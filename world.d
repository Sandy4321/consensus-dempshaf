module dempshaf.world;

import dempshaf.ai.agent;
import dempshaf.consensus.operators;
import dempshaf.consensus.ds;

import std.conv, std.file, std.getopt, std.math, std.random, std.stdio, std.string;

version (evidence_only)
{
    // VERSION: EVIDENCE_ONLY implies EVIDENCE is also TRUE.
    version = evidence;
}

void main(string[] args)
{
    /*
     * Set environment variables to use throughout tests;
     * Initialise consistent variables first, then sort through those passed
     * via command-line arguments.
     */
    immutable auto iterations = 50_000; //50_000
    immutable auto iterStep = iterations / 500; // iterations / 100
    immutable auto thresholdStep = 2;
    immutable auto testSet = 100; // 100
    immutable double evidenceNoise = 1.0;
    immutable bool setSeed = true;

    bool randomSelect = true, groupSizeSet;
    int l, n, p, thresholdStart, thresholdEnd, groupSize = 2, evidenceRate, noiseRate;
    double pRaw = 0.66;
    string boolThreeInit = "three_valued";

    writeln("Running program: ", args[0].split("/")[$-1]);

    const auto argProcessing = getopt(
        args,
        "dist",
        (string _, string s)
        {
            pRaw = to!double(s);
            p = to!int(pRaw * 100);
        },
        "thrStart",
        (string _, string s)
        {
            thresholdStart = to!int(to!double(s) * 100);
        },
        "thrEnd",
        (string _, string s)
        {
            thresholdEnd = to!int(to!double(s) * 100);
        },
        "random", &randomSelect,
        "rate", &evidenceRate,
        "group",
        (string _, string s)
        {
            groupSize = to!int(s);
            groupSizeSet = true;
        }
    );

    foreach (i, arg; args)
    {
        switch(i)
        {
            case 1:
                l = to!int(arg);
                writeln("Language size: ", l);
            break;
            case 2:
                n = to!int(arg);
                writeln("Population size: ", n);
            break;

            default:
            break;
        }
    }

    write("Logic: ");
    version (boolean)
        writeln("Boolean");
    else
        writeln("Three-valued");

    // Additional processing of arguments
    writeln("P value: ", pRaw, " :: ", p);
    if (p == 100)
    {
        writeln("==> ! Boolean initialisation !");
        boolThreeInit = "boolean";
    }
    writeln("Threshold start: ", thresholdStart);
    writeln("Threshold end: ", thresholdEnd);
    writeln("Random selection: ", randomSelect);

    if (groupSizeSet)
        writeln("Group size: ", groupSize);
    version (evidence)
        writeln("Random Evidence Allocation: " ~ to!string(evidenceRate) ~ "%");
    version (noisy)
        writeln("Evidence Noise Rate: " ~ to!string(noiseRate) ~ "%");

    auto seed = setSeed ? 128 : unpredictableSeed;
    auto rand = Random(seed);
    auto beliefDist = Random(seed);

    // Prepare arrays for storing all results collected during simulation
    immutable int arraySize = iterStep + 1;
    auto distanceResults    =   new string[][](arraySize, testSet);
    auto inconsistResults   =   new string[][](arraySize, testSet);
    auto entropyResults     =   new string[][](arraySize, testSet);
    auto uniqueResults      =   new string[][](arraySize, testSet);
    auto payoffResults      =   new string[][](arraySize, testSet);
    auto maxPayoffResults   =   new string[][](arraySize, testSet);

    // Initialize the population of agents according to population size l
    auto population = new Agent[n];
    foreach (ref agent; population) agent = new Agent();

    // Identify the choices that agents have and their respective,
    // normalised quality values.
    int[] choices;
    foreach (i; 0 .. l)
    {
        choices ~= i + 1;
    }
    writeln(choices);
    auto qualities = DempsterShafer.generatePayoff(choices,l);
    writeln(qualities);

    // Generate the frame of discernment (power set of the propositional variables)
    auto powerSet = DempsterShafer.generatePowerSet(l);
    writeln(powerSet);

    /*
     * Main test loop;
     * Total number of tests are run for each threshold in range thresholdStart
     * -> thresholdEnd.
     */
    for (int threshold = thresholdStart; threshold <= thresholdEnd; threshold += thresholdStep)
    {
        foreach (i; 0 .. 40) write("-"); writeln();
        writeln("threshold value: ", threshold / 100.0);

        rand = Random(seed);
        beliefDist = Random(seed);

        /*
         * Test loop;
         * The main experiment begins here.
         */
        foreach (test; 0 .. testSet)
        {
            write("\rtest #", test);
            stdout.flush();
            if (test == testSet - 1) writeln();

            auto payoffMap = new double[n];

            foreach (agentIndex, ref agent; population)
            {
                auto beliefs = new double[](l);
                double payoff;

                // assign uniform masses to the power set P^W.
                if (pRaw == 1)
                {
                    foreach (i; 0 .. l)
                    {
                        beliefs[] = 1.0 / l;
                    }
                }
                // assign full mass to the set W; complete ignorance.
                else if (pRaw == 0)
                {
                    beliefs[] = 0.0;
                    beliefs[$-1] = 1.0;
                }

                payoff = DempsterShafer.calculatePayoff(qualities, beliefs);
                agent.beliefs = beliefs;
                agent.payoff = payoff;
                payoffMap[agentIndex] = payoff;
                agent.resetInteractions;
            }

            /*
             * Iteration loop;
             * Agents interact according to broadcasting/listening rules,
             * but states are not discrete and separate. Possibility to limit
             * them based on some sort of inconsistency threshold exists.
             */

            int iterIndex;
            double[][] uniqueBeliefs;
            double distance, entropy, inconsist;
            bool append;
            foreach (iter; 0 .. iterations + 1)
            {
                if ((iter % (iterations / iterStep) == 0
                    && uniqueBeliefs.length > 1)
                    || iter == 0)
                {
                    uniqueBeliefs.length = 0;
                    distance = entropy = inconsist = 0.0;

                    foreach (i, ref agent; population)
                    {
                        double[] beliefs = agent.beliefs;

                        append = true;
                        foreach (unique; uniqueBeliefs)
                        {
                            if (unique == beliefs)
                            {
                                append = false;
                                break;
                            }
                        }
                        if (append)
                            uniqueBeliefs ~= beliefs;

                        // Calculate average entropy of agents' beliefs
                        entropy += DempsterShafer.entropy(beliefs, l);

                        // Calculate average distance of agents to identify
                        // possible consensus of the population
                        auto distanceHold = 0.0;
                        foreach (ref cmpAgent; population[i + 1 .. $])
                        {
                            if (agent == cmpAgent) continue;
                            distanceHold = DempsterShafer.distance(
                                agent.beliefs,
                                cmpAgent.beliefs,
                                l
                            );
                            distance += distanceHold;
                            inconsist += DempsterShafer.inconsistency(agent.beliefs, cmpAgent.beliefs, l);
                        }
                    }

                    distance = (2 * distance) / (n * (n - 1));
                    entropy /= n;
                    inconsist = (2 * inconsist) / (n * (n - 1));
                }

                // Fill out arrays for writing results later
                if ( (iter % (iterations / iterStep) == 0 ) || iter == iterations )
                {
                    distanceResults[iterIndex][test]    = format("%.4f", distance);
                    inconsistResults[iterIndex][test]   = format("%.4f", inconsist);
                    entropyResults[iterIndex][test]     = format("%.4f", entropy);
                    uniqueResults[iterIndex][test]      = format("%d", uniqueBeliefs.length);

                    payoffResults[iterIndex][test] = format(
                        "%.4f",
                        ((DempsterShafer.totalPayoff(payoffMap, 0.0) /
                            DempsterShafer.maximalPayoff) / n) * 100
                    );
                    maxPayoffResults[iterIndex][test] = format(
                        "%.4f",
                        (DempsterShafer.maxPayoff(payoffMap) /
                            DempsterShafer.maximalPayoff) * 100
                    );
                    iterIndex++;
                }

                // Only conduct interactions if agents have not yet reached
                // consensus. // uniqueBeliefs.length > 1
                if (uniqueBeliefs.length > 1)           // Check if consensus has been achieved
                {
                    int[] selection;
                    Agent[] selected;

                    // Select a pair of agents to interact:
                    // If randomSelect ? select at random : use roulette wheel
                    // selection method.
                    if (!randomSelect)
                    {
                        selection = DempsterShafer.rouletteSelection(rand, payoffMap, l, groupSize);
                    }
                    else
                    {
                        for (int i; i < groupSize; i++)
                        {
                            selection ~= uniform(0, n, rand);

                            if (i == 0) continue;
                            for (int j; j < i; j++)
                            {
                                if (selection[i] == selection[j])
                                {
                                    do selection[i] = uniform(0, n, rand);
                                    while (selection[i] == selection[j]);
                                    j = -1;
                                }
                            }
                        }
                    }

                    selected = new Agent[groupSize];
                    foreach (i, ref agent; selection)
                        selected[i] = population[agent];

                    auto combinedBeliefs = new double[][](groupSize, l);
                    foreach (ref belief; combinedBeliefs)
                    {
                        foreach (ref prop; belief)
                            prop = 0.0;
                    }

                    auto agentCounts = new int[groupSize];

                    bool consistent;
                    double inconsistency;
                    version (evidence_only)
                    {

                    }
                    else
                    {
                        foreach (int i, ref agent1; selected[0 .. $])
                        {
                            foreach (int j, ref agent2; selected[i + 1 .. $])
                            {
                                int k = i + 1 + j;
                                consistent = true;
                                if (threshold != 100)
                                {
                                    inconsistency = DempsterShafer.inconsistency(
                                        agent1.beliefs,
                                        agent2.beliefs,
                                        l
                                    );

                                    if ((inconsistency * 100) > threshold)
                                        consistent = false;
                                }

                                if (consistent)
                                {
                                    version (boolean)
                                    {
                                        // Code here if I make a Boolean variant,
                                        // if that's even possible.
                                    }
                                    else
                                    {
                                        // Need to form Dempster-Shafer combination here
                                        auto newBeliefs = [0.2,0.3,0.1,0.2,0.2];
                                        //auto newBeliefs = DempsterShafer.combination(
                                        //    agent1.beliefs,
                                        //    agent2.beliefs);
                                    }

                                    foreach (propIndex, ref prop; newBeliefs)
                                    {
                                        // Agent i
                                        combinedBeliefs[i][propIndex] += newBeliefs[propIndex];
                                        // Agent j
                                        combinedBeliefs[k][propIndex] += newBeliefs[propIndex];
                                    }
                                    // Increment the count to later normalise the beliefs for
                                    // each agent.
                                    agentCounts[i]++; agentCounts[k]++;
                                }
                            }

                            if (agentCounts[i] > 0)
                            {
                                auto newBeliefs = new double[](l);
                                foreach (propIndex, ref prop; newBeliefs)
                                {
                                    newBeliefs[propIndex] = combinedBeliefs[i][propIndex] /
                                        cast(double) agentCounts[i];
                                }

                                immutable auto newPayoff = DempsterShafer.calculatePayoff(
                                    qualities,
                                    newBeliefs
                                );

                                agent1.beliefs = newBeliefs;
                                agent1.payoff = newPayoff;
                                payoffMap[selection[i]] = newPayoff;
                                agent1.incrementInteractions;
                            }
                        }
                    }

                    version (evidence)
                    {
                        if (uniform(0, 100) <= evidenceRate)
                        {
                            auto randomIndex = uniform(0, n, rand);
                            auto randomAgent = population[randomIndex];

                            auto randomEvidence = new double[](l);
                            foreach (ref prop; randomEvidence)
                            {
                                prop = [0.0, 1.0];
                            }
                            auto randomProp = uniform(0, l, rand);
                            auto evidenceProp = (qualities[randomProp][0] == 1) ? [1.0, 1.0] : [0.0, 0.0];
                            if (uniform(0, 100) <= noiseRate)
                                evidenceProp[] += (evidenceProp[0] == 0.0) ? evidenceNoise : evidenceNoise * -1;

                            randomEvidence[randomProp] = evidenceProp;

                            auto newBeliefs = Operators.beliefConsensus(
                                randomAgent.beliefs,
                                randomEvidence
                            );

                            auto newPayoff = DempsterShafer.calculatePayoff(
                                qualities,
                                newBeliefs
                            );

                            randomAgent.beliefs = newBeliefs;
                            randomAgent.setPayoff(newPayoff);
                            payoffMap[randomIndex] = newPayoff;
                        }
                    }
                }
            }
        }

        writeln();

        // Write results to disk for current threshold
        string fileName;
        immutable string fileExt = ".csv";
        string booleanFN = "";
        string randomFN = "";
        version (boolean)
            booleanFN = "boolean_";
        if (randomSelect)
            randomFN = "random_";
        immutable auto fileThreshold = format("%.2f", threshold / 100.0);
        string groupSizeFN;
        if (groupSizeSet)
            groupSizeFN = "_" ~ to!string(groupSize);
        string evidenceRateFN;
        version (evidence_only)
        {
            evidenceRateFN ~= "_eo_" ~ to!string(evidenceRate);
        }
        else
        {
            version (evidence)
            {
                evidenceRateFN ~= "_ev_" ~ to!string(evidenceRate);
            }
        }
        string noisyEvidence;
        version (noisy)
        {
            noisyEvidence ~= "_noisy_" ~ to!string(noiseRate);
        }

        /*
         * Change the directory to store group results separately from the standard
         * results directory.
         */

        string directory;
        if (groupSize != 2)
        {
            directory = format(
                "../results/test_results/dempshaf/%s_initialisation/%s_agents/%s/%s_per_group/",
                boolThreeInit,
                n,
                l,
                groupSize
            );
        }
        else
        {
            directory = format(
                "../results/test_results/dempshaf/%s_initialisation/%s_agents/%s/",
                boolThreeInit,
                n,
                l
            );
        }

        auto append = "w";

        // Distance
        /*fileName = "distance" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
         ~ evidenceRateFN ~ noisyEvidence ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, distanceResults);*/

        // Inconsistency
        fileName = "inconsistency" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
         ~ evidenceRateFN ~ noisyEvidence ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, inconsistResults);

        // Entropy
        fileName = "entropy" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
         ~ evidenceRateFN ~ noisyEvidence ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, entropyResults);

        // Unique Beliefs
        fileName = "unique_beliefs" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
         ~ evidenceRateFN ~ noisyEvidence ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, uniqueResults);

        // Payoff
        fileName = "payoff" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
         ~ evidenceRateFN ~ noisyEvidence ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, payoffResults);

        // Maximum payoff
        fileName = "max_payoff" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
         ~ evidenceRateFN ~ noisyEvidence ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, maxPayoffResults);
    }
}

private void writeToFile(T)(string directory, string fileName, string append, T[][] results)
{
    auto file = File(directory ~ fileName, append);
    foreach (i, ref index; results)
    {
        foreach (j, ref test; index)
        {
            file.write(results[i][j]);
            file.write((j == results[i].length - 1) ? "\n" : ",");
        }
    }
    file.close();
}

// Below function is no longer required as belief results have been removed.

private void writeBeliefsToFile(T)(string directory, string fileName, string append, T[][] results)
{
    auto file = File(directory ~ fileName, append);
    foreach (i, ref index; results)
    {
        foreach (j, ref test; index)
        {
            foreach (k, ref belief; test)
            {
                file.write(results[i][j][k]);
                file.write((k == results[i][j].length - 1) ? "\n" : ",");
            }
        }
    }
    file.close();
}


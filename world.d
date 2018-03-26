module dempshaf.world;

import dempshaf.ai.agent;
import dempshaf.consensus.operators;
import dempshaf.consensus.ds;

import std.algorithm, std.conv, std.file, std.getopt, std.math, std.random, std.stdio, std.string;

void main(string[] args)
{
    /*
     * Set environment variables to use throughout tests;
     * Initialise consistent variables first, then sort through those passed
     * via command-line arguments.
     */
    immutable auto iterations = 100;            //50_000
    immutable auto iterStep = iterations / 1;   // iterations / 100
    immutable auto thresholdStep = 2;           // 2
    immutable auto testSet = 100;               // 100
    immutable bool setSeed = true;

    bool randomSelect = true, groupSizeSet;
    int l, n, thresholdStart, thresholdEnd, groupSize = 2;
    double pRaw = 0.66;
    int p = 66;
    string boolThreeInit = "three_valued";

    writeln("Running program: ", args[0].split("/")[$-1]);

    getopt(
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

    write("Evidence Mass: ");
    version (randomEvidence)
        writeln("random");
    else
        writeln("probabilistic");

    if (groupSizeSet)
        writeln("Group size: ", groupSize);

    auto seed = setSeed ? 128 : unpredictableSeed;
    auto rand = Random(seed);

    // Prepare arrays for storing all results collected during simulation
    immutable int arraySize = iterStep + 1;
    auto distanceResults    = new string[][](arraySize, testSet);
    auto inconsistResults   = new string[][](arraySize, testSet);
    auto entropyResults     = new string[][](arraySize, testSet);
    auto uniqueResults      = new string[][](arraySize, testSet);
    auto payoffResults      = new string[][](arraySize, testSet);
    auto maxPayoffResults   = new string[][](arraySize, testSet);
    auto bestChoiceResults  = new string[][](arraySize, testSet);
    auto cardMassResults    = new string[][](arraySize, testSet);

    // Initialize the population of agents according to population size l
    auto population = new Agent[n];
    foreach (ref agent; population) agent = new Agent();

    // Identify the choices that agents have and their respective,
    // normalised quality values.
    int[] choices;
    foreach (i; 0 .. l) choices ~= i + 1;
    writeln(choices);
    //auto qualities = DempsterShafer.generatePayoff(choices,l);
    auto qualities = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.2, 0.2, 1.0];
    writeln(qualities);
    // Ensure that the number of quality values matches the number of choices given.
    assert(qualities.length == l);

    // Generate the frame of discernment (power set of the propositional variables)
    auto powerSet = DempsterShafer.generatePowerSet(l);
    immutable auto belLength = to!int(powerSet.length);
    writeln(powerSet);

    // Find the choice with the highest payoff, and store its index in the power set.
    immutable int bestChoice = qualities.maxIndex.to!int;

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

        /*
         * Test loop;
         * The main experiment begins here.
         */
        foreach (test; 0 .. testSet)
        {
            write("\rtest #", test + 1);
            stdout.flush();
            if (test == testSet - 1) writeln();

            auto payoffMap = new double[n];

            foreach (agentIndex, ref agent; population)
            {
                double[int] beliefs;
                double payoff;

                // assign uniform masses to the power set P^W.
                if (pRaw == 1)
                {
                    foreach (int i; 0 .. belLength)
                    {
                        beliefs[i] = 1.0 / belLength;
                    }
                }
                // assign full mass to the set W; complete ignorance.
                else if (pRaw == 0)
                {
                    beliefs[belLength - 1] = 1.0;
                }

                payoff = DempsterShafer.calculatePayoff(
                    qualities,
                    powerSet,
                    beliefs
                );
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
            double[int][] uniqueBeliefs;
            double distance, entropy, inconsist, bestBelief, cardinality;
            bool append;
            foreach (iter; 0 .. iterations + 1)
            {
                /*
                 * Extract the data for each agent in the population, to be used
                 * throughout the simulation as well as for plotting results later.
                 */
                if (iter % (iterations / iterStep) == 0)
                {
                    uniqueBeliefs.length = 0;
                    distance = entropy = inconsist = bestBelief = cardinality = 0.0;

                    foreach (i, ref agent; population)
                    {
                        auto beliefs = agent.beliefs;

                        append = true;
                        foreach (unique; uniqueBeliefs)
                        {
                            // First compare whether the keys match. If they do, then
                            // the same subset has already been found. Then, check
                            // whether the masses for those subsets are the same.
                            if (
                                equal(unique.keys, beliefs.keys) &&
                                equal!approxEqual(unique.values, beliefs.values)
                            )
                            {
                                append = false;
                                break;
                            }
                        }
                        if (append) uniqueBeliefs ~= beliefs;

                        // Calculate average entropy of agents' beliefs
                        entropy += DempsterShafer.entropy(powerSet, l, beliefs);

                        // Calculate average distance of agents to identify
                        // possible consensus of the population
                        auto distanceHold = 0.0;
                        foreach (ref cmpAgent; population[i + 1 .. $])
                        {
                            if (agent == cmpAgent) continue;
                            distanceHold = DempsterShafer.distance(
                                powerSet,
                                l,
                                beliefs,
                                cmpAgent.beliefs
                            );
                            distance += distanceHold;
                            inconsist += DempsterShafer.inconsistency(
                                powerSet,
                                l,
                                beliefs,
                                cmpAgent.beliefs
                            );
                        }

                        if (bestChoice in beliefs)
                            bestBelief += beliefs[bestChoice];

                        foreach (j, ref bel; beliefs)
                        {
                            cardinality += bel * powerSet[j].length;
                        }
                    }

                    distance = (2 * distance) / (n * (n - 1));
                    entropy /= n;
                    inconsist = (2 * inconsist) / (n * (n - 1));
                    bestBelief /= n;
                    cardinality /= n;

                    // Format and tore the resulting simulation data into their
                    // respective arrays.

                    distanceResults[iterIndex][test]   = format("%.4f", distance);
                    inconsistResults[iterIndex][test]  = format("%.4f", inconsist);
                    entropyResults[iterIndex][test]    = format("%.4f", entropy);
                    uniqueResults[iterIndex][test]     = format("%d", uniqueBeliefs.length);
                    bestChoiceResults[iterIndex][test] = format("%.4f", bestBelief);
                    cardMassResults[iterIndex][test]   = format("%.4f", cardinality);

                    payoffResults[iterIndex][test] = format(
                        "%.4f",
                        (
                            (
                                DempsterShafer.totalPayoff(payoffMap, 0.0)
                            ) / n
                        ) * 100
                    );
                    maxPayoffResults[iterIndex][test] = format(
                        "%.4f",
                        (
                            DempsterShafer.maxPayoff(payoffMap)
                        ) * 100
                    );
                    iterIndex++;
                }
                /*
                    * Begin by combining each agent's mass function with the new
                    * evidence mass function, which serves as a form of 'payoff'
                    * assumed to be received when the agent assesses its choice
                    * e.g. when a honeybee visits a site.
                    */
                foreach(i, ref agent; population)
                {
                    // If evidence should be provided for a random choice.
                    version (randomEvidence)
                    {
                        agent.beliefs = Operators.consensus(
                            powerSet,
                            agent.beliefs,
                            DempsterShafer.randMassEvidence(
                                powerSet,
                                qualities,
                                rand
                            )
                        );
                    }
                    // Else, evidence should favour the most prominent choice.
                    else
                    {
                        agent.beliefs = Operators.consensus(
                            powerSet,
                            agent.beliefs,
                            DempsterShafer.massEvidence(
                                powerSet,
                                l,
                                qualities,
                                agent.beliefs,
                                rand
                            )
                        );
                    }
                }

                bool consistent;
                double inconsistency;
                Agent selected;
                int selection;

                auto snapshotPopulation = population.dup;

                foreach (i, ref agent; population)
                {
                    consistent = true;

                    do selection = uniform(0, n, rand);
                    while (i == selection);
                    selected = snapshotPopulation[selection];

                    /*if (threshold != 100)
                    {
                        inconsistency = DempsterShafer.inconsistency(
                            agent.beliefs,
                            selected.beliefs,
                            l
                        );

                        if ((inconsistency * 100) > threshold)
                            consistent = false;
                    }*/

                    auto newBeliefs = agent.beliefs;

                    if (consistent)
                    {
                        // Form a new belief via the consensus operator.
                        newBeliefs = Operators.consensus(
                            powerSet,
                            agent.beliefs,
                            selected.beliefs
                        );
                    }

                    immutable auto newPayoff = DempsterShafer.calculatePayoff(
                        qualities,
                        powerSet,
                        newBeliefs
                    );

                    agent.beliefs = newBeliefs;
                    agent.payoff  = newPayoff;
                    payoffMap[i]  = newPayoff;
                    agent.incrementInteractions;
                }
            }
        }

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
        fileName = "distance" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
        ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, distanceResults);

        // Inconsistency
        fileName = "inconsistency" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
        ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, inconsistResults);

        // Entropy
        fileName = "entropy" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
        ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, entropyResults);

        // Unique Beliefs
        fileName = "unique_beliefs" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
        ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, uniqueResults);

        // Payoff
        fileName = "payoff" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
        ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, payoffResults);

        // Maximum payoff
        fileName = "max_payoff" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
        ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, maxPayoffResults);

        // Best-choice belief
        fileName = "average_belief" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
        ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, bestChoiceResults);

        // Cardinality
        fileName = "cardinality" ~ "_" ~ booleanFN ~ randomFN ~ to!string(pRaw)
        ~ "_" ~ fileThreshold ~ fileExt;
        writeToFile(directory, fileName, append, cardMassResults);
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
            file.write((j == cast(ulong) results[i].length - 1) ? "\n" : ",");
        }
    }
    file.close();
}

// The following function is no longer required as belief results have been removed.
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
                file.write((k == cast(ulong) results[i][j].length - 1) ? "\n" : ",");
            }
        }
    }
    file.close();
}


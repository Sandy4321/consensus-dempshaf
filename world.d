module dempshaf.world;

import dempshaf.ai.agent;
import dempshaf.consensus.operators;
import dempshaf.consensus.ds;

import std.algorithm, std.array, std.conv, std.file, std.getopt, std.math;
import std.random, std.stdio, std.string, std.traits;

void main(string[] args)
{
    /*
     * Set environment variables to use throughout tests;
     * Initialise consistent variables first, then sort through those passed
     * via command-line arguments.
     */
    immutable auto iterations = 100;            //50_000
    immutable auto iterStep = iterations / 1;   // iterations / 100
    immutable auto testSet = 100;               // 100
    immutable auto alpha = 0.0;                 // 0.0
    immutable auto gamma = false;               // Enable(true)/disable(false) thresholds
    immutable auto lambda = 0.0;                // 0 would be regular combination
    immutable auto alterIter = 10;
    immutable bool setSeed = true;

    // An alias for one of two combination functions:
    // Consensus operator, and Dempster's rule of combination
    alias combination = Operators.consensus;
    // alias combination = Operators.dempsterRoC;
    immutable auto evidenceOnly = false;         // true for benchmarking

    bool randomSelect = true;
    int l, n;
    double pRaw = 0.66;
    int p = 66;
    string distribution = "";

    writeln("Running program: ", args[0].split("/")[$-1]);

    getopt(
        args,
        "dist",
        (string _, string s)
        {
            pRaw = to!double(s);
            p = to!int(pRaw * 100);
        },
        "random", &randomSelect
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
    writeln("P value: ", pRaw, " :: ", p);
    if (approxEqual(pRaw, 0.0))
        distribution = "ignorant";
    if (p == 100)
    {
        writeln("==> ! Uniform distribution !");
        distribution = "uniform";
    }
    writeln("Combination function: ", fullyQualifiedName!combination.split(".")[$-1]);
    writeln("Lambda value: ", lambda);
    version (alterQ)
    {
        writeln("Altering value(s) after ", alterIter, " iterations.");
    }
    writeln("Random selection: ", randomSelect);
    write("Evidence mass: ");
    version (negativeEvidence)
        writeln("negative");
    else version (randomEvidence)
        writeln("random");
    else
        writeln("probabilistic");
    if (evidenceOnly)
        writeln("!!! EVIDENCE-ONLY VERSION: FOR BENCHMARKING ONLY !!!");

    auto seed = setSeed ? 128 : unpredictableSeed;
    auto rand = Random(seed);

    // Prepare arrays for storing all results collected during simulation
    immutable int arraySize = iterStep + 1;
    // auto distanceResults    = new string[][](arraySize, testSet);
    // auto inconsistResults   = new string[][](arraySize, testSet);
    auto entropyResults     = new string[][](arraySize, testSet);
    auto uniqueResults      = new string[][](arraySize, testSet);
    auto payoffResults      = new string[][](arraySize, testSet);
    auto maxPayoffResults   = new string[][](arraySize, testSet);
    auto choiceResults      = new string[][](arraySize, testSet);
    auto powerSetResults    = new string[][](arraySize, testSet);
    auto cardMassResults    = new string[][](arraySize, testSet);

    // Initialize the population of agents according to population size l
    auto population = new Agent[n];
    foreach (ref agent; population) agent = new Agent();

    // Identify the choices that agents have and their respective,
    // normalised quality values.
    int[] choices;
    foreach (i; 0 .. l) choices ~= i + 1;
    writeln(choices);

    //*************************************
    immutable auto qualityIndex = args[$-1].to!int;
    //*************************************
    immutable auto masterQStrings = [
        "[0.2, 0.4, 1.0]",
        "[0.3, 0.6, 1.0]",
        "[0.8, 0.9, 1.0]",

        "[0.025, 0.025, 0.05, 0.1, 0.8]",
        "[0.96, 0.97, 0.98, 0.99, 1.0]",
        "[0.825, 0.85, 0.85, 0.88, 0.95]",

        "[0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.2, 0.2, 1.0]",
        "[0.1, 0.1, 0.3, 0.3, 0.5, 0.5, 0.6, 0.6, 0.8, 1.0]",
        "[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]"
    ];
    double[][] masterQualities;
    static foreach (qstring; masterQStrings)
        masterQualities ~= mixin(qstring);
    auto qualities = masterQualities
                     .filter!(a => a.length == l)
                     .array[qualityIndex];
    auto qualitiesString =  masterQStrings
                            .filter!(
                                a => a.split(",")
                                .length == l
                            ).array[qualityIndex];
    writeln(qualities, " == ", qualitiesString);
    // Ensure that the number of quality values matches the number of choices given.
    assert(qualities.length == l);

    static if (gamma)
    {
        // Generate the set of threshold values relevant to the language size.
        double[] thresholdSet;
        thresholdSet ~= 0.0;
        foreach (double i; 1 .. l + 1)
        {
            foreach (double j; 1 .. i)
            {
                thresholdSet ~= j/i;
            }
        }
        thresholdSet ~= 1.0;
        thresholdSet = thresholdSet.sort.uniq.array;
        writeln(thresholdSet);
    }
    else
    {
        immutable double[] thresholdSet = [0.0];
    }

    // Generate the frame of discernment (power set of the propositional variables)
    auto powerSet = DempsterShafer.generatePowerSet(l);
    immutable auto belLength = to!int(powerSet.length);
    // writeln(powerSet);

    // Find the choice with the highest payoff, and store its index in the power set.
    int bestChoice = qualities.maxIndex.to!int;

    /*
     * For each threshold in thresholdSet, run the experiment using that value of gamma.
     */
    foreach (threshold; thresholdSet)
    {
        static if (gamma)
        {
            writeln("threshold: %.4f".format(threshold));
        }
        /*
        * Main test loop;
        * The main experiment begins here.
        */
        foreach (test; 0 .. testSet)
        {
            write("\rtest #", test + 1);
            stdout.flush();
            if (test == testSet - 1) writeln();

            qualities = masterQualities
                        .filter!(a => a.length == l)
                        .array[qualityIndex];
            bestChoice = qualities.maxIndex.to!int;

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
            * but states are not discrete and separate.
            */

            int iterIndex;
            double[int] choiceBeliefs;
            double[int] powerSetBeliefs;
            double[int][] uniqueBeliefs;
            // double distance, inconsist,
            double entropy, cardinality;
            bool append;
            foreach (iter; 0 .. iterations + 1)
            {
                /*
                * If VERSION == alterQ then we alter the quality value of the
                * best choice to see how the population can react.
                */
                version (alterQ)
                {
                    if (iter == alterIter)
                    {
                        qualities[bestChoice] = qualities[bestChoice - 1] / 2.0;
                        bestChoice = qualities.maxIndex.to!int;
                    }
                }

                /*
                * Extract the data for each agent in the population, to be used
                * throughout the simulation as well as for plotting results later.
                */
                if (iter % (iterations / iterStep) == 0)
                {
                    foreach (index; 0 .. l)
                        choiceBeliefs[index] = 0.0;
                    foreach (index; 0 .. pow(2, l) - 1)
                        powerSetBeliefs[index] = 0.0;
                    uniqueBeliefs.length = 0;
                    // distance = inconsist =
                    entropy = cardinality = 0.0;

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
                        // auto distanceHold = 0.0;
                        /* foreach (ref cmpAgent; population[i + 1 .. $])
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
                        } */

                        foreach (index; 0 .. l)
                            if (index in beliefs)
                                choiceBeliefs[index] += beliefs[index];

                        foreach (index; 0 .. pow(2, l) - 1)
                            if (index in beliefs)
                                powerSetBeliefs[index] += beliefs[index];

                        foreach (j, ref bel; beliefs)
                        {
                            cardinality += bel * powerSet[j].length;
                        }
                    }

                    // distance = (2 * distance) / (n * (n - 1));
                    entropy /= n;
                    // inconsist = (2 * inconsist) / (n * (n - 1));
                    foreach (index; 0 .. l)
                        choiceBeliefs[index] /= n;
                    foreach (index; 0 .. pow(2, l) - 1)
                        powerSetBeliefs[index] /= n;
                    cardinality /= n;

                    // Format and tore the resulting simulation data into their
                    // respective arrays.

                    // distanceResults[iterIndex][test]   = format("%.4f", distance);
                    // inconsistResults[iterIndex][test]  = format("%.4f", inconsist);
                    entropyResults[iterIndex][test] = format("%.4f", entropy);
                    uniqueResults[iterIndex][test] = format("%d", uniqueBeliefs.length);
                    choiceResults[iterIndex][test] = "[";
                    foreach (key; choiceBeliefs.keys.sort)
                        choiceResults[iterIndex][test] ~= format(
                            "%.4f", choiceBeliefs[key]
                        ) ~ ",";
                    choiceResults[iterIndex][test] = choiceResults[iterIndex][test][0 .. $-1] ~ "]";
                    powerSetResults[iterIndex][test] = "[";
                    foreach (key; powerSetBeliefs.keys.sort)
                        powerSetResults[iterIndex][test] ~= format(
                            "%.4f", powerSetBeliefs[key]
                        ) ~ ",";
                    powerSetResults[iterIndex][test] = powerSetResults[iterIndex][test][0 .. $-1] ~ "]";
                    cardMassResults[iterIndex][test] = format("%.4f", cardinality);

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
                    version (negativeEvidence)
                    {
                        agent.beliefs = combination(
                            powerSet,
                            agent.beliefs,
                            DempsterShafer.negMassEvidence(
                                powerSet,
                                qualities,
                                alpha,
                                rand
                            ),
                            0.0,
                            lambda
                        );
                    }
                    else
                    {
                        // If evidence should be provided for a random choice.
                        version (randomEvidence)
                        {
                            agent.beliefs = combination(
                                powerSet,
                                agent.beliefs,
                                DempsterShafer.randMassEvidence(
                                    qualities,
                                    rand,
                                ),
                                0.0,
                                lambda
                            );
                        }
                        // Else, evidence should favour the most prominent choice.
                        else
                        {
                            agent.beliefs = combination(
                                powerSet,
                                agent.beliefs,
                                DempsterShafer.probMassEvidence(
                                    powerSet,
                                    l,
                                    qualities,
                                    agent.beliefs,
                                    rand
                                ),
                                0.0,
                                lambda
                            );
                        }
                    }
                }
                /*
                * Agents conduct some form of belief-merging/"consensus".
                */
                static if (!evidenceOnly)
                {
                    Agent selected;
                    int selection;
                    auto snapshotPopulation = population.dup;

                    foreach (i, ref agent; population)
                    {
                        do selection = uniform(0, n, rand);
                        while (i == selection);
                        selected = snapshotPopulation[selection];

                        auto newBeliefs = combination(
                            powerSet,
                            agent.beliefs,
                            selected.beliefs,
                            threshold,
                            lambda
                        );

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
        }

        // Write results to disk for current test.
        string fileName;
        string fileExt = ".csv";
        static if (gamma)
        {
            fileExt = "_%.4f".format(threshold) ~ fileExt;
        }
        string randomFN = "";
        if (randomSelect)
            randomFN = "random";

        /*
        * Change the directory to store results in the appropriate directory structure.
        */
        string directory = format(
            "../results/test_results/dempshaf/%s_distribution/%s_agents/",
            distribution,
            n
        );
        static if (lambda > 0.0)
        {
            directory ~= format("lambda_operator_%.1f/", lambda);
        }
        static if (fullyQualifiedName!combination.canFind("dempster"))
        {
            directory ~= "dempsters_operator/";
        }
        else
        {
            directory ~= "consensus_operator/";
        }
        version(negativeEvidence)
        {
            directory ~= "negative_evidence/";
        }
        static if (evidenceOnly)
        {
            directory ~= "evidence_only/";
        }
        static if (lambda > 0.0)
        {
            version(alterQ)
            {
                directory ~= format("change_at_%s/", alterIter);
            }
            else
            {
                directory ~= "no_change/";
            }
        }
        directory ~= format("%s/%s/", l, qualitiesString);

        auto append = "w";

        // Distance
        /* fileName = "distance" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, distanceResults); */

        // Inconsistency
        /* fileName = "inconsistency" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, inconsistResults); */

        // Entropy
        fileName = "entropy" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, entropyResults);

        // Unique Beliefs
        fileName = "unique_beliefs" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, uniqueResults);

        // Payoff
        fileName = "payoff" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, payoffResults);

        // Maximum payoff
        fileName = "max_payoff" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, maxPayoffResults);

        // Best-choice belief
        fileName = "average_beliefs" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, choiceResults);

        // Powerset belief
        fileName = "average_masses" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, powerSetResults);

        // Cardinality
        fileName = "cardinality" ~ "_" ~ randomFN ~ fileExt;
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


module dempshaf.world;

import dempshaf.ai.agent;
import dempshaf.consensus.operators;
import dempshaf.consensus.ds;

import core.stdc.stdlib;
import std.algorithm, std.array, std.conv, std.file, std.getopt, std.math;
import std.random, std.stdio, std.string, std.traits;

import std.parallelism;

// Set the version to symmetric or asymmetric
version = symmetric;

void main(string[] args)
{
    /*
     * Set environment variables to use throughout tests;
     * Initialise consistent variables first, then sort through those passed
     * via command-line arguments.
     */
    immutable auto iterations = 10_000;
    immutable auto changeThreshold = 50;
    auto maxIterations = 0;
    immutable auto iterStep = iterations / 1;
    immutable auto testSet = 100;
    immutable auto alpha = 0.0;
    immutable auto gamma = false;
    immutable auto lambda = 0.0;
    immutable auto iota = false;
    immutable auto alterIter = 10;
    immutable bool setSeed = true;

    // Default precision for approxEqual is 1e-2.
    immutable auto precision = 1e-4;

    // An alias for one of two combination functions:
    // Consensus operator, and Dempster's rule of combination

    alias combination = Operators.consensus;
    // alias combination = Operators.dempsterRoC;

    immutable auto evidenceOnly = false;
    // Evidence is random, not probabilistic:
    immutable auto randomEvidence = false;
    // Agents receive negative information.
    immutable auto negativeEvidence = false;

    if (gamma && fullyQualifiedName!combination.canFind("dempster"))
    {
        writeln("Cannot run gamma-thresholding for Dempster's rule.");
        exit(1);
    }

    bool randomSelect = true;
    int langSize, numOfAgents, initDist;
    double initDistRaw = 0.0;
    // string distribution = "";

    writeln("Running program: ", args[0].split("/")[$ - 1]);

    writeln("Simulation length: ", iterations, " iterations");

    getopt(args,/* "dist",
        (string _, string s)
        {
            initDistRaw = to!double(s);
            initDist = to!int(initDistRaw * 100);
        }, */
            "random", &randomSelect);
    foreach (i, arg; args)
    {
        switch (i)
        {
        case 1:
            numOfAgents = to!int(arg);
            writeln("Population size: ", numOfAgents);
            break;
        case 2:
            langSize = to!int(arg);
            writeln("Language size: ", langSize);
            break;

        default:
            break;
        }
    }

    if (gamma && langSize > 3)
    {
        writeln("Cannot run gamma-thresholding for a language size > 3.");
        exit(1);
    }
    else if (iota && langSize < 5)
    {
        writeln("Cannot run iota-thresholding for a language size < 5");
        exit(1);
    }

    write("Logic: ");
    version (boolean)
        writeln("Boolean");
    else
        writeln("Three-valued");

    write("Updating method: ");
    version (symmetric)
        writeln("! SYMMETRIC !");
    else
        writeln("! ASYMMETRIC !");
    /* writeln("P value: ", initDistRaw, " :: ", initDist);
    if (approxEqual(initDistRaw, 0.0))
        distribution = "ignorant";
    if (p == 100)
    {
        writeln("==> ! Uniform distribution !");
        distribution = "uniform";
    } */
    writeln("Combination function: ", fullyQualifiedName!combination.split(".")[$ - 1]);
    writeln("Lambda value: ", lambda);
    version (alterQ)
    {
        writeln("Altering value(s) after ", alterIter, " iterations.");
    }
    writeln("Random selection: ", randomSelect);
    write("Evidence mass: ");
    static if (negativeEvidence)
        writeln("negative");
    else static if (randomEvidence)
        writeln("random");
    else
        writeln("probabilistic");
    if (evidenceOnly)
        writeln("!!! EVIDENCE-ONLY VERSION: FOR BENCHMARKING ONLY !!!");
    version (sanityCheck)
        writeln("!!! SANITY CHECK MODE !!!");

    // Prepare arrays for storing all results collected during simulation
    immutable int arraySize = iterStep + 1;
    // auto inconsistResults   = new string[][](arraySize, testSet);
    auto entropyResults = new string[][](arraySize, testSet);
    auto uniqueResults = new string[][](arraySize, testSet);
    auto choiceResults = new string[][](arraySize, testSet);
    auto powersetResults = new string[][](arraySize, testSet);
    auto cardMassResults = new string[][](arraySize, testSet);

    auto steadyStateBeliefs = new string[][](numOfAgents, testSet);

    // Initialize the population of agents according to population size l
    auto population = new Agent[numOfAgents];
    foreach (ref agent; population)
        agent = new Agent();

    // Identify the choices that agents have and their respective,
    // normalised quality values.
    int[] choices;
    foreach (i; 0 .. langSize)
        choices ~= i + 1;
    writeln(choices);

    //*************************************
    immutable auto qualityIndex = args[$ - 1].to!int;
    //*************************************
    immutable auto masterQStrings = [
        "[0.3, 0.9]", "[0.5, 1.0]", "[0.9, 1.0]", "[0.2, 0.4, 1.0]", "[0.8, 0.9, 1.0]",
        "[1.0, 1.0, 1.0]", "[0.6, 0.7, 0.8, 0.9, 1.0]",
        "[0.025, 0.025, 0.05, 0.1, 0.8]", "[0.96, 0.97, 0.98, 0.99, 1.0]",

        "[0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.2, 0.2, 1.0]",
        "[0.1, 0.1, 0.3, 0.3, 0.5, 0.5, 0.6, 0.6, 0.8, 1.0]",
        "[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]",

        "[0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 1.0]"
    ];
    double[][] masterQualities;
    static foreach (qstring; masterQStrings)
        masterQualities ~= mixin(qstring);
    auto qualities = masterQualities.filter!(a => a.length == langSize).array[qualityIndex].dup;
    auto qualitiesString = masterQStrings.filter!(a => a.split(",")
            .length == langSize).array[qualityIndex];
    writeln(qualities);
    // Ensure that the number of quality values matches the number of choices given.
    assert(qualities.length == langSize);

    /*
     * If using the threshold-based operators, then generate the threshold ranges
     * and select the midpoint of each range to run as the gamma value.
     */
    // If gamma is not set, then threshold the agents based on
    // inconsistency, rather than thresholding the operator.
    auto affectOperator = false;
    static if (gamma)
    {
        // If gamma is set, then threshold the operator.
        affectOperator = true;
        // Generate the set of threshold values relevant to the language size.
        double[] thresholdSet, thresholdTempSet;
        thresholdTempSet ~= 0.0;
        foreach (double i; 1 .. langSize + 1)
        {
            foreach (double j; 1 .. i)
            {
                thresholdTempSet ~= j / i;
            }
        }
        thresholdTempSet ~= 1.0;
        thresholdTempSet = thresholdTempSet.sort.uniq.array;
        write(thresholdTempSet, " --> ");
        foreach (index; 0 .. thresholdTempSet.length.to!long - 1)
            thresholdSet ~= (thresholdTempSet[index] + thresholdTempSet[index + 1]) / 2.0;
        writeln(thresholdSet);
    }
    else static if (iota)
    {
        double[] thresholdSet;
        foreach (threshold; 0 .. 11)
            thresholdSet ~= (threshold / 10.0).to!double;
        foreach (threshold; 91 .. 100)
            thresholdSet ~= (threshold / 100.0).to!double;
        thresholdSet.sort;
        writeln(thresholdSet);

    }
    else
    {
        immutable double[] thresholdSet = [0.0];
    }

    // Generate the frame of discernment (power set of the propositional variables)
    immutable auto belLength = ((2 ^^ langSize) - 1).to!int;
    immutable auto powersetLimit = 5;
    if (langSize <= powersetLimit)
    {
        auto powerset = DempsterShafer.generatePowerset(langSize);
        writeln(powerset);
    }
    // Generate the indices of the hypotheses' singletons
    auto belIndices = new int[langSize];
    foreach (i; 0 .. langSize)
    {
        auto vector = new int[langSize];
        vector[i] = 1;
        belIndices[i] = DempsterShafer.vecToIndex(vector);
    }
    writeln(belIndices);

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
        else static if (iota)
        {
            writeln("threshold: %.2f".format(threshold));
        }

        auto seed = setSeed ? 128 : unpredictableSeed;
        auto rand = Random(seed);

        /*
        * Main test loop;
        * The main experiment begins here.
        */
        foreach (test; 0 .. testSet)
        {
            write("\rtest #", test + 1);
            stdout.flush();
            if (test == testSet - 1)
                writeln();

            qualities = masterQualities.filter!(a => a.length == langSize).array[qualityIndex].dup;
            bestChoice = qualities.maxIndex.to!int;

            foreach (agentIndex, ref agent; population)
            {
                double[int] beliefs;

                // assign uniform masses to the power set P^W.
                if (initDistRaw == 1)
                {
                    foreach (int i; 0 .. belLength)
                    {
                        beliefs[i] = 1.0 / belLength;
                    }
                }
                // assign full mass to the set W; complete ignorance.
                else if (initDistRaw == 0)
                {
                    beliefs[belLength - 1] = 1.0;
                }

                agent.beliefs = beliefs;
                agent.resetInteractions;
            }

            /*
            * Iteration loop;
            * Agents interact according to broadcasting/listening rules,
            * but states are not discrete and separate.
            */

            int iterIndex;
            double[int] choiceBeliefs;
            double[int] powersetBeliefs;
            double[int][] uniqueBeliefs;
            // double inconsist,
            double entropy, cardinality;
            bool append, reachedSteadyState;
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
                    foreach (index; belIndices)
                        choiceBeliefs[index] = 0.0;
                    if (langSize < powersetLimit)
                        foreach (index; 0 .. belLength)
                            powersetBeliefs[index] = 0.0;
                    uniqueBeliefs.length = 0;
                    // inconsist =
                    entropy = cardinality = 0.0;
                    reachedSteadyState = true;

                    foreach (i, ref agent; population)
                    {
                        auto beliefs = agent.beliefs;

                        append = true;
                        foreach (unique; uniqueBeliefs)
                        {
                            // First compare whether the keys match. If they do, then
                            // the same subset has already been found. Then, check
                            // whether the masses for those subsets are the same.
                            if (unique.keys.sort.equal(beliefs.keys.sort) && unique.keys
                                    .sort
                                    .map!(x => unique[x])
                                    .equal!approxEqual(beliefs.keys.sort.map!(x => beliefs[x])))
                            {
                                append = false;
                                break;
                            }
                        }
                        if (append)
                            uniqueBeliefs ~= beliefs;

                        // Calculate average entropy of agents' beliefs
                        entropy += DempsterShafer.entropy(belLength, beliefs);

                        foreach (index; belIndices)
                            if (index in beliefs)
                                choiceBeliefs[index] += beliefs[index];

                        if (langSize < powersetLimit)
                            foreach (index; 0 .. belLength)
                                if (index in beliefs)
                                    powersetBeliefs[index] += beliefs[index];

                        foreach (j, ref bel; beliefs)
                        {
                            cardinality += bel * DempsterShafer.createSet(langSize, j).length;
                        }

                        // Check if agent has reached a steady state
                        if (agent.timeSinceChange < changeThreshold)
                            reachedSteadyState = false;
                    }
                    entropy /= numOfAgents;
                    // inconsist = (2 * inconsist) / (n * (n - 1));
                    foreach (index; belIndices)
                        choiceBeliefs[index] /= numOfAgents;
                    if (langSize < powersetLimit)
                        foreach (index; 0 .. belLength)
                            powersetBeliefs[index] /= numOfAgents;
                    cardinality /= numOfAgents;

                    // Format and tore the resulting simulation data into their
                    // respective arrays.

                    // inconsistResults[iterIndex][test]  = format("%.4f", inconsist);
                    entropyResults[iterIndex][test] = format("%.4f", entropy);
                    uniqueResults[iterIndex][test] = format("%d", uniqueBeliefs.length);
                    choiceResults[iterIndex][test] = "[";
                    foreach (key; choiceBeliefs.keys.sort)
                        choiceResults[iterIndex][test] ~= format("%.4f", choiceBeliefs[key]) ~ ",";
                    choiceResults[iterIndex][test] = choiceResults[iterIndex][test][0 .. $ - 1]
                        ~ "]";
                    powersetResults[iterIndex][test] = "[";
                    if (langSize < powersetLimit)
                    {
                        foreach (key; powersetBeliefs.keys.sort)
                            powersetResults[iterIndex][test] ~= format("%.4f", powersetBeliefs[key])
                                ~ ",";
                        powersetResults[iterIndex][test] = powersetResults[iterIndex][test][0
                            .. $ - 1] ~ "]";
                    }
                    cardMassResults[iterIndex][test] = format("%.4f", cardinality);

                    iterIndex++;
                }

                /*
                 * If simulation has reached steady state and is at convenient
                 * cut-off point, then end this test.
                 */
                if (reachedSteadyState && iter % 100 == 0)
                {
                    maxIterations = (iter > maxIterations) ? iter : maxIterations;
                    continue;
                }

                /*
                * Begin by combining each agent's mass function with the new
                * evidence mass function, which serves as a form of 'payoff'
                * assumed to be received when the agent assesses its choice
                * e.g. when a honeybee visits a site.
                */
                ulong[] restrictedPopulation;
                version (sanityCheck)
                {
                    foreach (i, ref agent; population)
                    {
                        auto beliefs = agent.beliefs;
                        auto skip = false;
                        foreach (j; 0 .. l)
                        {
                            if (j in beliefs && approxEqual(beliefs[j], 1.0, precision))
                            {
                                skip = true;
                                break;
                            }
                        }
                        if (!skip)
                            restrictedPopulation ~= i;
                    }
                }
                else
                {
                    restrictedPopulation = new ulong[numOfAgents];
                    foreach (index; 0 .. numOfAgents)
                        restrictedPopulation[index] = index;
                }

                foreach (i; restrictedPopulation)
                {
                    Agent agent = population[i];

                    static if (negativeEvidence)
                    {
                        agent.beliefs = combination(langSize, agent.beliefs,
                                DempsterShafer.negMassEvidence(qualities,
                                    alpha, rand), 0.0, false, lambda);
                    }
                    else
                    {
                        // If evidence should be provided for a random choice.
                        static if (randomEvidence)
                        {
                            agent.beliefs = combination(langSize, agent.beliefs,
                                    DempsterShafer.randMassEvidence(qualities,
                                        rand,), 0.0, false, lambda);
                        }
                        // Else, evidence should favour the most prominent choice.
                    else
                        {
                            agent.beliefs = combination(langSize, agent.beliefs,
                                    DempsterShafer.probMassEvidence(qualities,
                                        agent.beliefs, rand), 0.0, false, lambda);

                            /* auto evidence = DempsterShafer.probMassEvidence(
                                qualities,
                                agent.beliefs,
                                rand
                            );

                            writeln("Evidential updating...");
                            writeln(
                                agent.beliefs.keys.map!(
                                    x => DempsterShafer.createSet(langSize, x)
                                ),
                                " (+) ",
                                evidence.keys.map!(
                                    x => DempsterShafer.createSet(langSize, x)
                                )
                            );
                            writeln("Old: ", agent.beliefs);
                            writeln("Evidence: ", evidence);

                            agent.beliefs = combination(
                                langSize,
                                agent.beliefs,
                                evidence,
                                0.0,
                                false,
                                lambda
                            );

                            writeln("New: ", agent.beliefs); */
                        }
                    }
                }
                /*
                * Agents conduct some form of belief-merging/"consensus".
                */
                Agent[] snapshotPopulation;
                foreach (index; 0 .. population.length)
                    snapshotPopulation ~= population[index].dup;

                static if (!evidenceOnly)
                {
                    if (restrictedPopulation.length > 2)
                    {
                        Agent selected;
                        int selection;

                        version (symmetric)
                        {
                            int i = restrictedPopulation.choice(rand).to!int;
                            do
                                selection = restrictedPopulation.choice(rand).to!int;
                            while (i == selection);
                            Agent agent = population[i];
                            selected = population[selection];

                            static if (iota)
                            {
                                immutable double inconsistency = DempsterShafer.inconsistency(langSize,
                                        agent.beliefs, selected.beliefs);
                                // If the pairwise inconsistency is greater than the
                                // threshold, and not within some margin of floating-point
                                // error, then do not combine beliefs.
                                if (inconsistency > threshold
                                        && !inconsistency.approxEqual(threshold, precision))
                                {
                                    continue;
                                }
                            }

                            auto newBeliefs = combination(langSize, agent.beliefs,
                                    selected.beliefs, threshold, affectOperator, lambda);

                            agent.beliefs = newBeliefs;
                        }
                        else
                        {
                            foreach (i; restrictedPopulation)
                            {
                                do
                                    selection = restrictedPopulation.choice(rand).to!int;
                                while (i == selection);
                                Agent agent = population[i];
                                selected = snapshotPopulation[selection];

                                static if (iota)
                                {
                                    immutable double inconsistency = DempsterShafer.inconsistency(langSize,
                                            agent.beliefs, selected.beliefs);
                                    /*
                                     * If the pairwise inconsistency is greater than the
                                     * threshold, and not within some margin of
                                     * floating-point error, then do not combine beliefs.
                                     */
                                    if (inconsistency > threshold
                                            && !inconsistency.approxEqual(threshold, precision))
                                    {
                                        continue;
                                    }
                                }

                                auto newBeliefs = combination(langSize, agent.beliefs,
                                        selected.beliefs, threshold, affectOperator, lambda);

                                agent.beliefs = newBeliefs;
                                selected.beliefs = newBeliefs;
                            }
                        }
                    }
                }
                static if (!gamma && !iota)
                {
                    /*
                    * Grab the steady state results.
                    */
                    if (iterIndex == iterations)
                    {
                        // auto interactions = 0.0;
                        foreach (i, ref agent; population)
                        {
                            auto beliefs = agent.beliefs;

                            steadyStateBeliefs[i][test] = "[";
                            foreach (index; belIndices)
                            {
                                if (index in beliefs)
                                {
                                    steadyStateBeliefs[i][test] ~= format("%.4f", beliefs[index])
                                        ~ ",";
                                }
                                else
                                {
                                    steadyStateBeliefs[i][test] ~= format("%.4f", 0.0) ~ ",";
                                }
                            }
                            steadyStateBeliefs[i][test] = steadyStateBeliefs[i][test][0 .. $ - 1]
                                ~ "]";
                            // interactions += agent.interactions;
                        }
                        // writeln(interactions /= numOfAgents);
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
        else static if (iota)
        {
            fileExt = "_%.2f".format(threshold) ~ fileExt;
        }
        string randomFN = "";
        if (randomSelect)
        {
            randomFN = "random";
        }
        /*
        * Change the directory to store results in the appropriate directory structure.
        */
        string directory = format("../results/test_results/dempshaf/%s_agents/", numOfAgents);
        version (symmetric)
        {
            directory ~= "symmetric/";
        }
        version (sanityCheck)
        {
            directory ~= "sanity_checks/";
        }
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
        static if (negativeEvidence)
        {
            directory ~= "negative_evidence/";
        }
        else static if (evidenceOnly)
        {
            directory ~= "evidence_only/";
        }
        static if (lambda > 0.0)
        {
            version (alterQ)
            {
                directory ~= format("change_at_%s/", alterIter);
            }
            else
            {
                directory ~= "no_change/";
            }
        }
        directory ~= format("%s/%s/", langSize, qualitiesString);
        auto append = "w";

        // Best-choice belief
        fileName = "average_beliefs" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, maxIterations, choiceResults);

        // Powerset belief
        if (langSize < powersetLimit)
        {
            fileName = "average_masses" ~ "_" ~ randomFN ~ fileExt;
            writeToFile(directory, fileName, append, maxIterations, powersetResults);
        }

        // Unique Beliefs
        fileName = "unique_beliefs" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, maxIterations, uniqueResults);

        // Inconsistency
        /* fileName = "inconsistency" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, maxIterations, inconsistResults); */

        // Entropy
        fileName = "entropy" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, maxIterations, entropyResults);

        // Cardinality
        fileName = "cardinality" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, maxIterations, cardMassResults);

        // Payoff
        /* fileName = "payoff" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, maxIterations, payoffResults); */

        // Maximum payoff
        /* fileName = "max_payoff" ~ "_" ~ randomFN ~ fileExt;
        writeToFile(directory, fileName, append, maxIterations, maxPayoffResults); */

        static if (!gamma && !iota)
        {
            // Steady state belief results
            fileName = "steadystate_beliefs" ~ "_" ~ randomFN ~ fileExt;
            writeToFile(directory, fileName, append, maxIterations, steadyStateBeliefs);
        }
    }
}

private void writeToFile(T)(string directory, string fileName, string append,
        T[][] results, int maxIterations)
{
    results = extendResults(results, maxIterations);
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

private void extendResults(T)(T[][] results, int maxIterations)
{
    int lastIteration;
    for (auto i = 0; i < maxiterations; i++)
    {
        if (lastIterations == int.init)
        {
            if (!results[i].find("").empty)
            {
                lastIteration = i - 1;
            }
        }
        if (lastIteration != int.init)
        {
            results[i] = results[lastIteration].dup;
        }
    }

    return results[0 .. maxIterations];
}

module dempshaf.world;

import dempshaf.ai.agent;
import dempshaf.consensus.operators;
import dempshaf.consensus.ds;

import core.stdc.stdlib;
import std.algorithm, std.array, std.conv, std.getopt, std.math;
import std.random, std.range, std.stdio, std.string, std.traits;

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
    immutable auto iterStep = iterations / 1;
    immutable auto testSet = 10;
    // alpha (a) is a parameter for negative evidential updating, such that 1-a is the
    // mass assigned to the set of all choices minus the worst choice selected (at random).
    // The set of complete ignorance is then assigned a mass of a.
    // immutable auto alpha = 0.0;
    // gamma is used as a switch to determine whether we should threshold the operator
    // based on similarity of the agents' beliefs. This parameter attempts to control
    // how imprecise agents' beliefs are at steady state.
    immutable auto gamma = false;
    // The lambda operator is used to adjust the fixed points of the combination
    //operators (away from the corners). Default: 0.0 means no adjustment.
    immutable auto lambda = 0.0;
    // iota is used as a switch to determine whether we should threshold the operator
    // based on relative inconsistency between pairs of agents.
    immutable auto iota = false;
    // immutable auto evidenceRate = 2/100.to!double;
    immutable auto paramHeatmaps = false;
    immutable auto qualityHeatmaps = false;
    immutable auto alterIter = 10;
    immutable bool setSeed = true;

    // Convergence parameters and variables
    // immutable auto changeThreshold = 50;     This was seen as no. of agents / 2
    immutable auto changeThreshold = 50;

    // Default precision for approxEqual is 1e-2.
    alias precision = DempsterShafer.precision;

    // An alias for one of two combination functions:
    // Consensus operator, and Dempster's rule of combination

    alias combination = Operators.consensus;
    // alias combination = Operators.average;
    // alias combination = Operators.dempsterRoC;
    // alias combination = Operators.yager;

    // Only record steadystate results
    immutable auto steadyStatesOnly = false;
    // Disable consensus formation
    immutable auto evidenceOnly = true;
    // Disable evidential updating
    immutable auto consensusOnly = false;
    // Evidence is random, not probabilistic:
    immutable auto randomEvidence = false;
    // Agents receive negative information.
    immutable auto negativeEvidence = false;

    // Set whether evidence should be associated with noise
    // and set the paramater value for the noise if so.
    // If noiseVariance = 0.0, then no noise is added.
    immutable auto noisyEvidence = false;
    // [0.025, 0.05, 0.1, 0.2, 0.3]
    static if (negativeEvidence && noisyEvidence)
    {
        double[] parameterSet = [
            -10.0, -5.0, -3.0, -1.0, -0.1, 0.0, 1.0, 3.0, 5.0, 10.0, 20.0, 100.0
        ];
    }
    else static if (noisyEvidence) immutable auto noiseVariance = 0.025;
    else                           immutable auto noiseVariance = 0.0;

    if ((paramHeatmaps || qualityHeatmaps) && !steadyStatesOnly)
    {
        writeln("If producing heatmaps, steadyStatesOnly must be true.");
        exit(1);
    }

    if (gamma && fullyQualifiedName!combination.canFind("dempster"))
    {
        writeln("Cannot run gamma-thresholding for Dempster's rule.");
        exit(1);
    }

    if (evidenceOnly && consensusOnly)
    {
        writeln("evidenceOnly and consensusOnly are mutually ",
                "exclusive and cannot both be true.");
        exit(1);
    }

    bool randomSelect = true;
    int langSize, numOfAgents;

    writeln("Running program: ", args[0].split("/")[$ - 1]);

    writeln("Simulation length: ", iterations, " iterations");

    getopt(args,
        "random", &randomSelect
    );

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
    version (boolean) writeln("Boolean");
    else  writeln("Three-valued");

    write("Updating method: ");
    version (symmetric)  writeln("! SYMMETRIC !");
    else writeln("! ASYMMETRIC !");

    writeln("Combination function: ", fullyQualifiedName!combination.split(".")[$ - 1]);

    // writeln("Evidence rate: ", evidenceRate);

    writeln("Lambda value: ", lambda);
    version (alterQ) writeln("Altering value(s) after ", alterIter, " iterations.");

    writeln("Random selection: ", randomSelect);

    write("Evidence mass: ");
    static if (negativeEvidence) writeln("negative");
    else static if (randomEvidence) writeln("random");
    else writeln("probabilistic");

    static if (negativeEvidence && noisyEvidence) writeln("Noise: noisy comparisons");
    else static if (noisyEvidence) writeln("Noise: ", noiseVariance);

    if (evidenceOnly)
        writeln("!!! EVIDENCE-ONLY VERSION: FOR BENCHMARKING ONLY !!!");
    if (consensusOnly)
        writeln("!!! CONSENSUS-ONLY VERSION: FOR TESTING PURPOSES ONLY !!!");

    // Set static array in Dempster-Shafer module using langSize
    DempsterShafer.staticVector     = new int[langSize];
    DempsterShafer.staticSet        = new int[langSize];
    DempsterShafer.staticPignistic  = new double[langSize];

    // Prepare arrays for storing all results collected during simulation
    static if (steadyStatesOnly) immutable int arraySize = 1;
    else immutable int arraySize = iterStep + 1;

    // Initialize the population of agents according to population size l
    auto population = new Agent[numOfAgents];
    foreach (ref agent; population)
        agent = new Agent();

    //*************************************
    immutable auto qualityIndex = args[$ - 1].to!int;
    //*************************************
    immutable auto masterQStrings = [
        "[0.3, 0.9]",
        "[0.5, 1.0]",
        "[0.9, 1.0]",

        "[0.2, 0.4, 1.0]",
        "[0.25, 0.5, 0.75]",
        "[0.8, 0.9, 1.0]",

        "[0.1666, 0.3333, 0.5, 0.6666, 0.8333]",

        "[0.0909, 0.1818, 0.2727, 0.3636, 0.4545, 0.5454, 0.6363, 0.7272, 0.8181, 0.9090]",

        "[0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 1.0]"
    ];
    double[][] masterQualities;
    static foreach (qstring; masterQStrings)
        masterQualities ~= mixin(qstring);
    auto qualities = masterQualities.filter!(a => a.length == langSize).array[qualityIndex].dup;
    auto qualitiesString = masterQStrings.filter!(a => a.split(",")
            .length == langSize).array[qualityIndex];
    writeln("Qualities: ", qualities);
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
        double[] parameterSet, parameterTempSet;
        parameterTempSet ~= 0.0;
        foreach (double i; 1 .. langSize + 1)
        {
            foreach (double j; 1 .. i)
            {
                parameterTempSet ~= j / i;
            }
        }
        parameterTempSet ~= 1.0;
        parameterTempSet = parameterTempSet.sort.uniq.array;
        write(parameterTempSet, " --> ");
        foreach (index; 0 .. parameterTempSet.length.to!long - 1)
            parameterSet ~= (parameterTempSet[index] + parameterTempSet[index + 1]) / 2.0;
        writeln(parameterSet);
    }
    else static if (iota)
    {
        double[] parameterSet;
        foreach (parameter; 0 .. 11)
            parameterSet ~= (parameter / 10.0).to!double;
        foreach (parameter; 91 .. 100)
            parameterSet ~= (parameter / 100.0).to!double;
        parameterSet.sort;
        writeln(parameterSet);
    }
    else static if (paramHeatmaps)
    {
        int[] parameterSet = [2, 3, 5, 7, 9, 10];
    }
    else static if (qualityHeatmaps){}
    else static if (negativeEvidence && noisyEvidence){}
    else
    {
        // immutable double[] parameterSet = [0.0];
        immutable double[] parameterSet = [
            0.0, 0.001, 0.002, 0.003, 0.004, 0.005, 0.006, 0.007, 0.008, 0.009,
            0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09,
            0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0
            // 0.9, 1.0
        ];
        writeln("Evidence rate: ", parameterSet);
    }

    // Generate the frame of discernment (power set of the propositional variables)
    immutable auto belLength = ((2 ^^ langSize) - 1).to!int;
    immutable auto powersetLimit = 5;
    if (langSize <= powersetLimit)
    {
        auto powerset = DempsterShafer.generatePowerset(langSize);
        writeln("Powerset: ", powerset);
    }
    // Generate the indices of the hypotheses' singletons
    auto belIndices = new int[langSize];
    foreach (i; 0 .. langSize)
    {
        auto vector = new int[langSize];
        vector[i] = 1;
        belIndices[i] = DempsterShafer.vecToIndex(vector);
    }
    writeln("Belief indices: ", belIndices);

    // Find the choice with the highest payoff, and store its index in the power set.
    writeln(qualities);
    int bestChoice = qualities.maxIndex.to!int;
    if (qualities[$-2] == qualities[$-1])
        bestChoice = qualities.length.to!int - 1;

    auto belPlIndices = DempsterShafer.belAndPlIndices(langSize, bestChoice);
    writeln("Bel() and Pl() indices: ", belPlIndices);

    // The maximum number of iterations across all tests, such that tests reaching
    // a steady state by smaller iteration counts should be extended to maxIterations.
    auto maxIterations = int.init;

    writeln("----------");

    /*
     * For each threshold in thresholdSet, run the experiment using that value of gamma.
     */
    foreach (parameter; parameterSet)
    {
        static if (gamma)
        {
            writeln("gamma threshold: %.4f".format(parameter));
            immutable auto threshold = parameter;
        }
        else static if (iota)
        {
            writeln("iota threshold: %.2f".format(parameter));
            immutable auto threshold = parameter;
        }
        else immutable auto threshold = 0.0;

        static if (paramHeatmaps)
        {
            writeln("Language size: %d".format(parameter));
            langSize = parameter;
        }

        static if (parameterSet.length > 1)
        {
            immutable auto evidenceRate = parameter;
            writeln(parameter);
        }

        auto seed = setSeed ? 1024 : unpredictableSeed;
        auto rand = Random(seed);

        // auto inconsistResults   = new string[][](arraySize, testSet);
        auto entropyResults     = new double[][](arraySize, testSet);
        // auto uniqueResults      = new long[][](arraySize, testSet);
        // uniqueResults.each!(x => x[] = -1L);
        auto choiceResults      = new double[][][](arraySize, testSet, langSize);
        // auto powersetResults    = new double[][][](arraySize, testSet, belLength);
        auto belPlResults       = new double[][][](arraySize, testSet, 2);
        auto cardMassResults    = new double[][](arraySize, testSet);
        // auto steadyStateBeliefs = new double[][][](numOfAgents, testSet, langSize);
        // auto agentsForTrajectories = std.range.iota(numOfAgents)
        //                                       .randomSample(5, rand)
        //                                       .array;
        // auto trajectoryBeliefs = new double[][][](arraySize, agentsForTrajectories.length, 3);

        auto populationIndices = new ulong[numOfAgents];
        foreach (index; 0 .. numOfAgents)
            populationIndices[index] = index;

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
            if (qualities[$-2] == qualities[$-1])
                bestChoice = qualities.length.to!int - 1;

            foreach (agentIndex, ref agent; population)
            {
                double[int] beliefs;
                // If no evidential updating is taking place, then randomly
                // initialise the agents' beliefs.
                static if (consensusOnly)
                {
                    // beliefs[std.range.iota(belLength).choice(rand)] = 1.0;
                    auto partitions = new double[belLength - 1];
                    foreach (ref elem; partitions) elem = uniform!"[]"(0.0, 1.0, rand);
                    partitions.sort;
                    foreach (index; 0 .. belLength)
                    {
                        if (index == 0) beliefs[index] = partitions[index];
                        else if (index < belLength - 1)
                            beliefs[index] = partitions[index] - partitions[index - 1];
                        else beliefs[index] = 1 - partitions[index - 1];
                    }
                }
                else beliefs[belLength - 1] = 1.0;

                agent.beliefs = beliefs;
                agent.resetInteractions;
            }
            /*
            * Iteration loop;
            * Agents interact according to broadcasting/listening rules,
            * but states are not discrete and separate.
            */
            int iterIndex;
            auto choiceBeliefs = new double[langSize];
            // auto powersetBeliefs = new double[belLength];
            // double[int][] uniqueBeliefs;
            // int[] uniqueBeliefsCount;
            double[2] belPl;
            // double inconsist,
            double entropy, cardinality;
            bool append, reachedSteadyState;

            version (asymmetric) auto snapshotPopulation = new Agent[numOfAgents];

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
                    choiceBeliefs[] = 0.0;
                    /* if (langSize < powersetLimit)
                        powersetBeliefs[] = 0.0; */

                    belPl = [0.0, 0.0];
                    // uniqueBeliefs.length = 0;
                    // uniqueBeliefsCount.length = 0;
                    // inconsist =
                    entropy = cardinality = 0.0;
                    reachedSteadyState = true;

                    foreach (i, ref agent; population)
                    {
                        auto beliefs = agent.beliefs;

                        /*
                         * Perhaps this is where I should increment the time_since_change
                         * counter, so that the time since their last change is actual
                         * iterations and not interactions...
                         */

                        /* append = true;
                        foreach (uniqIndex, unique; uniqueBeliefs)
                        {
                            // First compare whether the keys match. If they do, then
                            // the same subset has already been found. Then, check
                            // whether the masses for those subsets are the same.
                            if (unique.keys.sort.equal(beliefs.keys.sort) && unique.keys
                                .sort
                                .map!(a => unique[a])
                                .equal!approxEqual(
                                    beliefs.keys.sort.map!(a => beliefs[a])
                                ))
                            {
                                append = false;
                                uniqueBeliefsCount[uniqIndex]++;
                                break;
                            }
                        }
                        if (append)
                        {
                            uniqueBeliefs ~= beliefs;
                            uniqueBeliefsCount ~= 1;
                        } */

                        // Calculate average entropy of agents' beliefs
                        entropy += DempsterShafer.entropy(beliefs);

                        foreach (index, belIndex; belIndices)
                        {
                            if (belIndex in beliefs)
                            {
                                choiceBeliefs[index] += beliefs[belIndex];
                                if (belPlIndices[0].canFind(belIndex))
                                    belPl[0] += beliefs[belIndex];
                            }
                        }
                        /* if (langSize < powersetLimit)
                            foreach (index; 0 .. belLength)
                                if (index in beliefs)
                                    powersetBeliefs[index] += beliefs[index]; */

                        foreach (index, ref bel; beliefs)
                        {
                            if (belPlIndices[1].canFind(index))
                                belPl[1] += bel;
                            cardinality += bel * DempsterShafer.createSet(index).length;
                        }

                        // Check if agent has reached a steady state
                        if (agent.timeSinceChange < changeThreshold)
                        {
                            reachedSteadyState = false;
                        }
                    }

                    entropy /= numOfAgents;
                    assert(!entropy.isNaN);
                    // inconsist = (2 * inconsist) / (n * (n - 1));
                    choiceBeliefs[] /= numOfAgents;
                    belPl[] /= numOfAgents;
                    /* if (langSize < powersetLimit)
                        foreach (index; 0 .. belLength)
                            powersetBeliefs[index] /= numOfAgents; */
                    cardinality /= numOfAgents;

                    // Format and store the resulting simulation data into their
                    // respective arrays.

                    if (!steadyStatesOnly || (reachedSteadyState && iter % 100 == 1) || iter == iterations)
                    {
                        // inconsistResults[iterIndex][test]  = format("%.4f", inconsist);
                        entropyResults[iterIndex][test] = entropy;
                        // uniqueResults[iterIndex][test] = uniqueBeliefs.length;
                        choiceResults[iterIndex][test] = choiceBeliefs.dup;
                        /* if (langSize < powersetLimit)
                        {
                            powersetResults[iterIndex][test] = powersetBeliefs.dup;
                        } */
                        belPlResults[iterIndex][test] = belPl.dup;
                        cardMassResults[iterIndex][test] = cardinality;

                        // Plot agent trajectories for plotting barycentric plots
                        /* if (langSize == 2)// && test == 15)
                        {
                            foreach (i, agentIndex; agentsForTrajectories)
                            {
                                trajectoryBeliefs[iterIndex][i][0] = (0 in population[agentIndex].beliefs) ?
                                    population[agentIndex].beliefs[0] : 0 ;
                                trajectoryBeliefs[iterIndex][i][1] = (1 in population[agentIndex].beliefs) ?
                                    population[agentIndex].beliefs[1] : 0 ;
                                trajectoryBeliefs[iterIndex][i][2] = (2 in population[agentIndex].beliefs) ?
                                    population[agentIndex].beliefs[2] : 0 ;
                            }
                        } */

                        iterIndex++;
                    }
                }

                /*
                 * If simulation has reached steady state and is at convenient
                 * cut-off point, then end this test.
                 */
                if ((reachedSteadyState && iter % 100 == 1) || iter == iterations)
                {
                    if (reachedSteadyState && iter % 100 == 1)
                        maxIterations = (iter > maxIterations) ? iter : maxIterations;

                    // Grab the steady state results.
                    /* static if (!gamma && !iota)
                    {
                        foreach (i, ref agent; population)
                        {
                            auto beliefs = agent.beliefs;
                            steadyStateBeliefs[i][test] = belIndices
                                .map!(x => (x in beliefs) ? beliefs[x] : 0.0).array;
                        }
                    }

                    static if (steadyStatesOnly) maxIterations = int.init; */
                    break;
                }

                static if (!consensusOnly)
                {
                    version(asymmetric)
                    {
                        foreach (i; populationIndices)
                        {
                            Agent agent = population[i];

                            if (uniform01(rand) > evidenceRate)
                                continue;

                            static if (negativeEvidence)
                            {
                                agent.beliefs(
                                    combination(
                                        langSize, agent.beliefs,
                                        DempsterShafer.negMassEvidence(
                                            qualities, noisyEvidence,
                                            parameter, rand),
                                        0.0, false, lambda
                                    ),
                                    true
                                );
                            }
                            // If evidence should be provided for a random choice.
                            else static if (randomEvidence)
                            {
                                agent.beliefs(
                                    combination(
                                        langSize, agent.beliefs,
                                        DempsterShafer.randMassEvidence(
                                            qualities, rand),
                                        0.0, false, lambda
                                    ),
                                    true
                                );
                            }
                            // Else, evidence should favour the most prominent choice.
                            else
                            {
                                agent.beliefs(
                                    combination(
                                        langSize, agent.beliefs,
                                        DempsterShafer.probMassEvidence(
                                            qualities, noiseVariance, agent.beliefs, rand),
                                        0.0, false, lambda
                                    ),
                                    true
                                );
                            }
                        }
                    }
                    version(symmetric)
                    {
                        foreach (i; populationIndices)
                        {
                            Agent agent = population[i];

                            if (uniform01(rand) > evidenceRate)
                                continue;

                            static if (negativeEvidence)
                            {
                                agent.beliefs(
                                    combination(
                                        langSize, agent.beliefs,
                                        DempsterShafer.negMassEvidence(
                                            qualities, noisyEvidence,
                                            parameter, rand),
                                        0.0, false, lambda
                                    ),
                                    true
                                );
                            }
                            // If evidence should be provided for a random choice.
                            else static if (randomEvidence)
                            {
                                agent.beliefs(
                                    combination(
                                        langSize, agent.beliefs,
                                        DempsterShafer.randMassEvidence(
                                            qualities, rand),
                                        0.0, false, lambda
                                    ),
                                    true
                                );
                            }
                            // Else, evidence should favour the most prominent choice.
                            else
                            {
                                agent.beliefs(
                                    combination(
                                        langSize, agent.beliefs,
                                        DempsterShafer.probMassEvidence(
                                            qualities, noiseVariance, agent.beliefs, rand),
                                        0.0, false, lambda
                                    ),
                                    true
                                );
                            }
                        }
                    }
                }
                /*
                * Agents conduct some form of belief-merging/"consensus".
                */
                static if (!evidenceOnly)
                {
                    if (populationIndices.length > 2)
                    {
                        Agent selected;
                        int selection;

                        version (symmetric)
                        {
                            int i = populationIndices.choice(rand).to!int;
                            do selection = populationIndices.choice(rand).to!int;
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

                            // If newBeliefs is null, then the agents were completely
                            // inconsistent anyway.
                            if (newBeliefs !is null)
                            {
                                agent.beliefs(newBeliefs, true);
                                selected.beliefs(newBeliefs, true);
                            }
                        }
                        else
                        {
                            foreach (index, ref snapshotAgent; snapshotPopulation)
                                snapshotAgent = population[index].dup;
                            foreach (i; populationIndices)
                            {
                                do selection = populationIndices.choice(rand).to!int;
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
                                    if (inconsistency > threshold &&
                                        !inconsistency.approxEqual(threshold, precision))
                                    {
                                        continue;
                                    }
                                }

                                auto newBeliefs = combination(langSize, agent.beliefs,
                                    selected.beliefs, threshold, affectOperator, lambda);

                                // If newBeliefs is null, then the agents were completely
                                // inconsistent anyway.
                                if (newBeliefs !is null) agent.beliefs(newBeliefs, true);
                            }
                        }
                    }
                }
            }
        }

        writeln("Writing results...");

        // Write results to disk for current test.
        string fileName;
        string fileExt = ".csv";
        string randomFN = "";
        if (randomSelect) randomFN = "random";

        /*
        * Change the directory to store results in the appropriate directory structure.
        */
        string directory = "../results/test_results/dempshaf/";

        static if (!paramHeatmaps)
            directory ~= "%s_agents/".format(numOfAgents);

        version (symmetric) directory ~= "symmetric/";
        static if (lambda > 0.0) directory ~= "lambda_operator_%.1f/".format(lambda);
        static if (fullyQualifiedName!combination.canFind("Operators.dempster"))
            directory ~= "dempsters_operator/";
        else static if (fullyQualifiedName!combination.canFind("Operators.consensus"))
            directory ~= "consensus_operator/";
        else static if (fullyQualifiedName!combination.canFind("Operators.average"))
            directory ~= "average_operator/";
        else static if (fullyQualifiedName!combination.canFind("Operators.yager"))
            directory ~= "yagers_operator/";
        static if (negativeEvidence) directory ~= "negative_evidence/";
        else static if (evidenceOnly) { /* directory ~= "evidence_only/"; */ }
        static if (lambda > 0.0)
        {
            version (alterQ)
                directory ~= "change_at_%s/".format(alterIter);
            else
                directory ~= "no_change/";
        }
        static if (!paramHeatmaps)
            directory ~= "%s/%s/".format(langSize, qualitiesString);
        auto append = "w";

        auto parameterString = "";

        // Append evidence_rate for comparison figures
        parameterString ~= "_%.3f_er".format(evidenceRate);

        static if (negativeEvidence && noisyEvidence)
            parameterString ~= "_lambda_%.2f".format(parameter);
        else static if (noisyEvidence) parameterString ~= "_%.4f".format(noiseVariance);
        static if (gamma) parameterString ~= "_%.4f".format(parameter);
        else static if (iota) parameterString ~= "_%.2f".format(parameter);
        static if (paramHeatmaps) parameterString ~= "_" ~ numOfAgents.to!string
                                                   ~ "_" ~ langSize.to!string;
        else static if (evidenceOnly) parameterString ~= "_eo";

        // Best-choice belief
        fileName = "average_beliefs" ~ "_" ~ randomFN ~ parameterString ~ fileExt;
        writeToFileNested(directory, fileName, append, maxIterations, choiceResults);

        // Powerset belief
        /* if (langSize < powersetLimit)
        {
            fileName = "average_masses" ~ "_" ~ randomFN ~ parameterString ~ fileExt;
            writeToFileNested(directory, fileName, append, maxIterations, powersetResults);
        } */

        // Best-choice Bel and Pl
        fileName = "belief_plausibility" ~ "_" ~ randomFN ~ parameterString ~ fileExt;
        writeToFileNested(directory, fileName, append, maxIterations, belPlResults);

        // Unique Beliefs
        // fileName = "unique_beliefs" ~ "_" ~ randomFN ~ parameterString ~ fileExt;
        // writeToFile(directory, fileName, append, maxIterations, uniqueResults);

        // Inconsistency
        /* fileName = "inconsistency" ~ "_" ~ randomFN ~ parameterString ~ fileExt;
        writeToFile(directory, fileName, append, maxIterations, inconsistResults); */

        // Entropy
        fileName = "entropy" ~ "_" ~ randomFN ~ parameterString ~ fileExt;
        writeToFile(directory, fileName, append, maxIterations, entropyResults);

        // Cardinality
        fileName = "cardinality" ~ "_" ~ randomFN ~ parameterString ~ fileExt;
        writeToFile(directory, fileName, append, maxIterations, cardMassResults);

        // static if (!gamma && !iota)
        // {
        //     // Steady state belief results
        //     fileName = "steadystate_beliefs" ~ "_" ~ randomFN ~ parameterString ~ fileExt;
        //     writeToFileNested(directory, fileName, append, maxIterations, steadyStateBeliefs);
        // }

        // if (langSize == 2)
        // {
        //     // Trajectory belief results for selected agents
        //     fileName = "trajectory_beliefs" ~ "_" ~ randomFN ~ parameterString ~ fileExt;
        //     writeToFileNested(directory, fileName, append, maxIterations, trajectoryBeliefs);
        // }
    }
}

private void writeToFileNested(T)(string directory, string fileName, string append,
                            int maxIterations, T[][][] results)
{
    // Convert results array to strings here
    auto convertedResults = new string[][](results.length, results[0].length);
    foreach (i, ref row; results)
    {
        foreach (j, ref col; row)
        {
            if (is(typeof(col[0]) == long))
                convertedResults[i][j] = "["
                    ~ col
                    .map!(x => "%d".format(x))
                    .join(",")
                    ~ "]";
            else if (is(typeof(col[0]) == double))
            {
                if (col[0].isNaN)
                {
                    convertedResults[i][j] = "";
                }
                else
                {
                    convertedResults[i][j] = "["
                        ~ col
                        .map!(x => "%.4f".format(x))
                        .join(",")
                        ~ "]";
                }
            }
        }
    }

    // END

    if (maxIterations != int.init && !fileName.canFind("steadystate"))
        convertedResults = extendResults(convertedResults, maxIterations);
    auto file = File(directory ~ fileName, append);
    foreach (i, ref index; convertedResults)
    {
        foreach (j, ref test; index)
        {
            file.write(convertedResults[i][j]);
            file.write((j == cast(ulong) convertedResults[i].length - 1) ? "\n" : ",");
        }
    }
    file.close();
}

private void writeToFile(T)(string directory, string fileName, string append,
                            int maxIterations, T[][] results)
{
    // Convert results array to strings here
    auto convertedResults = new string[][](results.length, results[0].length);
    foreach (i, ref row; results)
    {
        foreach (j, ref col; row)
        {
            if (is(typeof(col) == long))
                convertedResults[i][j] = (col == -1) ? "" : "%d".format(col);
            else if (is(typeof(col) == double))
                convertedResults[i][j] = (col.to!double.isNaN) ? "" : "%.4f".format(col);
        }
    }

    // END

    if (maxIterations != int.init && !fileName.canFind("steadystate"))
        convertedResults = extendResults(convertedResults, maxIterations);
    auto file = File(directory ~ fileName, append);
    foreach (i, ref index; convertedResults)
    {
        foreach (j, ref test; index)
        {
            file.write(convertedResults[i][j]);
            file.write((j == cast(ulong) convertedResults[i].length - 1) ? "\n" : ",");
        }
    }
    file.close();
}

private T[][] extendResults(T)(ref T[][] results, int maxIterations)
{
    // Results are two-dimensional arrays of the form:
    // [ iteration 1 : [test 0] [test 1] ... [test N]
    //   ...
    //   iteration N : [test 0] [test 1] ... [test N] ]
    for (auto i = 0; i < maxIterations; i++)
    {
        for (auto j = 0; j < results[i].length; j++)
            if (results[i][j] == "" && i-1 >= 0) results[i][j] = results[i-1][j];
    }
    return results[0 .. maxIterations];
}

module dempshaf.consensus.ds;

import dempshaf.misc.importidiom;

/**
 * DempsterShafer is a class for containing all of the calculation functions
 * specific to the DempsterShafer model of beliefs.
 */
public class DempsterShafer
{
    /**
     * Set the precision of the approxEqual checks.
     */
    static immutable auto precision = 1e-4;

    /**
     * Generate the binary vector based on the set provided,
     * and the language size.
     */
    static auto setToVec(
        const int langSize,
        const int[] set) pure
    {
        int[] binaryVector = new int[langSize];

        foreach (ref element; set)
        {
            binaryVector[element] = 1;
        }

        return binaryVector;
    }

    unittest
    {
        import std.stdio : writeln;

        writeln("Unit tests:\tsetToVec : from set");

        int langSize = 3;
        auto set = [0, 2];
        assert(setToVec(langSize, set) == [1, 0, 1]);
        set = [1, 2];
        assert(setToVec(langSize, set) == [0, 1, 1]);
        set = [0, 1, 2];
        assert(setToVec(langSize, set) == [1, 1, 1]);

        langSize = 5;
        set = [0];
        assert(setToVec(langSize, set) == [1, 0, 0, 0, 0]);
        set = [0, 1, 2, 3, 4];
        assert(setToVec(langSize, set) == [1, 1, 1, 1, 1]);
        set = [0, 2, 4];
        assert(setToVec(langSize, set) == [1, 0, 1, 0, 1]);

        writeln("\t\tPASSED.");
    }

    /**
     * Generate the binary vector based on its index in the powerset,
     * and then return the vector.
     */
    static auto indexToVec(
        const int langSize,
        const int index) pure
    {
        int[] binaryVector = new int[langSize];
        int correctedIndex = index + 1;

        foreach (ref element; binaryVector)
        {
            element = (correctedIndex % 2 == 0) ? 0 : 1;
            correctedIndex /= 2;
        }

        return binaryVector;
    }

    unittest
    {
        import std.stdio : writeln;

        writeln("Unit tests:\tindexToVec : from index");

        int langSize = 3;
        int index;
        assert(indexToVec(langSize, index) == [1, 0, 0]);
        index = 5;
        assert(indexToVec(langSize, index) == [0, 1, 1]);
        index = 6;
        assert(indexToVec(langSize, index) == [1, 1, 1]);

        langSize = 5;
        index = 0;
        assert(indexToVec(langSize, index) == [1, 0, 0, 0, 0]);
        index = 30;
        assert(indexToVec(langSize, index) == [1, 1, 1, 1, 1]);
        index = 20;
        assert(indexToVec(langSize, index) == [1, 0, 1, 0, 1]);

        writeln("\t\tPASSED.");
    }

    /**
     * Generate the set based on its index, first calling indexToVec
     * and then returning the set.
     */
    static auto createSet(
        const int langSize,
        const int index) pure
    {
        import std.algorithm.searching : count;
        import std.conv : to;

        auto vector = indexToVec(langSize, index);

        auto set = new int[vector.count(1)];
        auto fillIndex = 0;
        foreach (i, ref value; vector)
        {
            if (value == 1)
            {
                set[fillIndex] = i.to!int;
            }
        }
        return set;
    }

    unittest
    {
        import std.stdio : writeln;

        writeln("Unit tests:\tcreateSet : from index");

        int langSize = 3;
        int index;
        assert(createSet(langSize, index) == [0]);

        index = 3;
        assert(createSet(langSize, index) == [2]);

        index = 5;
        assert(createSet(langSize, index) == [1, 2]);

        writeln("\t\tPASSED.");
    }

    /**
     * Generate the set based on its binary vector, and then return
     * the set.
     */
    static auto createSet(const int[] vector) pure
    {
        import std.conv : to;

        int[] set;
        foreach (i, ref value; vector)
        {
            if (value == 1)
            {
                set ~= i.to!int;
            }
        }

        return set;
    }

    unittest
    {
        import std.stdio : writeln;

        writeln("Unit tests:\tcreateSet : from vector");

        auto vector = [1, 0, 0];
        auto set = createSet(vector);
        assert(set == [0]);

        vector = [0, 0, 1];
        set = createSet(vector);
        assert(set == [2]);

        vector = [0, 1, 1];
        set = createSet(vector);
        assert(set == [1, 2]);

        writeln("\t\tPASSED.");
    }

    /**
     * Calculate the index of the set in the powerset.
     */
    static auto setToIndex(
        const int langSize,
        const int[] set) pure
    {

        auto vector = setToVec(langSize, set);

        int index;
        foreach (i, ref value; vector)
        {
            index += value * 2^^i;
        }

        return index - 1;
    }

    /**
     * Calculate the index of the vector in the powerset.
     */
    static auto vecToIndex(const int[] vector) pure
    {

        int index;
        foreach (i, ref value; vector)
        {
            index += value * 2^^i;
        }

        return index - 1;
    }

    unittest
    {
        import std.stdio : writeln;

        writeln("Unit tests:\tvecToIndex");

        int[] vector = [1, 1, 1];
        assert(vecToIndex(vector) == 6);

        vector = [1, 0, 1];
        assert(vecToIndex(vector) == 4);

        vector = [1, 0, 0];
        assert(vecToIndex(vector) == 0);

        vector = [0, 0, 1];
        assert(vecToIndex(vector) == 3);

        writeln("\t\tPASSED.");
    }

    /**
     * The Hellinger distance for two discrete probability distributions,
     * applied to the pignistic distributions of each agent's beliefs.
     */
    static auto distance(
        const int langSize,
        const double[int] beliefs1,
        const double[int] beliefs2) pure
    {
        import std.math : sqrt;

        auto pignisticBel1 = pignisticDist(langSize, beliefs1);
        auto pignisticBel2 = pignisticDist(langSize, beliefs2);

        double distance = 0.0;
        double sum = 0.0;
        foreach (i; 0 .. langSize)
            sum += (sqrt(pignisticBel1[i]) - sqrt(pignisticBel2[i])) ^^2;

        distance += (1.0 / sqrt(2.0)) * sqrt(sum);

        return distance;
    }

    /**
     * Calculates the Deng entropy of an agent's mass function: a measure of uncertainty.
     */
    static auto entropy(
        const int langSize,
        const double[int] beliefs) pure
    {
        import std.math : approxEqual, log2;

        double entropy = 0.0;

        foreach (index, belief; beliefs)
        {
            if (approxEqual(belief, 0.0))
                continue;
            entropy -= belief * log2(
                belief/((2^^createSet(langSize, index).length)-1)
            );
        }

        return entropy;
    }

    /**
     * Inconsistency measure between two beliefs.
     */
    static auto inconsistency(
        const int langSize,
        const double[int] beliefs1,
        const double[int] beliefs2) pure
    {
        import std.algorithm : find, setIntersection, sort, sum, uniq;
        import std.math : approxEqual;

        double inconsistency = 0.0;

        foreach (i, ref bel1; beliefs1)
        {
            // If the mass is 0, skip this set.
            if (approxEqual(bel1, 0.0))
                continue;
            foreach (j, ref bel2; beliefs2)
            {
                // If the mass is 0, skip this set.
                if (approxEqual(bel2, 0.0))
                    continue;

                auto set1 = createSet(langSize, i);
                auto set2 = createSet(langSize, j);
                auto intersection = setIntersection(set1, set2);
                if (intersection.empty)
                {
                    // If the intersection is the empty set, add the product of the
                    // beliefs to the inconsistency sum.
                    inconsistency += bel1 * bel2;
                }
            }
        }

        return inconsistency;
    }

    /**
     * Generates the power set (frame of discernment) from the number of
     * propositional variables given as l.
     */
    static auto generatePowerset(const int langSize) pure
    {
        import std.algorithm.sorting : sort;

        auto powerset = new int[][]((2^^langSize));
        auto props = new int[langSize];

        foreach (ref set; powerset)
        {
            foreach (int i, ref prop; props)
                if (prop == 1) set ~= i;

            props[0]++;
            foreach (i, ref prop; props[0 .. $-1])
                if (prop > 1)
                {
                    prop = 0;
                    props[i+1]++;
                }
        }

        auto tempSet = powerset.sort();
        powerset = null;
        foreach (ref level; 0 .. langSize + 1)
            foreach (ref prop; 0 .. langSize)
                foreach (ref set; tempSet)
                    if (set.length > 0)
                        if (set.length == level && set[0] == prop)
                            powerset ~= set;

        return powerset;
    }

    unittest
    {
        import std.stdio : writeln;

        writeln("Unit tests:\tgeneratePowerset");

        auto langSize = 1;
        auto powerset = generatePowerset(langSize);
        assert(powerset == [[0]]);

        langSize = 2;
        powerset = generatePowerset(langSize);
        assert(powerset == [[0], [1], [0, 1]]);

        langSize = 3;
        powerset = generatePowerset(langSize);
        assert(powerset == [[0], [1], [2], [0, 1], [0, 2], [1, 2], [0, 1, 2]]);

        writeln("\t\tPASSED.");
    }

    /**
     * Generate the indices for both belief and plausibily, so that
     * you can calculate these later on without having to generate
     * the vectors every time in order to retrieve the indices.
     */
    static auto belAndPlIndices(in int langSize, ) pure
    {

    }

    unittest
    {
        import std.stdio : writeln;

        writeln("Unit tests:\tbelAndPlIndices");



        writeln("\t\tPASSED.");
    }

    /**
     * Calculates the evidential mass assignment based on the agent's current
     * beliefs. This prioritises the most dominant choice to receive feedback (payoff
     * so that more accurate beliefs are reinforced, and inaccurate beliefs are
     * punished.
     */
    static auto probMassEvidence(
        const double[] qualities,
        const double[int] beliefs,
        ref from!"std.random".Random rand) pure
    {
        import std.conv : to;
        import std.random : uniform01;

        auto langSize = qualities.length.to!int;
        auto pignisticBel = pignisticDist(langSize, beliefs);
        immutable auto prob = uniform01(rand);
        auto sum = 0.0;
        int choice;
        foreach (int i, ref bel; pignisticBel)
        {
            sum += bel;
            if (sum >= prob)
            {
                choice = i;
                break;
            }
        }

        auto vector = new int[langSize];
        vector[choice] = 1;
        auto index = vecToIndex(vector);

        double[int] massFunction;
        massFunction[index] = qualities[choice];
        if (qualities[choice] != 1.0)
            massFunction[(2^^langSize)-2] = 1.0 - qualities[choice];

        return massFunction;
    }

    unittest
    {
        import std.math : approxEqual;
        import std.random : Random, unpredictableSeed;
        import std.stdio : writeln;

        writeln("Unit tests:\tprobMassEvidence");

        auto rand = Random(unpredictableSeed);
        auto langSize = 2;
        auto qualities = [0.8, 0.2];
        double[int] beliefs;
        beliefs[0] = 1.0; beliefs[1] = 0.0; beliefs[2] =  0.0;
        auto massFunction = probMassEvidence(qualities, beliefs, rand);
        // It is necessary to use approxEqual here in the element-wise comparison
        // of arrays because you're comparing doubles which can result in them
        // printing the same out, but not actually being comparatively equivalent.
        assert(approxEqual(massFunction[0], 0.8, precision));
        assert(approxEqual(massFunction[2], 0.2, precision));

        beliefs[0] = 0.0; beliefs[1] = 1.0; beliefs[2] =  0.0;
        massFunction = probMassEvidence(qualities, beliefs, rand);
        assert(approxEqual(massFunction[1], 0.2, precision));
        assert(approxEqual(massFunction[2], 0.8, precision));

        beliefs[0] = 0.5; beliefs[1] = 0.5; beliefs[2] =  0.0;
        massFunction = probMassEvidence(qualities, beliefs, rand);
        if (0 in massFunction)
            assert(
                approxEqual(massFunction[0], 0.8, precision) &&
                approxEqual(massFunction[2], 0.2, precision)
            );
        else
            assert(
                approxEqual(massFunction[1], 0.2, precision) &&
                approxEqual(massFunction[2], 0.8, precision)
            );


        writeln("\t\tPASSED.");
    }

    /**
     * Calculates the evidential mass assignment, selecting a quality value
     * at random.
     */
    static auto randMassEvidence(
        const double[] qualities,
        ref from!"std.random".Random rand) pure
    {
        import std.conv : to;
        import std.random : uniform;

        immutable int langSize = qualities.length.to!int;

        auto choice = uniform(0, langSize, rand);
        auto vector = new int[langSize];
        vector[choice] = 1;
        auto index = vecToIndex(vector);

        double[int] massFunction;
        massFunction[index] = qualities[choice];
        if (qualities[choice] != 1.0)
            massFunction[(2^^langSize)-2] = 1.0 - qualities[choice];

        return massFunction;
    }

    unittest
    {
        import std.algorithm.comparison : equal;
        import std.math : approxEqual;
        import std.random : Random, unpredictableSeed;
        import std.stdio : writeln;

        writeln("Unit tests:\trandMassEvidence");

        auto rand = Random(unpredictableSeed);
        auto langSize = 2;
        auto qualities = [0.8, 0.2];
        auto massFunction = randMassEvidence(qualities, rand);
        // It is necessary to use approxEqual here in the element-wise comparison
        // of arrays because you're comparing doubles which can result in them
        // printing the same out, but not actually being comparatively equivalent.
        if (0 in massFunction)
            assert(
                approxEqual(massFunction[0], 0.8, precision) &&
                approxEqual(massFunction[2], 0.2, precision)
            );
        else
            assert(
                approxEqual(massFunction[1], 0.2, precision) &&
                approxEqual(massFunction[2], 0.8, precision)
            );

        writeln("\t\tPASSED.");
    }

    /**
     * Calculates the evidential mass assignment, selecting a quality value
     * at random.
     */
    static auto negMassEvidence(
        const double[] qualities,
        const double alpha,
        ref from!"std.random".Random rand) pure
    {
        import std.algorithm.iteration : filter;
        import std.conv : to;
        import std.math : approxEqual;
        import std.random : randomChoice = choice, uniform01;
        import std.range : array, iota;

        int[] selection = iota(0, qualities.length.to!int).array;
        int[] choices = [-1, -1];
        choices[0] = selection.randomChoice(rand);
        do
        {
            choices[1] = selection.randomChoice(rand);
        }
        while (choices[0] == choices[1]);

        immutable int choice = (qualities[choices[0]] < qualities[choices[1]])
                             ? choices[0]: choices[1];

        double[int] massFunction;
        immutable int[] evidenceSet = iota(0, qualities.length.to!int)
                                    .filter!(a => a != choice)
                                    .array;
        int index = setToIndex(qualities.length.to!int, evidenceSet);

        assert(index != int.init);

        if (approxEqual(alpha, 1.0, precision))
            massFunction[(2^^qualities.length.to!int)-2] = 1.0;
        else if (approxEqual(alpha, 0.0, precision))
        {
            massFunction[index] = 1.0;
        }
        else
        {
            massFunction[index] = 1 - alpha;
            massFunction[(2^^qualities.length.to!int)-2] = alpha;
        }

        return massFunction;
    }

    unittest
    {
        import std.algorithm.comparison : equal;
        import std.algorithm.mutation : remove;
        import std.conv : to;
        import std.math : approxEqual;
        import std.random : Random, unpredictableSeed;
        import std.stdio : writeln;

        writeln("Unit tests:\tnegMassEvidence");

        auto rand = Random(unpredictableSeed);
        auto langSize = 3;
        auto qualities = [0.8, 0.2, 0.1];
        double alpha = 0.0; // Alpha = 0 means "precise" negative info.
        auto massFunction = negMassEvidence(qualities, alpha, rand);
        // It is necessary to use approxEqual here in the element-wise comparison
        // of arrays because you're comparing doubles which can result in them
        // printing the same out, but not actually being comparatively equivalent.
        assert(approxEqual(massFunction[massFunction.keys[0]], 1.0, precision));

        alpha = 1.0;
        massFunction = negMassEvidence(qualities, alpha, rand);
        assert(approxEqual(massFunction[(2^^qualities.length.to!int)-2], 1.0, precision));

        alpha = 0.5;
        massFunction = negMassEvidence(qualities, alpha, rand);
        assert(approxEqual(massFunction[(2^^qualities.length.to!int)-2], 0.5, precision));
        massFunction.remove((2^^qualities.length.to!int)-2);
        assert(approxEqual(massFunction[massFunction.keys[0]], 0.5, precision));

        writeln("\t\tPASSED.");
    }

    /**
     * Calculates the evidential mass assignment, selecting a quality value
     * based on the pignistic belief of the agent.
     */
    static auto probNegMassEvidence(
        const double[] qualities,
        const double[int] beliefs,
        const double alpha,
        ref from!"std.random".Random rand) //pure
    {
        import std.algorithm.iteration : filter;
        import std.algorithm.searching : count, find;
        import std.conv : to;
        import std.math : approxEqual;
        import std.random : randomChoice = choice, uniform01;
        import std.range : array, iota;
        import std.stdio : writeln;

        auto pignisticBel = pignisticDist(qualities.length.to!int, beliefs);

        // If the agent's mass function assigns mass to more than one choice
        int choice;
        if (pignisticBel.count!("a > 0") > 1)
        {
            auto prob = uniform01(rand);
            int[] choices = [-1, -1];
            auto sum = 0.0;
            foreach (int i, ref bel; pignisticBel)
            {
                sum += bel;
                if (sum >= prob)
                {
                    choices[0] = i;
                    break;
                }
            }
            do
            {
                prob = uniform01(rand);
                sum = 0.0;
                foreach (int i, ref bel; pignisticBel)
                {
                    sum += bel;
                    if (sum >= prob)
                    {
                        choices[1] = i;
                        break;
                    }
                }
            }
            while (choices[0] == choices[1]);

            if (qualities[choices[0]].approxEqual(qualities[choices[1]], precision))
            {
                choice = choices.randomChoice;
            }
            else
            {
                choice = (qualities[choices[0]] < qualities[choices[1]])
                            ? choices[0]: choices[1];
            }
        }
        else
        {
            int[] selection = iota(0, qualities.length.to!int).array;
            int[] choices = [-1, -1];
            foreach (i, belief; pignisticBel)
            {
                if (belief.approxEqual(1.0, precision))
                {
                    choices[0] = i.to!int;
                    break;
                }
            }
            do
            {
                choices[1] = selection.randomChoice(rand);
            }
            while (choices[0] == choices[1]);
        }
        double[int] massFunction;
        immutable int[] evidenceSet = iota(0, qualities.length.to!int)
                                    .filter!(a => a != choice)
                                    .array;
        int index = setToIndex(qualities.length.to!int, evidenceSet);

        assert(index != int.init);

        if (approxEqual(alpha, 1.0, precision))
            massFunction[(2^^qualities.length.to!int)-2] = 1.0;
        else if (approxEqual(alpha, 0.0, precision))
        {
            massFunction[index] = 1.0;
        }
        else
        {
            massFunction[index] = 1 - alpha;
            massFunction[(2^^qualities.length.to!int)-2] = alpha;
        }

        return massFunction;
    }

    /**
     * Generates the pignistic (uniform) probability distribution from an
     * agent's mass function.
     */
    static auto pignisticDist(
        const int langSize,
        const double[int] beliefs) pure
    {
        auto pignistic = new double[](langSize);
        pignistic[] = 0;

        foreach (ref key, ref value; beliefs)
        {
            auto set = createSet(langSize, key);
            foreach (ref choice; set)
            {
                pignistic[choice] += value/set.length;
            }
        }

        return pignistic;
    }

    unittest
    {
        import std.math : approxEqual;
        import std.stdio : writeln;

        writeln("Unit tests:\tpignisticDist");

        auto langSize = 2;

        double[int] probDist;
        probDist[0] = 0.2;
        probDist[1] = 0.2;
        probDist[2] = 0.6;
        auto uniformDist = pignisticDist(langSize, probDist);
        assert(approxEqual(uniformDist[0], 0.5, precision));
        assert(approxEqual(uniformDist[1], 0.5, precision));

        probDist[0] = 0.2;
        probDist[1] = 0.1;
        probDist[2] = 0.7;
        uniformDist = pignisticDist(langSize, probDist);
        assert(approxEqual(uniformDist, [0.55,0.45], precision));
        assert(approxEqual(uniformDist, [0.55,0.45], precision));

        writeln("\t\tPASSED.");
    }

    /**
     * Calculate the relative similarity between two sets of propositions.
     * Returns true if the two sets are similar enough, according to some
     * threshold value, and false if they are too dissimilar.
     */
    static auto setSimilarity(
        const int[] set1,
        const int[] set2,
        const double threshold)
    {
        import std.algorithm.setops : multiwayUnion, setIntersection;
        import std.conv : to;
        import std.range.primitives : walkLength;

        immutable auto setIntersec = setIntersection(set1, set2).walkLength;
        immutable auto setUnion = multiwayUnion(cast(int[][])[set1, set2]).walkLength;

        return (setIntersec.to!double / setUnion.to!double) > threshold;
    }

    unittest
    {
        import std.stdio : writeln;

        writeln("Unit tests:\tsetSimilarity");

        auto set1 = [0, 1, 3, 5];
        auto set2 = [1, 2, 4, 5];
        auto threshold = 0.4;
        assert(!setSimilarity(set1, set2, threshold));
        threshold = 0.3;
        assert(setSimilarity(set1, set2, threshold));

        set1 = [0, 1, 2, 3, 4, 5];
        set2 = [0, 1, 2, 3, 4, 5];
        threshold = 1.0;
        assert(!setSimilarity(set1, set2, threshold));

        writeln("\t\tPASSED.");
    }
}

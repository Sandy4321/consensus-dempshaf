module dempshaf.consensus.ds;

import dempshaf.misc.importidiom;
import dempshaf.misc.normalDistribution;

/**
 * DempsterShafer is a class for containing all of the calculation functions
 * specific to the Dempster-Shafer framework of beliefs.
 */
public class DempsterShafer
{
    /**
     * Set the precision of the approxEqual checks.
     */
    static immutable auto precision = 1e-4;
    /**
      * Set of static variables.
      */
    static int[] staticVector;
    static int[] staticSet;
    static double[] staticPignistic;

    static bool getNoise = true;
    static real[2] noisePair;

    /**
     * Generate the binary vector based on the set provided,
     * and the language size.
     */
    static auto setToVec(const int[] set)
    {
        staticVector[] = 0;

        foreach (ref element; set) staticVector[element] = 1;

        return staticVector.dup;
    }

    /**
     * Generate the binary vector based on its index in the powerset,
     * and then return the vector.
     */
    static auto indexToVec(const int index)
    {
        staticVector[] = 0;
        int correctedIndex = index + 1;

        foreach (ref element; staticVector)
        {
            element = (correctedIndex % 2 == 0) ? 0 : 1;
            correctedIndex /= 2;
        }

        return staticVector.dup;
    }

    /**
     * Generate the set based on its index, first calling indexToVec
     * and then returning the set.
     */
    static auto createSet(const int index)
    {
        import std.algorithm.iteration : sum;
        import std.conv : to;
        import std.range : array;

        auto vector = indexToVec(index);
        staticSet[] = 0;
        auto fillIndex = 0;
        foreach (i, ref value; vector)
        {
            if (value == 1) staticSet[fillIndex++] = i.to!int;
        }
        return staticSet[0 .. vector.sum].dup;
    }

    /**
     * Generate the set based on its binary vector, and then return
     * the set.
     */
    static auto createSet(const int[] vector)
    {
        import std.algorithm.iteration : sum;
        import std.conv : to;

        staticSet[] = 0;
        auto fillIndex = 0;
        foreach (i, ref value; vector)
            if (value == 1) staticSet[fillIndex++] = i.to!int;

        return staticSet[0 .. vector.sum].dup;
    }

    /**
     * Calculate the index of the set in the powerset.
     */
    static auto setToIndex(const int[] set)
    {
        auto vector = setToVec(set);
        int index;
        foreach (i, ref value; vector) index += value * 2^^i;

        return index - 1;
    }

    /**
     * Calculate the index of the vector in the powerset.
     */
    static auto vecToIndex(const int[] vector)
    {
        int index;
        foreach (i, ref value; vector) index += value * 2^^i;

        return index - 1;
    }

    /**
     * The Hellinger distance for two discrete probability distributions,
     * applied to the pignistic distributions of each agent's beliefs.
     */
    static auto distance(
        const int langSize,
        const double[int] beliefs1,
        const double[int] beliefs2)
    {
        import std.math : sqrt;

        auto pignisticBel1 = pignisticDist(beliefs1);
        auto pignisticBel2 = pignisticDist(beliefs2);

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
    static auto entropy(const double[int] beliefs)
    {
        import std.math : approxEqual, log2;

        double entropy = 0.0;

        foreach (index, belief; beliefs)
        {
            if (approxEqual(belief, 0.0)) continue;
            entropy -= belief * log2(belief/((2^^createSet(index).length)-1));
        }

        return entropy;
    }

    /**
     * Inconsistency measure between two beliefs.
     */
    static auto inconsistency(
        const double[int] beliefs1,
        const double[int] beliefs2)
    {
        import std.algorithm : setIntersection;
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

                auto set1 = createSet(i);
                auto set2 = createSet(j);
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
     * propositional variables given as langSize.
     */
    static auto generatePowerset(const int langSize)
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
                    if (set.length > 0 && set.length == level && set[0] == prop)
                        powerset ~= set;

        return powerset;
    }

    /**
     * Generate the indices for both belief and plausibily, so that
     * you can calculate these later on without having to generate
     * the vectors every time in order to retrieve the indices.
     */
    static auto belAndPlIndices(const int langSize, const int choice)
    {
        import std.algorithm.iteration : sum;

        auto masterVector = new int[langSize - 1];
        auto vector = new int[langSize];
        vector[choice] = 1;
        auto belIndex = vecToIndex(vector);
        int[] plIndices;

        while (vector.sum < langSize)
        {
            if (choice != 0) vector[0 .. choice] = masterVector[0 .. choice];
            if (choice != langSize - 1)
                vector[choice + 1 .. $] = masterVector[choice .. $];
            plIndices ~= vecToIndex(vector);

            masterVector[0]++;
            foreach (i, ref prop; masterVector[0 .. $-1])
            {
                if (prop > 1)
                {
                    prop = 0;
                    masterVector[i+1]++;
                }
            }
        }
        return [[belIndex], plIndices];
    }

    /**
     * Calculates the evidential mass assignment based on the agent's pignistic
     * distribution. This prioritises the most dominant choice to receive feedback
     * (payoff so that more accurate beliefs are reinforced, and inaccurate beliefs
     * are punished.
     */
    static auto probMassEvidence(
        const double[] qualities,
        const double noiseVariance,
        const double[int] beliefs,
        ref from!"std.random".Random rand)
    {
        import std.conv : to;
        import std.random : uniform;

        import std.stdio : writeln;

        auto pignisticBel = pignisticDist(beliefs);
        immutable auto prob = uniform!"[]"(0.0, 1.0, rand);
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

        staticVector[] = 0;
        staticVector[choice] = 1;
        auto index = vecToIndex(staticVector);

        double[int] massFunction;
        auto quality = qualities[choice].to!double;
        auto noise = 0.0;

        if (noiseVariance > 0.0)
        {
            do
            {
                if (getNoise)
                {
                    noisePair = normalDistribution(rand);
                    noise = noisePair[0];
                    getNoise = false;
                }
                else
                {
                    noise = noisePair[1];
                    getNoise = true;
                }

                noise *= noiseVariance;

            } while (quality + noise < 0 || quality + noise > 1);
        }
        quality += noise;
        // Bound the noisy quality value to form a truncated noise profile
        if (quality > 1)      quality = 1.0;
        else if (quality < 0) quality = 0.0;

        massFunction[index] = quality;

        if (quality != 1.0)
            massFunction[(2^^qualities.length.to!int)-2] = 1.0 - quality;

        return massFunction;
    }

    /**
     * Calculates the evidential mass assignment, selecting a quality value
     * at random.
     */
    static auto randMassEvidence(
        const double[] qualities,
        ref from!"std.random".Random rand)
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

    /**
     * Uses negative updating to provide evidence of the "worst" choice, selecting
     * two choices at random, A and B, for comparison,  then updating on, e.g. ¬A,
     * when A is the worst choice out of the two.
     */
    static auto negMassEvidence(
        const double[] qualities,
        const double alpha,
        ref from!"std.random".Random rand)
    {
        import std.algorithm.iteration : filter;
        import std.conv : to;
        import std.math : approxEqual;
        import std.random : randomChoice = choice;
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
        int index = setToIndex(evidenceSet);

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
     * The same as negative updating, but the selection of the pair is weighted
     * according to the agent's pignistic distribution. Possibly useless.
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
        import std.random : randomChoice = choice, uniform;
        import std.range : array, iota;
        import std.stdio : writeln;

        auto pignisticBel = pignisticDist(beliefs);

        // If the agent's mass function assigns mass to more than one choice
        int choice;
        if (pignisticBel.count!("a > 0") > 1)
        {
            auto prob = uniform!"[]"(0.0, 1.0, rand);
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
                prob = uniform!"[]"(0.0, 1.0, rand);
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
                choice = choices.randomChoice(rand);
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
        int index = setToIndex(evidenceSet);

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
    static auto pignisticDist(const double[int] beliefs)
    {
        staticPignistic[] = 0;

        foreach (ref key, ref value; beliefs)
        {
            auto set = createSet(key);
            foreach (ref choice; set)
            {
                staticPignistic[choice] += value/set.length;
            }
        }

        return staticPignistic.dup;
    }

    /**
     * Calculate the relative similarity between two sets of propositions.
     * Returns true if the two sets are similar enough, according to some
     * threshold value, and false if they are too dissimilar.
     */
    static auto setSimilarity(
        const int[] set1,
        const int[] set2)
    {
        import std.algorithm.setops : multiwayUnion, setIntersection;
        import std.conv : to;
        import std.range.primitives : walkLength;

        immutable auto setIntersec = setIntersection(set1, set2).walkLength;
        immutable auto setUnion = multiwayUnion(cast(int[][])[set1, set2]).walkLength;

        return setIntersec.to!double / setUnion.to!double;
    }
}

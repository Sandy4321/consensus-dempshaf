module dempshaf.consensus.ds;

import dempshaf.importidiom;

/**
 * DempsterShafer is a class for containing all of the calculation functions
 * specific to the DempsterShafer model of beliefs.
 */
public class DempsterShafer
{
    /**
     * Generate the payoff model.
     */
    static auto ref generatePayoff(
        ref in int[] choices,
        ref in int l) pure
    {
        import std.algorithm.iteration : sum;
        import std.conv : to;

        auto payoff = new double[l];
        auto choiceSum = choices[0 .. l].sum;

        foreach (ref i; 0 .. l)
            payoff[i] = choices[i] / to!double(choiceSum);

        return payoff;
    }

    /**
     * Calculate the payoff associated with a given belief.
     */
    static auto ref calculatePayoff(
        ref in double[] payoffs,
        ref in int[][] powerSet,
        ref in double[] beliefs) pure
    {
        import std.algorithm.searching : maxElement;
        import std.conv : to;

        double payoff = 0.0;
        auto maximalPayoff = payoffs.maxElement;
        immutable int l = payoffs.length.to!int;
        auto pignistic = pignisticDist(
            powerSet,
            l,
            beliefs
        );

        foreach (i, ref prob; pignistic)
        {
           payoff += prob * payoffs[i];
        }

        return payoff/maximalPayoff;
    }

    /**
     * Calculate the minimum payoff value present in the population.
     */
    static auto ref minPayoff(ref in double[] payoffMap) pure
    {
        import std.algorithm.searching : minElement;

        return payoffMap.minElement;
    }

    /**
     * Calculate the maximum payoff value present in the population.
     */
    static auto ref maxPayoff(ref in double[] payoffMap) pure
    {
        import std.algorithm.searching : maxElement;

        return payoffMap.maxElement;
    }

    /**
     * Calculate the total payoff of the population.
     */
    static auto ref totalPayoff(
        ref in double[] payoffMap,
        in double minPayoff) pure
    {
        import std.algorithm.iteration : map, sum;

        return payoffMap.map!(x => x - minPayoff).sum;
    }

    /**
     * The selection algorithm for selecting two pairs of agents based on the
     * roulette-wheel selection method seen in genetic algorithms.
     */
    static auto ref rouletteSelection(
        ref from!"std.random".Random rand,
        ref double[] payoffMap,
        ref int l,
        ref int amt)
    {
        import std.random : uniform;

        auto selection = new int[amt];
        int select;
        immutable auto n = payoffMap.length;
        double payoff, choice;

        auto totalPayoff = DempsterShafer.totalPayoff(payoffMap, 0);

        while(select < amt)
        {
            choice = uniform(0.0, 1.0, rand);
            payoff = 0.0;
            foreach (int agent, ref value; payoffMap)
            {
                //payoff += (value + l) / (totalPayoff + (n * l));
                payoff += (value + (l + 1)) / (totalPayoff + (n * (l + 1)));
                if (payoff < choice)
                {
                    continue;
                }

                selection[select++] = agent;
                if (select > 0 && selection[0] == selection[1])
                    select--;
                break;
            }
        }
        return selection;
    }

    /**
     * The Hellinger distance for two discrete probability distributions,
     * applied to the pignistic distributions of each agent's beliefs.
     */
    static auto ref distance(
        ref in int[][] powerSet,
        ref in int l,
        ref in double[] beliefs1,
        ref in double[] beliefs2) pure
    {
        import std.math : sqrt;

        auto pignisticBel1 = pignisticDist(powerSet, l, beliefs1);
        auto pignisticBel2 = pignisticDist(powerSet, l, beliefs2);

        double distance = 0.0;
        double sum = 0.0;
        foreach (i; 0 .. l)
            sum += (sqrt(pignisticBel1[i]) - sqrt(pignisticBel2[i])) ^^2;

        distance += (1.0 / sqrt(2.0)) * sqrt(sum);

        return distance;
    }

    /**
     * Calculates the entropy of an agent's beliefs: a measure of uncertainty.
     */
    static auto ref entropy(
        ref in int[][] powerSet,
        ref in int l,
        ref in double[] beliefs) pure
    {
        import std.math : approxEqual, log2;

        auto pignisticBel = pignisticDist(powerSet, l, beliefs);

        double entropy = 0.0;

        foreach (belief; pignisticBel)
        {
            if (approxEqual(belief, 0.0))
                continue;
            entropy -= belief * log2(belief);
        }

        return entropy;
    }

    /**
     * Inconsistency measure between two beliefs.
     */
    static auto ref inconsistency(
        ref in int[][] powerSet,
        ref in int l,
        ref in double[] beliefs1,
        ref in double[] beliefs2) pure
    {
        auto pignisticBel1 = pignisticDist(powerSet, l, beliefs1);
        auto pignisticBel2 = pignisticDist(powerSet, l, beliefs2);

        double inconsistency = 0.0;

        foreach (i; 0 .. l)
        {
            inconsistency += (pignisticBel1[i] * (1.0 - pignisticBel2[i]));
        }

        return (inconsistency / l);
    }

    /**
     * Generates the power set (frame of discernment) from the number of
     * propositional variables given as l.
     */
    static auto ref generatePowerSet(ref in int l) pure
    {
        import std.algorithm.sorting : sort;

        auto powerSet = new int[][]((2^^l));
        auto props = new int[l];

        foreach (ref set; powerSet)
        {
            foreach (int i, ref prop; props)
            {
                if (prop == 1)
                {
                    set ~= i;
                }
            }

            props[0]++;
            foreach (i, ref prop; props[0 .. $-1])
            {
                if (prop > 1)
                {
                    prop = 0;
                    props[i+1]++;
                }
            }
        }

        auto tempSet = powerSet.sort();
        powerSet = null;
        foreach (ref level; 0 .. l + 1)
            foreach (ref prop; 0 .. l)
                foreach (ref set; tempSet)
                    if (set.length > 0)
                        if (set.length == level && set[0] == prop)
                            powerSet ~= set;

        return powerSet;
    }

    unittest
    {
        import std.stdio : writeln;

        writeln("Unit tests:\tgeneratePowerSet");

        auto l = 1;
        auto powerSet = generatePowerSet(l);
        assert(powerSet == [[0]]);

        l = 2;
        powerSet = generatePowerSet(l);
        assert(powerSet == [[0], [1], [0, 1]]);

        l = 3;
        powerSet = generatePowerSet(l);
        assert(powerSet == [[0], [1], [2], [0, 1], [0, 2], [1, 2], [0, 1, 2]]);

        writeln("\t\tPASSED.");
    }

    /**
     * Calculates the evidential mass assignment based on the agent's current
     * beliefs. This prioritises the most dominant choice to receive feedback (payoff
     * so that more accurate beliefs are reinforced, and inaccurate beliefs are
     * punished.
     */
    static auto ref massEvidence(
        ref in int[][] powerSet,
        ref in int l,
        ref in double[] qualities,
        ref in double[] beliefs,
        ref from!"std.random".Random rand) pure
    {
        import std.random : uniform01;

        auto pignisticBel = pignisticDist(powerSet, l, beliefs);
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

        auto massFunction = new double[](powerSet.length);
        massFunction[] = 0.0;

        massFunction[choice] = qualities[choice];
        massFunction[$-1] = 1.0 - qualities[choice];

        return massFunction;
    }

    unittest
    {
        import std.algorithm.comparison : equal;
        import std.math : approxEqual;
        import std.random : Random, unpredictableSeed;
        import std.stdio : writeln;

        writeln("Unit tests:\tmassEvidence");

        auto rand = Random(unpredictableSeed);

        auto l = 2;
        auto powerSet = generatePowerSet(l);
        assert(powerSet == [[0], [1], [0, 1]]);

        auto qualities = [0.8, 0.2];
        auto beliefs = [1.0, 0.0, 0.0];
        auto massFunction = massEvidence(powerSet, l, qualities, beliefs, rand);
        // It is necessary to use approxEqual here in the element-wise comparison
        // of arrays because you're comparing doubles which can result in them
        // printing the same out, but not actually being comparatively equivalent.
        assert(equal!approxEqual(massFunction, [0.8, 0, 0.2]));

        beliefs = [0.0, 1.0, 0.0];
        massFunction = massEvidence(powerSet, l, qualities, beliefs, rand);
        assert(equal!approxEqual(massFunction, [0, 0.2, 0.8]));

        beliefs = [0.5, 0.5, 0.0];
        massFunction = massEvidence(powerSet, l, qualities, beliefs, rand);
        assert(
            equal!approxEqual(massFunction, [0.8, 0, 0.2]) ||
            equal!approxEqual(massFunction, [0, 0.2, 0.8])
        );


        writeln("\t\tPASSED.");
    }

    /**
     * Calculates the evidential mass assignment, selecting a quality value
     * at random.
     */
    static auto ref randMassEvidence(
        ref in int[][] powerSet,
        ref in double[] qualities,
        ref from!"std.random".Random rand) pure
    {
        import std.random : uniform;

        auto choice = uniform(0, qualities.length, rand);
        auto massFunction = new double[](powerSet.length);
        massFunction[] = 0.0;

        massFunction[choice] = qualities[choice];
        massFunction[$-1] = 1.0 - qualities[choice];

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

        auto l = 2;
        auto powerSet = generatePowerSet(l);
        assert(powerSet == [[0], [1], [0, 1]]);

        auto qualities = [0.8, 0.2];
        auto massFunction = randMassEvidence(powerSet, qualities, rand);
        // It is necessary to use approxEqual here in the element-wise comparison
        // of arrays because you're comparing doubles which can result in them
        // printing the same out, but not actually being comparatively equivalent.
        assert(
            equal!approxEqual(massFunction, [0.8, 0, 0.2]) ||
            equal!approxEqual(massFunction, [0, 0.2, 0.8])
        );

        writeln("\t\tPASSED.");
    }

    /**
     * Generates the pignistic (uniform) probability distribution from an
     * agent's mass function.
     */
    static auto ref pignisticDist(
        ref in int[][] powerSet,
        ref in int l,
        ref in double[] beliefs) pure
    {
        auto pignistic = new double[](l);
        pignistic[] = 0;

        foreach (i, ref set; powerSet)
        {
            foreach (ref choice; set)
            {
                pignistic[choice] += beliefs[i]/set.length;
            }
        }

        return pignistic;
    }

    unittest
    {
        import std.algorithm.comparison : equal;
        import std.math : approxEqual;
        import std.stdio : writeln;

        writeln("Unit tests:\tpignisticDist");

        auto l = 2;
        auto powerSet = generatePowerSet(l);

        double[] probDist = [0.2, 0.2, 0.6];
        auto uniformDist = pignisticDist(powerSet, l, probDist);
        assert(equal!approxEqual(uniformDist, [0.5,0.5]));

        probDist = [0.2, 0.1, 0.7];
        uniformDist = pignisticDist(powerSet, l, probDist);
        assert(equal!approxEqual(uniformDist, [0.55,0.45]));

        writeln("\t\tPASSED.");
    }
}

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
    static double[] generatePayoff(
        ref in int[] choices,
        ref in int l) pure
    {
        import std.algorithm : sum;
        import std.conv      : to;

        auto payoff = new double[l];
        auto choiceSum = choices[0 .. l].sum;

        foreach (ref i; 0 .. l)
            payoff[i] = choices[i] / to!double(choiceSum);

        return payoff;
    }

    /**
     * Calculate the payoff associated with a given belief.
     */
    static double calculatePayoff(
        ref in double[] payoffs,
        ref in int[][] powerSet,
        ref in double[] beliefs) pure
    {
        import std.algorithm : maxElement;

        double payoff = 0.0;
        auto maximalPayoff = payoffs.maxElement;
        auto pignistic = new double[](payoffs.length);
        pignistic[] = 0;

        foreach (i, ref set; powerSet)
        {
            foreach (ref choice; set)
            {
                pignistic[choice] += beliefs[i]/set.length;
            }
        }

        foreach (i, ref prob; pignistic)
        {
           payoff += prob * payoffs[i];
        }

        return payoff/maximalPayoff;
    }

    /**
     * Calculate the minimum payoff value present in the population.
     */
    static double minPayoff(ref in double[] payoffMap) pure
    {
        import std.algorithm.searching : minElement;

        return payoffMap.minElement;
    }

    /**
     * Calculate the maximum payoff value present in the population.
     */
    static double maxPayoff(ref in double[] payoffMap) pure
    {
        import std.algorithm.searching : maxElement;

        return payoffMap.maxElement;
    }

    /**
     * Calculate the total payoff of the population.
     */
    static double totalPayoff(
        ref in double[] payoffMap,
        in double minPayoff) pure
    {
        import std.algorithm.iteration;

        return payoffMap.map!(x => x - minPayoff).sum;
    }

    /**
     * The selection algorithm for selecting two pairs of agents based on the
     * roulette-wheel selection method seen in genetic algorithms.
     */
    static int[] rouletteSelection(
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
     * Calculates the Hellinger distance between two probability distributions.
     */
    /*static double distance(
        in double[2][] beliefs1,
        in double[2][] beliefs2,
        ref in int l) pure
    {
        import std.math : sqrt;

        double distance = 0.0;
        foreach (i; 0 .. l)
        {
            double sum = 0.0;

            // True
            sum += (sqrt(beliefs1[i][0]) - sqrt(beliefs2[i][0])) ^^2;

            // Borderline
            auto one = (beliefs1[i][1] - beliefs1[i][0] < 0) ?
                0 : beliefs1[i][1] - beliefs1[i][0];
            auto two = (beliefs2[i][1] - beliefs2[i][0] < 0) ?
                0 : beliefs2[i][1] - beliefs2[i][0];
            sum += (sqrt(one) - sqrt(two)) ^^2;

            // False
            one = (1.0 - beliefs1[i][1]) < 0 ? 0 : 1.0 - beliefs1[i][1];
            two = (1.0 - beliefs2[i][1]) < 0 ? 0 : 1.0 - beliefs2[i][1];
            sum += (sqrt(one) - sqrt(two)) ^^2;

            distance += (1.0 / sqrt(2.0)) * sqrt(sum);
        }
        return distance / cast(double) l;   // Normalise distance over all propositions
    }*/

    /**
     * The Hellinger distance for two discrete probability distributions,
     * applied to the pignistic distributions of each agent's beliefs.
     */
    static double distance(
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
    static double entropy(
        ref in double[] beliefs,
        ref in int l) pure
    {
        import std.math : log, log2;

        double entropy = 1.0;
        /*double one, two, logOne, logTwo, logThree = 0.0;

        foreach (belief; beliefs)
        {
            one = (belief[1] - belief[0]) < 0 ? 0 : (belief[1] - belief[0]);
            two = (1.0 - belief[1]) < 0 ? 0 : 1.0 - belief[1];

            logOne = (belief[0] == 0 ? 0 : log2(belief[0]));
            logTwo = (one == 0 ? 0 : log2(one));
            logThree = (two == 0 ? 0 : log2(two));

            entropy -= (belief[0] * logOne)
                    + (one * logTwo)
                    + (two * logThree);
        }*/

        // TODO: IMPLEMENT ENTROPY MEASURE

        return entropy / l;
    }

    /**
     * Inconsistency measure between two beliefs.
     */
    static double inconsistency(
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
        import std.algorithm : sort;

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
        import std.math   : approxEqual;
        import std.random : Random;
        import std.stdio  : writeln;

        writeln("Unit tests:\tmassEvidence");

        auto rand = Random();

        auto l = 2;
        auto powerSet = generatePowerSet(l);
        assert(powerSet == [[0], [1], [0, 1]]);

        auto qualities = [0.8, 0.2];
        auto massFunction = massEvidence(powerSet, qualities, rand);
        auto temp = [0.8, 0, 0.2];
        // It is necessary to use approxEqual here in the element-wise comparison
        // of arrays because you're comparing doubles which can result in them
        // printing the same out, but not actually being comparatively equivalent.
        assert(equal!approxEqual(massFunction, temp));

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
        import std.math   : approxEqual;
        import std.random : Random;
        import std.stdio  : writeln;

        writeln("Unit tests:\trandMassEvidence");

        auto rand = Random();

        auto l = 2;
        auto powerSet = generatePowerSet(l);
        assert(powerSet == [[0], [1], [0, 1]]);

        auto qualities = [0.8, 0.2];
        auto massFunction = randMassEvidence(powerSet, qualities, rand);
        auto temp = [0.8, 0, 0.2];
        // It is necessary to use approxEqual here in the element-wise comparison
        // of arrays because you're comparing doubles which can result in them
        // printing the same out, but not actually being comparatively equivalent.
        assert(equal!approxEqual(massFunction, temp));

        writeln("\t\tPASSED.");
    }

    /**
     * Calculates the mass assignment of an agent's belief and plausibility measures.
     */
    static auto ref massFunction(
        ref in double[][] powerSet,
        ref in double[] beliefs) pure
    {
        return;
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

    }

    /**
     * Calculates the belief assignment from an agent's mass function.
     */
    static auto ref beliefAssignment(
        ref in double[][] powerSet,
        ref in double[][] masses) pure
    {
        return;
    }
}

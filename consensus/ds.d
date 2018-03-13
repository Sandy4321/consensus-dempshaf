module dempshaf.consensus.ds;

import dempshaf.importidiom;

/**
 * DempsterShafer is a class for containing all of the calculation functions
 * specific to the DempsterShafer model of beliefs.
 */
public class DempsterShafer
{
    /**
     * Keep track of the total maximal payoff. Useful for calculating convergence
     * in the payoff model.
     */
    static auto maximalPayoff = 0.0;

    /**
     * Generate the payoff model.
     */
    static double[] generatePayoff(
        ref in int[] choices,
        ref in int l) pure
    {
        import std.algorithm : sum;
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
    static double calculatePayoff(
        ref in double[] payoffs,
        ref in int[][] powerSet,
        ref in double[] beliefs) pure
    {
        double payoff = 0.0;
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

        return payoff;
    }

    /**
     * Calculate the minimum payoff value present in the population.
     */
    static double minPayoff(ref in double[] payoffMap) pure
    {
        auto payoff = double.infinity;
        foreach(ref value; payoffMap)
        {
            if (value < payoff)
                payoff = value;
        }

        return payoff;
    }

    /**
     * Calculate the maximum payoff value present in the population.
     */
    static double maxPayoff(ref in double[] payoffMap) pure
    {
        auto payoff = double.infinity * -1;
        foreach(ref value; payoffMap)
        {
            if (value > payoff)
                payoff = value;
        }

        return payoff;
    }

    /**
     * Calculate the total payoff of the population
     */
    static double totalPayoff(
        ref in double[] payoffMap,
        in double minPayoff) pure
    {
        double payoff = 0.0;
        foreach(ref value; payoffMap)
        {
            payoff += value - minPayoff;
        }

        return payoff;
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

        //auto minPayoff = DempsterShafer.minPayoff(payoffMap);
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
     * Takes opinions and probability distributions for both agents and calculates
     * the distance between both agents on a world-belief basis.
     */
    /*static double valuationDistance(
        in int[][][] opinions1, in double[2][] p1,
        in int[][][] opinions2, in double[2][] p2) pure
    {
        import std.math : sqrt;

        auto agent1 = opinions1;
        auto agent2 = opinions2;
        auto prob1 = p1;
        auto prob2 = p2;

        double distance = 0.0;
        auto counter = new int[agent2.length];

        foreach (i, ref opinion1; agent1)
        {
            bool found;
            foreach(int j, ref opinion2; agent2)
            {
                if (opinion1 == opinion2)
                {
                    distance += ((1.0 / sqrt(2.0)) * sqrt((sqrt(prob1[i]) - sqrt(prob2[j])) ^^2));
                    counter[j]++;
                    found = true;
                    break;
                }
            }
            if (!found)
            {
                distance += ((1.0 / sqrt(2.0)) * sqrt(prob1[i]));
            }
        }
        foreach (int i, ref j; counter)
        {
            if (!j) distance += ((1.0 / sqrt(2.0)) * sqrt((0.0 - sqrt(prob2[i])) ^^2));
        }
        return distance;
    }*/

    /**
     * Need to find a good distance measure for Dempster-Shafer Theory..
     * This distance measure is a placeholder for now.
     */
    static double distance(
        ref in double[] beliefs1,
        ref in double[] beliefs2,
        ref in int l) pure
    {
        import std.math : sqrt;

        double distance = 1.0;

        // TODO: IMPLEMENT DISTANCE MEASURE

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
        ref in double[] beliefs1,
        ref in double[] beliefs2,
        ref in int l) pure
    {
        double inconsistency = 0.0;
        foreach (prop; 0 .. l)
        {
            //inconsistency += (beliefs1[prop][0] * (1.0 - beliefs2[prop][1])) +
            //    ((1.0 - beliefs1[prop][1]) * beliefs2[prop][0]);
            inconsistency += 1.0;
        }

        return (inconsistency / l);
    }

    /**
     * Generates the power set (frame of discernment) from the number of
     * propositional variables given as l.
     */
    static auto generatePowerSet(ref in int l) pure
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
     * Calculates the mass assignment of an agent's belief and plausibility measures.
     */
    static auto massEvidence(
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
        import std.random : Random;
        import std.stdio : writeln;

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
     * Calculates the mass assignment of an agent's belief and plausibility measures.
     */
    static auto massFunction(
        ref in double[][] powerSet,
        ref in double[] beliefs) pure
    {
        return;
    }

    /**
     * Calculates the belief assignment from an agent's mass function.
     */
    static auto beliefAssignment(
        ref in double[][] powerSet,
        ref in double[][] masses) pure
    {
        return;
    }
}

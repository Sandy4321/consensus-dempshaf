module dempshaf.consensus.ds;

import dempshaf.importidiom;

public class DempsterShafer
{
    static auto maximalPayoff = 0.0;

    static double[] generatePayoff(
        ref in int[] choices,
        ref in int l) pure
    {
        import std.algorithm, std.conv;

        auto payoff = new double[l];
        auto choiceSum = choices[0 .. l].sum;

        foreach (ref i; 0 .. l)
            payoff[i] = choices[i] / to!double(choiceSum);

        return payoff;
    }

    static double calculatePayoff(
        ref in double[] payoffs,
        ref in double[] beliefs) pure
    {
        double payoff = 0.0;
        foreach (i, ref belief; beliefs)
        {
            payoff += belief[0] * payoffs[i];
        }

        return payoff;
    }

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

    static int[] rouletteSelection(
        ref from!"std.random".Random rand,
        ref double[] payoffMap,
        ref int l,
        ref int amt)
    {
        import std.random;

        auto selection = new int[amt];
        int select;
        auto n = payoffMap.length;
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

    /*
     * distance: calculates the Hellinger distance between two probability
     * distributions.
     */
    static double distance(
        in double[] worldBeliefs1,
        in double[] worldBeliefs2,
        ref in int l) pure
    {
        import std.math;

        double distance = 0.0;
        foreach (i; 0 .. l)
        {
            double sum = 0.0;

            // True
            sum += (sqrt(worldBeliefs1[i][0]) - sqrt(worldBeliefs2[i][0])) ^^2;

            // Borderline
            auto one = (worldBeliefs1[i][1] - worldBeliefs1[i][0] < 0) ?
                0 : worldBeliefs1[i][1] - worldBeliefs1[i][0];
            auto two = (worldBeliefs2[i][1] - worldBeliefs2[i][0] < 0) ?
                0 : worldBeliefs2[i][1] - worldBeliefs2[i][0];
            sum += (sqrt(one) - sqrt(two)) ^^2;

            // False
            one = (1.0 - worldBeliefs1[i][1]) < 0 ? 0 : 1.0 - worldBeliefs1[i][1];
            two = (1.0 - worldBeliefs2[i][1]) < 0 ? 0 : 1.0 - worldBeliefs2[i][1];
            sum += (sqrt(one) - sqrt(two)) ^^2;

            distance += (1.0 / sqrt(2.0)) * sqrt(sum);
        }
        return distance / cast(double) l;   // Normalise distance over all propositions
    }

    /*
     * valuationDistance: takes opinions and probability dist.s for both agents
     * and calculates the distance between both agents on a world-belief basis.
     */
    static double valuationDistance(
        in int[][][] opinions1, in double[] p1,
        in int[][][] opinions2, in double[] p2) pure
    {
        import std.math;

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
    }

    /*
     * generatePowerSet: generates the power set (frame of discernment) from
     * the number of propositional variables given as l.
     */
    static ref auto generatePowerSet(ref in int l) pure
    {
        import std.algorithm : sort;

        auto powerSet = new double[][]((2^^l));
        auto props = new int[l];
        props[] = 0;

        foreach (ref set; powerSet)
        {
            foreach (i, ref prop; props)
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
                {
                    if (set.length > 0)
                        if (set.length == level && set[0] == prop)
                        {
                            powerSet ~= set;
                        }
                }

        return powerSet;
    }

    unittest
    {
        import std.stdio : writeln;

        writeln("Unit tests:\tgeneratePowerSet(int l)");

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

    /*
     * massAssignment: calculates the mass assignment of an agent's belief and
     * plausibility measures.
     */
    static auto massAssignment(
        ref in double[][] powerSet,
        in double[] beliefs) pure
    {
        return;
    }

    /*
     * beliefAssignment: calculates the belief assignment from an agent's
     * mass function.
     */
    static auto beliefAssignment(
        ref in double[][] powerSet,
        in double[][] masses) pure
    {
        return;
    }
}

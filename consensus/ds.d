module dempshaf.consensus.ds;

import dempshaf.consensus.feedback;

import std.math;

public class DempsterShafer : Feedback
{
    public
    {
        static auto maximalPayoff = 0.0;

        static double[][] generatePayoff(
            ref Random rand,
            int l)
        {
            auto payoff = new double[][](l, 3);
            auto value = 0.0;
            for (int i; i < l; i++)
            {
                // Generate new payoff value for the proposition
                value = 1.0; //uniform(-1.0, 1.0, rand);
                if (uniform(0, 2, rand))
                {
                    value *= -1;
                }
                // Payoff value: true
                payoff[i][0] = value;
                // Payoff value: borderline [default: 0.0]
                payoff[i][1] = 0.0;
                // Payoff value: false
                payoff[i][2] = value * -1;

                // Calculate maximal payoff achievable by summing all positive
                // payoff values generated.
                maximalPayoff += (value > 0) ? value : (value * -1);
            }

            return payoff;
        }

        static double calculatePayoff(
            in double[][] payoffs,
            in double[2][] beliefs)
        {
            double payoff = 0.0;
            foreach (i, ref belief; beliefs)
            {
                payoff += belief[0] * payoffs[i][0];
                payoff += (belief[1] - belief[0]) * payoffs[i][1];
                payoff += (1.0 - belief[1]) * payoffs[i][2];
            }

            return payoff;
        }

        static double minPayoff(in double[] payoffMap)
        {
            auto payoff = double.infinity;
            foreach(ref value; payoffMap)
            {
                if (value < payoff)
                    payoff = value;
            }

            return payoff;
        }

        static double maxPayoff(in double[] payoffMap)
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
            in double[] payoffMap,
            in double minPayoff)
        {
            double payoff = 0.0;
            foreach(ref value; payoffMap)
            {
                payoff += value - minPayoff;
            }

            return payoff;
        }

        static int[] rouletteSelection(
            ref Random rand,
            double[] payoffMap,
            int l,
            int amt)
        {
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
            in double[2][] worldBeliefs1,
            in double[2][] worldBeliefs2,
            in int l)
        {
            double distance = 0.0;
            foreach (i; 0 .. l)
            {
                double sum = 0.0;

                // True
                sum += (sqrt(worldBeliefs1[i][0]) -
                    sqrt(worldBeliefs2[i][0])) ^^2;

                // Borderline
                auto one = (worldBeliefs1[i][1] - worldBeliefs1[i][0] < 0) ? 0 : worldBeliefs1[i][1] - worldBeliefs1[i][0];
                auto two = (worldBeliefs2[i][1] - worldBeliefs2[i][0] < 0) ? 0 : worldBeliefs2[i][1] - worldBeliefs2[i][0];
                sum += (sqrt(one) -
                    sqrt(two)) ^^2;

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
            in int[][][] opinions2, in double[] p2)
        {
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
    }
}

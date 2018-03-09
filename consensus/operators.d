module dempshaf.consensus.operators;

/**
 * The Operators class provides operators for dealing with agents' beliefs.
 */
public final class Operators
{
    /**
     * Consensus operator for uncertain three-valued beliefs.
     */
    static auto beliefConsensus(
        ref in double[2][] beliefs1,
        ref in double[2][] beliefs2) pure
    {
        auto beliefs = new double[2][beliefs1.length];
        auto w1 = beliefs1;
        auto w2 = beliefs2;

        foreach (i, ref belief; beliefs)
        {
            belief = [
                (w1[i][0] * w2[i][1]) +
                (w1[i][1] * w2[i][0]) -
                (w1[i][0] * w2[i][0]),
                (w1[i][0] + w2[i][0]) +
                (w1[i][1] * w2[i][1]) -
                (w1[i][1] * w2[i][0]) -
                (w1[i][0] * w2[i][1])
            ];
        }

        return beliefs;
    }

    /**
     * Consensus operator for uncertain three-valued beliefs.
     */

    static auto ref ruleOfCombination(
        ref in double[][] powerSet,
        in double[] beliefs1,
        in double[] beliefs2) pure
    {
        import std.algorithm.searching;
        import std.algorithm.sorting;
        import std.algorithm.setops;
        import std.math : approxEqual;
        import std.conv;

        auto beliefs = new double[powerSet.length];

        foreach (i, ref bel1; beliefs1)
        {
            foreach (j, ref bel2; beliefs2)
            {
                double[] currentSet;
                auto intersection = setIntersection(powerSet[i], powerSet[j]);
                if (intersection.empty)
                {
                    currentSet = (powerSet[i] ~ powerSet[j]).dup;
                    currentSet.sort;
                }
                else
                {
                    currentSet ~= powerSet[i];
                    foreach (ref element; powerSet[j])
                        if (currentSet.find(element).length == 0)
                            currentSet ~= element;
                    currentSet.sort();
                }
                if (approxEqual(bel1, 0.0) || approxEqual(bel2, 0.0))
                {

                }
            }
        }

        return beliefs;
    }
}

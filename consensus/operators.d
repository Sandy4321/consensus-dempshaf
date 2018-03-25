module dempshaf.consensus.operators;

/**
 * The Operators class provides operators for dealing with agents' beliefs.
 */
public final class Operators
{
    /**
     * Consensus operator for uncertain three-valued beliefs.
     */
    static auto ref beliefConsensus(
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
     * Consensus operator for Dempster-Shafer mass functions.
     */

    static auto ref consensus(
        ref in int[][] powerSet,
        in double[int] beliefs1,
        in double[int] beliefs2) pure
    {
        import std.algorithm : find, setIntersection, sort, sum;
        import std.math : approxEqual;

        double[int] beliefs;

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

                int[] currentSet;
                auto intersection = setIntersection(powerSet[i], powerSet[j]);

                if (intersection.empty)
                {
                    // If the intersection is the empty set, form the union instead.
                    currentSet = (powerSet[i] ~ powerSet[j]).dup;
                    currentSet.sort;
                }
                else
                {
                    // If the intersection is not empty, recreate the intersection set.
                    foreach (elem; intersection)
                        currentSet ~= elem;
                }
                foreach (int k, ref set; powerSet)
                {
                    if (currentSet == set)
                    {
                        beliefs[k] += bel1 * bel2;
                    }
                }
            }
        }

        foreach (ref index; beliefs.byKey)
            beliefs[index] /= beliefs.byValue.sum;

        return beliefs;
    }

    /**
     * Dempster-Shafer's rule of combination operator.
     */

    static auto ref combination(
        ref in int[][] powerSet,
        in double[int] beliefs1,
        in double[int] beliefs2) //pure
    {
        import std.algorithm : setIntersection, sort, sum;
        import std.math : approxEqual;

        auto beliefs = new double[powerSet.length];
        beliefs[] = 0;

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

                int[] currentSet;
                auto intersection = setIntersection(powerSet[i], powerSet[j]);

                if (intersection.empty)
                {
                    // If the intersection is the empty set, add to empty set
                    // and renormalise later.
                }
                else
                {
                    // If the intersection is not empty, recreate the intersection set.
                    foreach (elem; intersection)
                        currentSet ~= elem;
                }
                foreach (k, ref set; powerSet)
                {
                    if (currentSet == set)
                    {
                        beliefs[k] += bel1 * bel2;
                    }
                }
            }
        }

        beliefs[] /= beliefs.sum;

        return beliefs;
    }
}

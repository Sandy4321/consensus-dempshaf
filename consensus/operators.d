module dempshaf.consensus.operators;

/**
 * The Operators class provides operators for dealing with agents' beliefs.
 */
public final class Operators
{
    /**
     * Set the precision of the approxEqual checks.
     */
    static immutable auto precision = 1e-4;
    /**
     * Consensus operator for Dempster-Shafer mass functions.
     */
    static auto ref consensus(
        ref in int[][] powerset,
        in double[int] beliefs1,
        in double[int] beliefs2,
        in double threshold,
        in bool affectOperator,
        ref in double lambda) pure
    {
        import std.algorithm : find, setIntersection, sort, sum, uniq;
        import std.array : array;
        import std.math : approxEqual, isNaN;

        import dempshaf.consensus.ds;

        double[int] beliefs;

        foreach (i, ref bel1; beliefs1)
        {
            // If the mass is 0, skip this set.
            if (approxEqual(bel1, 0.0, precision))
                continue;
            foreach (j, ref bel2; beliefs2)
            {
                // If the mass is 0, skip this set.
                if (approxEqual(bel2, 0.0, precision))
                    continue;
                int[] currentSet;
                auto intersection = setIntersection(powerset[i], powerset[j]);

                // Only threshold the operator if affectOperator == true
                if (affectOperator &&
                    !DempsterShafer.setSimilarity(
                        powerset[i],
                        powerset[j],
                        threshold
                    )
                )
                {
                    // If the agents are not sufficiently similar, according to
                    // the threshold gamma, then take the union.
                    currentSet = (powerset[i] ~ powerset[j]).dup.sort.uniq.array;
                }
                // If not affecting the operator, or above condition fails anyway,
                // simply check that the intersection is the empty set.
                else if (intersection.empty)
                {
                    // If the intersection is the empty set, form the union instead.
                    currentSet = (powerset[i] ~ powerset[j]).dup.sort.uniq.array;
                }
                else
                {
                    // If the intersection is not empty, recreate the intersection set.
                    foreach (elem; intersection)
                        currentSet ~= elem;
                }
                foreach (int k, ref set; powerset)
                {
                    if (currentSet == set)
                    {
                        beliefs[k] += bel1 * bel2;
                    }
                }
            }
        }

        // Apply the lambda parameter to skew beliefs away from the usual fixed-points
        // of 0 and 1.
        foreach (ref index; beliefs.byKey)
        {
            beliefs[index] *= 1 - lambda;
        }
        beliefs[cast(int) powerset.length - 1] += lambda;

        // Normalisation to ensure beliefs sum to 1.0 due to potential rounding errors.
        immutable auto renormaliser = beliefs.byValue.sum;

        if (renormaliser != 1.0)
        {
            foreach (ref index; beliefs.byKey)
            {
                beliefs[index] /= renormaliser;
            }
        }

        return beliefs;
    }

    /**
     * Dempster-Shafer's rule of combination operator.
     */
    static auto ref dempsterRoC(
        ref in int[][] powerset,
        in double[int] beliefs1,
        in double[int] beliefs2,
        in double threshold,
        in bool affectOperator,
        ref in double lambda) pure
    {
        import std.algorithm : setIntersection, sort, sum;
        import std.math : approxEqual, isInfinity, isNaN;

        double[int] beliefs;
        auto emptySet = 0.0;

        foreach (i, ref bel1; beliefs1)
        {
            // If the mass is 0, skip this set.
            if (approxEqual(bel1, 0.0, this.precision))
                continue;
            foreach (j, ref bel2; beliefs2)
            {
                // If the mass is 0, skip this set.
                if (approxEqual(bel2, 0.0, this.precision))
                    continue;
                int[] currentSet;
                auto intersection = setIntersection(powerset[i], powerset[j]);
                if (intersection.empty)
                {
                    // If the intersection is the empty set, add to empty set
                    // and renormalise later.
                    emptySet += bel1 * bel2;
                    continue;
                }
                else
                {
                    // If the intersection is not empty, recreate the intersection set.
                    foreach (elem; intersection)
                        currentSet ~= elem;
                }
                foreach (int k, ref set; powerset)
                {
                    if (currentSet == set)
                    {
                        beliefs[k] += bel1 * bel2;
                    }
                }
            }
        }

        if (beliefs.length == 1)
        {
            beliefs[beliefs.keys[0]] = 1.0;
        }
        else if (beliefs.length > 1)
        {
            foreach (ref index; beliefs.byKey)
            {
                beliefs[index] /= 1.0 - emptySet;
            }
        }
        else
        {
            // If beliefs are completely inconsistent, just return the original belief.
            return cast(double[int]) beliefs1;
        }

        // Apply the lambda parameter to skew beliefs away from the usual fixed-points
        // of 0 and 1.
        foreach (ref index; beliefs.byKey)
        {
            beliefs[index] *= 1 - lambda;
        }
        beliefs[cast(int) powerset.length - 1] += lambda;

        // Normalisation to ensure beliefs sum to 1.0 due to potential rounding errors.
        immutable auto renormaliser = beliefs.byValue.sum;

        if (renormaliser != 1.0)
        {
            foreach (ref index; beliefs.byKey)
            {
                beliefs[index] /= renormaliser;
            }
        }

        return beliefs;
    }
}

module dempshaf.consensus.operators;

/**
 * The Operators class provides operators for dealing with agents' beliefs.
 */
public final class Operators
{
    /**
     * Consensus operator for Dempster-Shafer mass functions.
     */
    static auto ref consensus(
        ref in int[][] powerSet,
        in double[int] beliefs1,
        in double[int] beliefs2,
        ref in double gamma,
        ref in double lambda) pure
    {
        import std.algorithm : find, setIntersection, sort, sum;
        import std.math : approxEqual;

        import dempshaf.consensus.ds;

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

                if (intersection.empty || DempsterShafer.setSimilarity(
                    powerSet[i],
                    powerSet[j],
                    gamma))
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

        // Apply the lambda parameter to skew beliefs away from the usual fixed-points
        // of 0 and 1.
        foreach (ref index; beliefs.byKey)
        {
            beliefs[index] *= 1 - lambda;
        }
        beliefs[cast(int) powerSet.length - 1] += lambda;

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
        ref in int[][] powerSet,
        in double[int] beliefs1,
        in double[int] beliefs2,
        ref in double gamma,
        ref in double lambda) pure
    {
        import std.algorithm : setIntersection, sort, sum;
        import std.math : approxEqual, isInfinity, isNaN;

        double[int] beliefs;
        auto emptySet = 0.0;

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
                    emptySet += bel1 * bel2;
                    continue;
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

        assert(!beliefs.byValue.sum.isNaN && !beliefs.byValue.sum.isInfinity);

        if (beliefs.length == 1)
        {
            beliefs[beliefs.keys[0]] = 1.0;
        }
        else if (beliefs.length > 1)
        {
            foreach (ref index; beliefs.byKey)
            {
                beliefs[index] /= 1.0 - emptySet;
                assert(!beliefs[index].isNaN && !beliefs[index].isInfinity);
            }
        }
        else
        {
            // I think this could also be:
            // beliefs1.to!(double[int])  -- brackets required for the [int] part.
            // Can also make it beliefs1.castFrom!(double[int]).to!(double[int])
            // to check the requirement that you're casting to the same type as before.
            return cast(double[int]) beliefs1;
        }

        assert(beliefs.length > 0);

        // Apply the lambda parameter to skew beliefs away from the usual fixed-points
        // of 0 and 1.
        foreach (ref index; beliefs.byKey)
        {
            beliefs[index] *= 1 - lambda;
        }
        beliefs[cast(int) powerSet.length - 1] += lambda;

        // Normalisation to ensure beliefs sum to 1.0 due to potential rounding errors.
        immutable auto renormaliser = beliefs.byValue.sum;

        if (renormaliser != 1.0)
        {
            foreach (ref index; beliefs.byKey)
            {
                beliefs[index] /= renormaliser;
                assert(!beliefs[index].isNaN && !beliefs[index].isInfinity);
            }
        }

        return beliefs;
    }
}

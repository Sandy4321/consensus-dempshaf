module dempshaf.consensus.operators;

import dempshaf.consensus.ds;

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
    static auto consensus(
        const int langSize,
        const double[int] beliefs1,
        const double[int] beliefs2,
        const double threshold,
        const bool affectOperator,
        const double lambda) pure
    {
        import std.algorithm : find, setIntersection, sort, sum, uniq;
        import std.array : array;
        import std.math : approxEqual, isNaN;

        import dempshaf.consensus.ds;

        import std.stdio : writeln;

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
                auto set1 = DempsterShafer.createSet(langSize, i);
                auto set2 = DempsterShafer.createSet(langSize, j);
                auto intersection = setIntersection(set1, set2);

                // Only threshold the operator if affectOperator == true
                if (affectOperator &&
                    !DempsterShafer.setSimilarity(
                        set1,
                        set2,
                        threshold
                    ))
                {
                    // If the agents are not sufficiently similar, according to
                    // the threshold gamma, then take the union.
                    currentSet = (set1 ~ set2).dup.sort.uniq.array;
                }
                // If not affecting the operator, or above condition fails anyway,
                // simply check that the intersection is the empty set.
                else if (intersection.empty)
                {
                    // If the intersection is the empty set, form the union instead.
                    currentSet = (set1 ~ set2).dup.sort.uniq.array;
                }
                else
                {
                    // If the intersection is not empty, recreate the intersection set.
                    foreach (elem; intersection)
                        currentSet ~= elem;
                }

                beliefs[DempsterShafer.setToIndex(langSize, currentSet)] += bel1 * bel2;
            }
        }

        // Apply the lambda parameter to skew beliefs away from the usual fixed-points
        // of 0 and 1.
        foreach (ref index; beliefs.byKey)
        {
            beliefs[index] *= 1 - lambda;
        }
        if (lambda > 0) beliefs[cast(int) (2^^langSize) - 2] += lambda;

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
    static auto dempsterRoC(
        const int langSize,
        const double[int] beliefs1,
        const double[int] beliefs2,
        const double threshold,
        const bool affectOperator,
        const double lambda) pure
    {
        import std.algorithm : setIntersection, sort, sum;
        import std.math : approxEqual, isInfinity, isNaN;

        import std.stdio : writeln;

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
                auto set1 = DempsterShafer.createSet(langSize, i);
                auto set2 = DempsterShafer.createSet(langSize, j);
                auto intersection = setIntersection(set1, set2);
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

                beliefs[DempsterShafer.setToIndex(langSize, currentSet)] += bel1 * bel2;
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
            return null;
        }

        // Apply the lambda parameter to skew beliefs away from the usual fixed-points
        // of 0 and 1.
        foreach (ref index; beliefs.byKey)
        {
            beliefs[index] *= 1 - lambda;
        }
        if (lambda > 0) beliefs[cast(int) (2^^langSize) - 2] += lambda;

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

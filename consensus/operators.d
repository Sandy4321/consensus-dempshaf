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
    alias precision = DempsterShafer.precision;
    /**
      * Set of static variables.
      */
    static int[] currentSet;


    /**
     * Consensus operator for Dempster-Shafer mass functions.
     */
    static auto consensus(
        const int langSize,
        const double[int] beliefs1,
        const double[int] beliefs2,
        const double threshold,
        const bool affectOperator,
        const double lambda)
    {
        import std.algorithm : canFind, setIntersection, sort, sum, uniq;
        import std.array : array;
        import std.math : approxEqual, isNaN;

        import dempshaf.consensus.ds;

        import std.stdio : writeln;

        double[int] beliefs;
        if (currentSet == null) currentSet.reserve(langSize);

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

                auto set1 = DempsterShafer.createSet(i);
                auto set2 = DempsterShafer.createSet(j);
                auto intersection = setIntersection(set1, set2);

                // Only threshold the operator if affectOperator == true
                if (intersection.empty || (affectOperator && DempsterShafer.setSimilarity(set1, set2) <= threshold))
                {
                    // If the agents are not sufficiently similar, according to
                    // the threshold gamma, or if the intersection is the empty set,
                    // then take the union.
                    // currentSet = (set1 ~ set2).dup.sort.uniq.array;
                    currentSet = set1;
                    foreach (elem; set2)
                    {
                        if (!set1.canFind(elem)) currentSet ~= elem;
                    }
                    currentSet.sort;
                }
                else
                {
                    // If the intersection is not empty, recreate the intersection set.
                    currentSet = intersection.array;
                }
                beliefs[DempsterShafer.setToIndex(currentSet)] += bel1 * bel2;
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
        const double lambda)
    {
        import std.algorithm : setIntersection, sort, sum;
        import std.math : approxEqual, isInfinity, isNaN;
        import std.range : array;

        double[int] beliefs;
        auto emptySet = 0.0;
        if (currentSet == null) currentSet.reserve(langSize);

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

                auto set1 = DempsterShafer.createSet(i);
                auto set2 = DempsterShafer.createSet(j);
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
                    currentSet = intersection.array;
                }

                beliefs[DempsterShafer.setToIndex(currentSet)] += bel1 * bel2;
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

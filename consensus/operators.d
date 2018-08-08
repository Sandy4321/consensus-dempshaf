module dempshaf.consensus.operators;

import dempshaf.consensus.ds;

/**
 * The Operators class provides operators for dealing with agents' beliefs.
 * These are specific to Dempster-Shafer mass functions.
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
    static int[] setUnion;

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
        import std.algorithm : copy, setIntersection, sort, sum, uniq;
        import std.array : array;
        import std.conv : to;
        import std.math : approxEqual;
        import std.range.primitives : walkLength;

        double[int] beliefs;
        if (currentSet == null) currentSet.reserve(langSize);
        if (setUnion == null) setUnion.reserve(langSize * 2);

        foreach (i, ref bel1; beliefs1)
        {
            // If the mass is 0, skip this set.
            if (approxEqual(bel1, 0.0, precision)) continue;

            foreach (j, ref bel2; beliefs2)
            {
                // If the mass is 0, skip this set.
                if (approxEqual(bel2, 0.0, precision)) continue;

                auto set1 = DempsterShafer.createSet(i);
                auto set2 = DempsterShafer.createSet(j);
                auto setIntersec = setIntersection(set1, set2);

                setUnion.length = set1.length + set2.length;
                setUnion[0 .. set1.length] = set1;
                setUnion[set1.length .. set1.length + set2.length] = set2;

                setUnion.length -= setUnion.sort.uniq.copy(setUnion).length;

                immutable auto similarity = setIntersec.walkLength.to!double /
                                            setUnion.length.to!double;

                /*
                 * Only threshold the operator if affectOperator == true.
                 * If the agents are not sufficiently similar, according to
                 * the threshold gamma, or if the intersection is the empty set,
                 * then take the union.
                 */
                if (setIntersec.empty ||
                    (affectOperator && similarity <= threshold))
                {
                    currentSet = setUnion;
                }
                // If the intersection is not empty, recreate the intersection set.
                else currentSet = setIntersec.array;

                beliefs[DempsterShafer.setToIndex(currentSet)] += bel1 * bel2;
            }
        }

        // Apply the lambda parameter to skew beliefs away from the usual fixed-points
        // of 0 and 1.
        foreach (ref index; beliefs.byKey) beliefs[index] *= 1 - lambda;
        if (lambda > 0) beliefs[cast(int) (2^^langSize) - 2] += lambda;

        // Normalisation to ensure beliefs sum to 1.0 due to potential rounding errors.
        immutable auto renormaliser = beliefs.byValue.sum;

        if (renormaliser != 1.0)
            foreach (ref index; beliefs.byKey)
                beliefs[index] /= renormaliser;

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
        import std.algorithm : setIntersection, sum;
        import std.math : approxEqual, isInfinity;
        import std.range : array;

        double[int] beliefs;
        auto emptySet = 0.0;
        if (currentSet == null) currentSet.reserve(langSize);
        if (setUnion == null) setUnion.reserve(langSize * 2);

        foreach (i, ref bel1; beliefs1)
        {
            // If the mass is 0, skip this set.
            if (approxEqual(bel1, 0.0, this.precision)) continue;

            foreach (j, ref bel2; beliefs2)
            {
                // If the mass is 0, skip this set.
                if (approxEqual(bel2, 0.0, this.precision)) continue;

                auto set1 = DempsterShafer.createSet(i);
                auto set2 = DempsterShafer.createSet(j);
                auto setIntersec = setIntersection(set1, set2);

                /*
                 * If the intersection is the empty set, add to empty set
                 * and renormalise later.
                 */
                if (setIntersec.empty)
                {
                    emptySet += bel1 * bel2;
                    continue;
                }
                // If the intersection is not empty, recreate the intersection set.
                else currentSet = setIntersec.array;

                beliefs[DempsterShafer.setToIndex(currentSet)] += bel1 * bel2;
            }
        }

        if (beliefs.length == 1) beliefs[beliefs.keys[0]] = 1.0;
        else if (beliefs.length > 1)
            foreach (ref index; beliefs.byKey)
                beliefs[index] /= 1.0 - emptySet;
        // If beliefs are completely inconsistent, just return the original belief.
        else return null;

        // Apply the lambda parameter to skew beliefs away from the usual fixed-points
        // of 0 and 1.
        foreach (ref index; beliefs.byKey) beliefs[index] *= 1 - lambda;
        if (lambda > 0) beliefs[cast(int) (2^^langSize) - 2] += lambda;

        // Normalisation to ensure beliefs sum to 1.0 due to potential rounding errors.
        immutable auto renormaliser = beliefs.byValue.sum;

        if (renormaliser != 1.0)
            foreach (ref index; beliefs.byKey)
                beliefs[index] /= renormaliser;

        return beliefs;
    }
}

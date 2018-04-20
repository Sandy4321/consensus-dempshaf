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
        ref in double lambda) pure
    {
        import std.algorithm : find, setIntersection, sort, sum;
        import std.math : approxEqual;

        double[int] beliefs;

        foreach (i, ref bel1; beliefs1)
        {
            // If the mass is 0, skip this set.
            /* if (approxEqual(bel1, 0.0))
                continue; */
            foreach (j, ref bel2; beliefs2)
            {
                // If the mass is 0, skip this set.
                /* if (approxEqual(bel2, 0.0))
                    continue; */

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
                    if (currentSet == set && bel1 * bel2 != 0)
                    {
                        beliefs[k] += bel1 * bel2;
                    }
                }
            }
        }

        foreach (ref index; beliefs.byKey)
        {
            beliefs[index] *= 1 - lambda;
        }

        if (!beliefs.byKey.find(cast(int) powerSet.length - 1).empty)
        {
            beliefs[cast(int) powerSet.length - 1] += lambda;
        }

        // Normalisation to ensure beliefs sum to 1.0 due to potential rounding errors.

        immutable auto normaliser = beliefs.byValue.sum;

        foreach (ref index; beliefs.byKey)
        {
            beliefs[index] /= normaliser;
        }

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
        import std.math : approxEqual, isNaN;

        import std.stdio;

        double[int] beliefs;
        auto emptySet = 0.0;

        writeln("-------------------------");
        writeln("Beliefs1: ", beliefs1);
        writeln("Beliefs2: ", beliefs2);
        writeln("-------------------------");

        foreach (i, ref bel1; beliefs1)
        {
            // If the mass is 0, skip this set.
            // if (approxEqual(bel1, 0.0))
            //     continue;
            foreach (j, ref bel2; beliefs2)
            {
                // If the mass is 0, skip this set.
                // if (approxEqual(bel2, 0.0))
                //     continue;

                int[] currentSet;
                auto intersection = setIntersection(powerSet[i], powerSet[j]);
                writeln(intersection, ": ", powerSet[i], ", ", powerSet[j]);

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
                    if (currentSet == set && bel1 * bel2 != 0)
                    {
                        beliefs[k] += bel1 * bel2;
                    }
                }
            }
        }
        writeln(beliefs.keys);
        writeln(beliefs.values);

        if (beliefs.length == 1)
        {
            beliefs[beliefs.keys[0]] = 1.0;
        }
        else if (beliefs.length > 0)
        {
            foreach (ref index; beliefs.byKey)
            {
                beliefs[index] /= 1.0 - emptySet;
                assert(!beliefs[index].isNaN);
            }
        }
        else
        {
            beliefs[cast(int) powerSet.length - 1] = 1.0;
            assert(!beliefs[cast(int) powerSet.length - 1].isNaN);
        }

        writeln("Lambda'd:", beliefs.values);

        assert(beliefs.length > 0);

        // Normalisation to ensure beliefs sum to 1.0 due to potential rounding errors.
        immutable auto normaliser = beliefs.byValue.sum;
        writeln("Normaliser: ", normaliser);

        if (normaliser != 1.0)
        {
            foreach (ref index; beliefs.byKey)
            {
                beliefs[index] /= normaliser;
                assert(!beliefs[index].isNaN);
            }
        }

        writeln("Renormalised:", beliefs.values);

        return beliefs;
    }
}

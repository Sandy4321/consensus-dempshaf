module dempshaf.consensus.operators;

/**
 * The Operators class provides operators for dealing with agents' beliefs.
 */
public final class Operators
{
    /**
     * Consensus operator for uncertain three-valued beliefs.
     */
    static double[] beliefConsensus(
        in double[] beliefs1,
        in double[] beliefs2) pure
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

    static auto ruleOfCombination(
        in double[] beliefs1,
        in double[] beliefs2) pure
    {
        return;
    }
}

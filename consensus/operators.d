module dempshaf.consensus.operators;

public final class Operators
{
    static double entropy(
        ref in double[] beliefs,
        ref in int l) pure
    {
        import std.math : log, log2;

        double entropy = 0.0;
        double one, two, logOne, logTwo, logThree = 0.0;

        foreach (belief; beliefs)
        {
            one = (belief[1] - belief[0]) < 0 ? 0 : (belief[1] - belief[0]);
            two = (1.0 - belief[1]) < 0 ? 0 : 1.0 - belief[1];

            logOne = (belief[0] == 0 ? 0 : log2(belief[0]));
            logTwo = (one == 0 ? 0 : log2(one));
            logThree = (two == 0 ? 0 : log2(two));

            entropy -= (belief[0] * logOne)
                    + (one * logTwo)
                    + (two * logThree);
        }

        return entropy / l;
    }

    static double inconsistency(
        in double[] beliefs1,
        in double[] beliefs2,
        ref in int l) pure
    {
        double inconsistency = 0.0;
        foreach (prop; 0 .. l)
        {
            inconsistency += (beliefs1[prop][0] * (1.0 - beliefs2[prop][1])) +
                ((1.0 - beliefs1[prop][1]) * beliefs2[prop][0]);
        }

        return (inconsistency / l);
    }

    static double[] beliefConsensus(
        double[] beliefs1,
        double[] beliefs2) pure
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


}

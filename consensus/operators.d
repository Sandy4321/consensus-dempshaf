module dempshaf.consensus.operators;

public final class Operators
{
    static double entropy(
        ref in double[2][] beliefs,
        ref in int l) pure
    {
        import std.math;

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
        in double[2][] beliefs1,
        in double[2][] beliefs2,
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

    static double frankTNorm(T, L)(T belief1, T belief2, L p) pure
    {
        import std.math;

        T function(T value1, T value2, L p) func;

        if (p == 0) func = (x, y, p) => (x <= y) ? x : y;
        else if (p == 1) func = (x, y, p) => x * y;
        else
        {
            func = (x, y, p)
            {
                return log(1 + ( ((pow(exp(p), x) - 1) * (pow(exp(p), y) - 1) ) / (exp(p) - 1)) ) / p;
            };
        }

        return func(belief1, belief2, p);
    }

    static double[2][] beliefConsensus(
        double[2][] beliefs1,
        double[2][] beliefs2) pure
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

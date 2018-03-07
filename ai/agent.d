module dempshaf.ai.agent;

public final class Agent
{
    private
    {
        double[] mBeliefs;
        double mPayoff;
        int interactions;
    }

    void beliefs(double[] beliefs)
    {
        import std.string, std.conv;

        this.mBeliefs = beliefs;
        string tempProp;
        foreach (ref belief; this.mBeliefs)
            foreach (ref prop; belief)
                if (prop >= 1.0) prop = 1.0;
                else
                {
                    tempProp = format("%.5f", prop);
                    prop = to!double(tempProp);
                }
    }

    double[] beliefs() pure
    {
        return this.mBeliefs;
    }

    void payoff(in double payoff) pure
    {
        this.mPayoff = payoff;
    }

    double payoff() pure
    {
        return this.mPayoff;
    }

    double ignorance(in int l) pure
    {
        import std.conv;

        auto ignorance = 0.0;
        foreach (int i, ref belief; beliefs)
        {
            ignorance += belief[1] - belief[0];
        }
        return ignorance / to!double(l);
    }

    void incrementInteractions() pure
    {
        this.interactions++;
    }

    int getInteractions() pure
    {
        return this.interactions;
    }

    void resetInteractions() pure
    {
        this.interactions = 0;
    }
}

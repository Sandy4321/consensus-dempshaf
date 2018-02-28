module dempshaf.ai.agent;

import std.string, std.conv;

public final class Agent
{
    private
    {
        double[2][] mBeliefs;
        double mPayoff;
        int interactions;
    }

    void beliefs(double[2][] beliefs)
    {
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

    double[2][] beliefs() pure
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

    double vagueness(in int l) pure
    {
        auto vagueness = 0.0;
        foreach (int i, ref belief; beliefs)
        {
            vagueness += belief[1] - belief[0];
        }
        return vagueness / cast(double) l;
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

module dempshaf.ai.agent;

public final class Agent
{
    private
    {
        double[] mBeliefs;
        double mPayoff;
        int interactions;
    }

    /**
     *
     */
    auto beliefs(ref double[] beliefs)
    {
        import std.string : format;
        import std.conv : to;

        this.mBeliefs = beliefs;
        string tempProp;
        foreach (ref prop; this.mBeliefs)
        {
            if (prop >= 1.0) prop = 1.0;
            else
            {
                tempProp = format("%.5f", prop);
                prop = to!double(tempProp);
            }
        }
    }

    /**
     *
     */
    auto ref beliefs() pure
    {
        return this.mBeliefs;
    }

    /**
     *
     */
    void payoff(ref in double payoff) pure
    {
        this.mPayoff = payoff;
    }

    /**
     *
     */
    auto ref payoff() pure
    {
        return this.mPayoff;
    }

    /**
     *
     */
    void incrementInteractions() pure
    {
        this.interactions++;
    }

    /**
     *
     */
    auto ref getInteractions() pure
    {
        return this.interactions;
    }

    /**
     *
     */
    void resetInteractions() pure
    {
        this.interactions = 0;
    }
}

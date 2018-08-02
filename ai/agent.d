module dempshaf.ai.agent;

/**
 * Agent class that contains the behaviours of each agent, such as setting and
 * retrieving beliefs, payoff, and keeping count of interactions.
 */
public final class Agent
{
    import std.array : appender;

    private
    {
        double[int] mBeliefs;
        int mInteractions;
        int mTimeSinceChange;
        double[2] mBelPl;

        // Temp variables
        auto tempIndices = appender!(int[]);
        auto tempBeliefs = appender!(double[]);
        string tempProp;
    }

    /**
     * Set the beliefs of an agent, which is a mass function.
     */
    void beliefs(double[int] beliefs, bool increment = false)
    {
        import std.algorithm : equal, map, sort;
        import std.algorithm.iteration : each;
        import std.array : assocArray;
        import std.conv : to;
        import std.math : approxEqual;
        import std.range : zip;
        import std.string : format;

        tempIndices.clear;
        tempIndices.reserve(beliefs.keys.length);
        tempBeliefs.clear;
        tempBeliefs.reserve(beliefs.values.length);

        foreach (int index, ref prop; beliefs)
        {
            if (prop >= 1.0)
            {
                tempIndices ~= index;
                tempBeliefs ~= 1.0;
            }
            else if (prop == 0.0)
            {
                continue;
            }
            else
            {
                tempProp = format("%.5f", prop);
                tempIndices ~= index;
                tempBeliefs ~= to!double(tempProp);
            }
        }

        if (tempIndices.data.length == this.mBeliefs.length)
            foreach (tIndex, ref index; tempIndices.data)
                if (index in this.mBeliefs &&
                    tempBeliefs.data[tIndex].approxEqual(this.mBeliefs[index]))
                    this.mTimeSinceChange++;
                else this.mTimeSinceChange = 0;

        // if (tempBeliefs.keys.sort.equal(this.mBeliefs.keys.sort) &&
        //     tempBeliefs.keys.sort.map!(x => tempBeliefs[x])
        //         .equal!approxEqual(
        //             this.mBeliefs.keys.sort.map!(
        //                 x => this.mBeliefs[x]
        //     )))
        // {
        //     this.mTimeSinceChange++;
        // }
        // else this.mTimeSinceChange = 0;

        // this.mBeliefs = tempBeliefs.dup;
        this.mBeliefs = zip(tempIndices.data, tempBeliefs.data).assocArray;
        if (increment) this.incrementInteractions;

        this.belAndPl;
    }

    /**
     * Return the beliefs of an agent.
     */
    auto beliefs() pure
    {
        return this.mBeliefs;
    }

    /**
     * Calculate the Bel and Pl of each singleton from an agent's
     * mass function.
     */
    void belAndPl(double[int] beliefs) pure
    {
        double[2] belPl;
    }

    /**
     * Return the Bel and Pl of each singleton.
     */
    auto belAndPl() pure
    {
        return this.mBelPl;
    }

    /**
     * Increment the interaction count of the agent.
     */
    void incrementInteractions() pure
    {
        this.mInteractions++;
    }

    /**
     * Set the interaction count of the agent.
     */
    void interactions(const int interactions) pure
    {
        this.mInteractions = interactions;
    }

    /**
     * Return the interaction count of the agent.
     */
    auto interactions() pure
    {
        return this.mInteractions;
    }

    /**
     * Reset the agent's interactions count.
     */
    void resetInteractions() pure
    {
        this.mInteractions = 0;
    }

    /**
     * Set the number of iterations since the agent's beliefs changed.
     */
    void timeSinceChange(const int timeSinceChange) pure
    {
        this.mTimeSinceChange = timeSinceChange;
    }

    /**
     * Return the number of iterations since the agent's beliefs changed.
     */
    auto timeSinceChange() pure
    {
        return this.mTimeSinceChange;
    }

    /**
     * Duplication function for agents.
     */
    auto dup()
    {
        Agent duplicate = new Agent();

        duplicate.beliefs = this.mBeliefs;
        return duplicate;
    }
}

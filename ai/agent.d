module dempshaf.ai.agent;

/**
 * Agent class that contains the behaviours of each agent, such as setting and
 * retrieving beliefs, payoff, and keeping count of interactions.
 */
public final class Agent
{
    private
    {
        double[int] mBeliefs;
        int mInteractions;
        int mTimeSinceChange;
    }

    /**
     * Set the beliefs of an agent, which is a mass function.
     */
    void beliefs(double[int] beliefs)
    {
        import std.algorithm : equal, map, sort;
        import std.conv : to;
        import std.math : approxEqual;
        import std.string : format;

        double[int] tempBeliefs;
        string tempProp;
        foreach (index, ref prop; beliefs)
        {
            if (prop >= 1.0)
            {
                tempBeliefs[index] = 1.0;
            }
            else if (prop == 0.0)
            {
                continue;
            }
            else
            {
                tempProp = format("%.5f", prop);
                tempBeliefs[index] = to!double(tempProp);
            }
        }

        if (tempBeliefs.keys.sort.equal(this.mBeliefs.keys.sort) &&
            tempBeliefs.keys.sort.map!(x => tempBeliefs[x])
                .equal!approxEqual(
                    this.mBeliefs.keys.sort.map!(
                        x => this.mBeliefs[x]
                    )
            ))
        {
            this.mTimeSinceChange++;
        }
        else this.mTimeSinceChange = 0;
        this.mBeliefs = tempBeliefs;
        this.incrementInteractions;
    }

    /**
     * Return the beliefs of an agent
     */
    auto beliefs() pure
    {
        return this.mBeliefs;
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
    void interactions(in int interactions) pure
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
    void timeSinceChange(in int timeSinceChange) pure
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
        duplicate.interactions = this.mInteractions;
        duplicate.timeSinceChange = this.mTimeSinceChange;
        return duplicate;
    }
}

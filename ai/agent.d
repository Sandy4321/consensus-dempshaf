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
        double mPayoff;
        int interactions;
    }

    /**
     * Set the beliefs of an agent, which is a mass function.
     */
    void beliefs(ref double[int] beliefs)
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
     * Return the beliefs of an agent
     */
    auto ref beliefs() pure
    {
        return this.mBeliefs;
    }

    /**
     * Set the payoff of an agent.
     */
    void payoff(ref in double payoff) pure
    {
        this.mPayoff = payoff;
    }

    /**
     * Return the payoff of an agent.
     */
    auto ref payoff() pure
    {
        return this.mPayoff;
    }

    /**
     * Increment the interaction count of the agent.
     */
    void incrementInteractions() pure
    {
        this.interactions++;
    }

    /**
     * return the interaction count of the agent.
     */
    auto ref getInteractions() pure
    {
        return this.interactions;
    }

    /**
     * Reset the agent's interactions count.
     */
    void resetInteractions() pure
    {
        this.interactions = 0;
    }

    /**
     * Copy function for agents.
     */
    Agent dup() {
        Agent duplicate = new Agent();
        duplicate.beliefs = this.mBeliefs;
        duplicate.payoff = this.mPayoff;
        duplicate.interactions = this.interactions;
        return duplicate;
    }
}

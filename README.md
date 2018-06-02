# Dempster-Shafer model for multi-agent consensus

This is a version of the kind of consensus model developed during my Ph.D. in which agents broadcast their beliefs to the surrounding, listening agents, who update their beliefs based on the broadcast (disregards spatial constraints - belief-space only). Specifically, this is a voter-type model set in the context of the best-of-n problem. In this model, beliefs are not three-valued w/ (imprecise) probability, but instead are represented in Dempster-Shafer's theory of evidence.

We are interested in looking at a range of problems within this model, including:

- Consensus operator (Ph.D.) vs Dempster's rule of combination.
- Recovery from changes in qualities of choices; dropping quality value of dominant choice to see how the population reacts to changes in the environment.
- Benchmarking with evidential-updating only.
- Negative information: where agents consider two "choices" to receive an incomplete partial ordering, with which they update their beliefs based on choice X being NOT the best choice, for X < Y.

#### Part of project T-B PHASE | 2017 - 2022

#### Run command:

rdmd -I../ world 5 100 --dist=0

#### Useful notes

rdmd -I../ -unittest -main dir/filename

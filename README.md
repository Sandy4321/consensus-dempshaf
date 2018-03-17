# Dempster-Shafer model for multi-agent consensus

This is a version of the kind of consensus model developed during my Ph.D. in which agents broadcast their beliefs to the surrounding, listening agents, who update their beliefs based on the broadcast (disregards spatial constraints - belief-space only). Specifically, this is a voter-type model set in the context of the best-of-n problem. In this model, beliefs are not three-valued w/ (imprecise) probability, but instead are represented in Dempster-Shafer's theory of evidence.

We are interested in looking at a range of problems within this model, including:

- Consensus operator (Ph.D.) vs Dempster's rule of combination.

#### Part of project T-B PHASE | 2017 - 2022__

#### Run command:

rdmd -I../ world 5 100 --dist=0 --thrStart=1.0 --thrEnd=1.0

#### Useful notes

rdmd -I../ -unittest -main dir/filename

# A model of multi-agent evidence propagation and consensus formation in the Dempster-Shafer framework.

In this model we compare two operators within the framework of Dempster-Shafer Theory, or Evidence Theory. This allows us to intuitively capture agents' uncertainty and, ideally, to study operators that might lead to convergence to imprecise beliefs, such as "the patient has either disease 1 or disease 2, but not any other disease." The first operator, Dempster's Rule of Combination (RoC) will be familiar to those also familiar with DST, as it is the most common rule for combining different sources of evidence. The seceond operator, referred to herein as the consensus operator, is based on Dubois and Prade's set-based operator, where the rule is simply to take the intersection when possible, and union otherwise.

Two versions of this model have been developed: an *asymmetric* model in which the population broadcasts beliefs while simultaneously listening for new beliefs with which to merge their own. In the *symmetric* model, we select a pair of agents at random to merge their beliefs, and the pair of agents adopt the same resulting belief. Asymmetry is faster as it naturally allows for the whole population to update at each time step, where the symmetric model requires greater numbers of iterations to achieve similar levels of convergence.

We are interested in looking at a range of problems within this model, including:

- Consensus operator (intersection when possible, union otherwise) vs Dempster's rule of combination.
- Adding average operator and Yager's operator for additional comparisons.
- Thresholding the operators to allow convergence to imprecise beliefs.
- Recovery from changes in qualities of choices; dropping quality value of dominant choice to see how the population reacts to changes in the environment.
- Benchmarking with evidential-updating only.
- Negative information: where agents consider two "choices" to receive an incomplete partial ordering, with which they update their beliefs based on choice X being NOT the best choice, for X < Y.

#### Part of project T-B PHASE | 2017 - 2022

#### Run command:

rdmd -I../ (-version=sanityCheck) world 1000 5 --dist=0 {0|1|2}

#### Run results:

python3 plot_dempshaf.py [ignorant/uniform] [population_size] [lang_size] [additional_folders]

#### Useful notes

rdmd -I../ -unittest -main dir/filename

#### Profiling program

dmd -g -I../ world.d ai/agent.d consensus/ds.d consensus/operators.d misc/importidiom.d

valgrind --tool=callgrind --dump-instr=yes --collect-jumps=yes --callgrind-out-file=callgrind_out ./world [...]

rdmd -I../ misc/dcallgrind.d callgrind_out

#### Profiling GC

rdmd -profile=gc -I../ ...

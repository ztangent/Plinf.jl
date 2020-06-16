## Online Bayesian Goal Inference For Boundedly Rational Planning Agents
Experiments for NeurIPS 2020 (preprint: https://arxiv.org/abs/2006.07532).

### Setup

Clone this branch of the repository via:
```
git clone -b neurips-2020-experiments --single-branch https://github.com/ztangent/Plinf.jl.git
```

Open the Julia REPL in top-level `Plinf.jl` folder, press `]` to enter the package manager, then run `instantiate` to install all dependencies.

Exit the package manager by pressing backspace, then run
```julia
include("experiments/experiments.jl")
```
This will take a while to load and precompile all code and dependencies, following which all experimental code can be run.

### Experiments

Experiments for each domain and inference method and dataset can be run by calling the ```run_domain_experiments``` function, with the following arguments:
```julia
run_domain_experiments(EXPERIMENTS_PATH, <domain>, <dataset>, <method>)
```

For example, to run Sequential Inverse Plan Search (SIPS) on the `doors-keys-gems` domain for the dataset of optimal trajectories, call:
```julia
run_domain_experiments(EXPERIMENTS_PATH, "doors-keys-gems", "optimal", :sips)
```
and to run the Plan Recognition as Planning (PRP) baseline experiments on the `taxi` domain for the suboptimal dataset, call:
```julia
run_domain_experiments(EXPERIMENTS_PATH, "taxi", "suboptimal", :prp)
```
Bayesian Inverse Reinforcement Learning experiments were performed in Python using [PDDLGym](https://github.com/tomsilver/pddlgym/tree/hierarchical_types/custom/inverse_planning), and hence are not included in this repository. To run experiments on a specific problem (i.e. initial state) within a domain, `run_problem_experiments` can be called, given an additional argument for the problem index.

Raw results for each set of experiments will automatically by saved to `experiments/results/<domain>`, along with summary statistics in `experiments/results/<domain>_summary.csv`. If results need to be re-analyzed to compute the statistics, this can be done with `analyze_domain_results`:
```julia
analyze_domain_results(EXPERIMENTS_PATH, <domain>, save=true)
```

The full set of SIPS and PRP experiments performed in the paper can be run with the following commands

```julia
# SIPS (optimal)
run_domain_experiments(EXPERIMENTS_PATH, "taxi", "optimal", :sips)
run_domain_experiments(EXPERIMENTS_PATH, "doors-keys-gems", "optimal", :sips)
run_domain_experiments(EXPERIMENTS_PATH, "block-words", "optimal", :sips)
run_domain_experiments(EXPERIMENTS_PATH, "intrusion-detection", "optimal", :sips)

# SIPS (sub-optimal)
run_domain_experiments(EXPERIMENTS_PATH, "taxi", "suboptimal", :sips)
run_domain_experiments(EXPERIMENTS_PATH, "doors-keys-gems", "suboptimal", :sips)
run_domain_experiments(EXPERIMENTS_PATH, "block-words", "suboptimal", :sips)
run_domain_experiments(EXPERIMENTS_PATH, "intrusion-detection", "suboptimal", :sips)

# PRP (optimal)
run_domain_experiments(EXPERIMENTS_PATH, "taxi", "optimal", :prp)
run_domain_experiments(EXPERIMENTS_PATH, "doors-keys-gems", "optimal", :prp)
run_domain_experiments(EXPERIMENTS_PATH, "block-words", "optimal", :prp)
run_domain_experiments(EXPERIMENTS_PATH, "intrusion-detection", "optimal", :prp)

# PRP (sub-optimal)
run_domain_experiments(EXPERIMENTS_PATH, "taxi", "suboptimal", :prp)
run_domain_experiments(EXPERIMENTS_PATH, "doors-keys-gems", "suboptimal", :prp)
run_domain_experiments(EXPERIMENTS_PATH, "block-words", "suboptimal", :prp)
run_domain_experiments(EXPERIMENTS_PATH, "intrusion-detection", "suboptimal", :prp)
```

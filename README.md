# fdaPDE Methods Test Bench

## Overview

This repository serves as a test bench specifically designed for evaluating methods related to [fdaPDE](https://fdapde.github.io) (Physics-Informed Spatial and Functional Data Analysis). It provides a collection of utilities and scripts to facilitate the testing process, including model evaluation metrics computation, plot generation, and automation of tests with various parameter configurations.

## Features

- **Model Evaluation Metrics:** Utilities are available for computing various model evaluation metrics (`RMSE`, `IRMSE`, `...`), allowing for comprehensive assessment of fdaPDE methods' performance.
- **Plot Generation:** The repository includes tools for generating plots to visualize the results of the tested methods, aiding in the interpretation and analysis of the experimental outcomes.
- **Test Automation:** Scripts are provided for serial, local parallel, and Slurm execution. The active profile selects the default strategy.

## Usage

### Running Tests

To run tests using the provided utilities, follow these steps:

1. Create or update a profile in `config.R`.
2. Build the runtime environment:

   ```bash
   make build PROFILE=macbook
   ```

   `build` installs dependencies and prepares the profile-selected
   repository-local `libraries/fdaPDE-cpp` clone, including its recorded
   `fdaPDE/core` submodule. It also prepares nlohmann/json `v3.12.0` in
   `libraries/nlohmann-json`. Both destinations are reused, and the pinned JSON
   checkout can be prepared offline after its initial clone. On an already
   provisioned machine, initialize the profile without reinstalling:

   ```bash
   make write_env create_dirs PROFILE=macbook
   ```

   For the smoothing example, the `macbook` profile defaults to the
   `develop-Splines` outer branch, Homebrew GCC 15, and Eigen at
   `/opt/homebrew/opt/eigen/include/eigen3`. The corresponding environment
   variables remain available when a different branch or installation is
   required.

   The outer branch always comes from the active profile's
   `FDAPDE_CPP_BRANCH` key. The standard build and compile targets create or
   refresh the ignored repository-local `libraries/fdaPDE-cpp` clone from the
   configured remote `FDAPDE_CPP_REPOSITORY`, then initialize `fdaPDE/core` at
   the selected branch's recorded gitlink.
   Drivers can also be compiled explicitly against that stack:

   ```bash
   make compile MODEL=smoothing-example TARGET=fit_model_fem
   make compile MODEL=smoothing-example TARGET=fit_model_spline
   ```

   Accepted outer/core branch mappings are `develop-Splines` or historical
   `develop_splines` to `develop-splines`, `develop_RGCCA` to `develop-RGCCA`,
   and `develop_fPLS` to `develop-fPLS`. Bootstrap validates the mapping but
   always checks out the core commit recorded by the selected outer branch.
   The generated outer and core repositories remain attached to their mapped
   local branches and track the corresponding `origin` branches.

3. Run a suite through the strategy declared by the active profile:

   ```bash
   make run_test TEST_SUITE=smoothing-example TEST_NAME=all
   ```

   `run_test` first invokes the standard `compile` target with `MODEL` set to
   the selected `TEST_SUITE`, compiling all C++ mains for that suite.

Profiles can set `TEST_EXECUTION_STRATEGY` to `serial`, `parallel`, or `slurm`,
and `COMPILE_STRATEGY` to `local` or `slurm`.

For a small queue/batch check, pass `SMOKE_TEST=1`:

```bash
SMOKE_TEST=1 make run_test TEST_SUITE=smoothing-example TEST_NAME=all
```

### HPC/Slurm Quick Start

The `hpc-slurm` profile uses a repository-local Apptainer/Singularity image for
all C++ compilation and fit execution. A reviewer needs Bash, Make, Git, host
`Rscript`, `/usr/bin/time`, and either `apptainer` or `singularity`; real jobs
also require host `sbatch`. No host C++ compiler, Eigen, or Ipopt installation
is required.

```bash
make build PROFILE=hpc-slurm
SMOKE_TEST=1 make run_test PROFILE=hpc-slurm TEST_SUITE=smoothing-example TEST_NAME=all
```

The build pulls `docker://aldoclemente/fdapde-docker:latest` to
`libraries/fdapde-docker-latest.sif`, prepares `libraries/fdaPDE-cpp` and
`libraries/nlohmann-json`, and installs required R packages. When
`R_LIBS_USER` is unset, the profile uses the ignored `libraries/R` directory.
Generated builds, queues, results, images, and logs use the standard profile
paths.

The existing SIF is validated and reused without contacting the registry. To
update it, remove that file explicitly and rerun the build. The `latest` tag is
mutable, so fresh clones built at different times can receive different image
content; set `SINGULARITY_IMAGE_SOURCE` to an immutable digest URI for a
review-frozen run. Set `SINGULARITY_IMAGE` to override the local SIF path.
[Apptainer](https://apptainer.org/docs/user/latest/docker_and_oci.html) and
[SingularityCE](https://docs.sylabs.io/guides/latest/user-guide/singularity_and_docker.html)
both support pulling Docker/OCI images into reusable SIF files.

The currently published image metadata includes base R, but the testbench runs
R on the host because Make configuration, R package installation, queue
generation, aggregation, and plotting happen outside C++ execution. `make
build` installs the required R packages automatically. Slurm submission also
stays on the host.

If no supported container runtime is visible, load the cluster's Apptainer or
SingularityCE module and rerun the build. If the registry or network is
unavailable, place a previously prepared SIF at the configured path; it will be
reused without registry access. A fully offline build also needs the JSON and
fdaPDE clones plus the R library pre-staged under `libraries/`. Use
`SLURM_DRY_RUN=1` to inspect compile and test submissions without calling
`sbatch`.

### Smoothing Example

For repetition `r`, the truth on `[0,1]` is
`a1_r*sin(2*pi*x) + a2_r*sin(4*pi*x) + a3_r*sin(8*pi*x)`. The coefficients
are independent Gaussian draws with means `(1, 0.5, 0.25)` and standard
deviations `(0.1, 0.05, 0.025)`. One sampled coefficient vector and one noise
vector are shared by `SRPDE-FEM` and `SRPDE-SPLINES`. For observation locations
`x_i`, the configured SNR is
`mean((f(x_i) - mean(f(x_i)))^2) / sigma^2`, and noise is independent
`N(0, sigma^2)` with recorded seeds. The full suite uses 30 repetitions and:

- `vary_n_locs`: `20, 40, 80, 160, 320`, with `n_nodes=81` and `SNR=10`.
- `vary_n_nodes`: `11, 21, 41, 81, 161`, with `n_locs=120` and `SNR=10`.
- `vary_snr`: `1, 2, 5, 10, 20, 50`, with `n_locs=120` and `n_nodes=81`.

Normalized RMSE is
`sqrt(mean((f_hat-f)^2)) / sqrt(mean((f-mean(f))^2))` on 1001 common points.
Peak RAM is the maximum resident set size reported for each external C++ fit by
`/usr/bin/time`: bytes are divided by `1024^2` on macOS and KiB by `1024` on
Linux, so `peak_ram_mib` is always MiB. Wall time uses a monotonic clock. CPU
time is C++ process CPU seconds from `std::clock`; CPU usage is
`100 * CPU seconds / wall seconds`. Timings cover domain/model construction,
GCV, the final fit, and dense-grid evaluation. Both models evaluate the fitted
function at all 1001 grid points in C++ as part of `prediction_seconds`. The
driver records all four phases separately; `solver_seconds` is GCV plus the
final fit, while total wall time includes setup and evaluation for both models.

The suite follows `template_base`: each family declares an explicit `options`
list, expands only `test_options$varying_options` with `explode_options()`, and
writes one JSON file per level with `write_options_json()`. It then runs 30
`batch_*` repetitions, routes models through `utils/wrappers.R`, evaluates via
`fit_and_evaluate.R` and `models_evaluation.R`, aggregates through the shared
result loaders, and plots through shared `plot.aggregated_data()`.
The fixed GCV grid `10^seq(-6, 0, length.out=9)` is stored directly in every
option JSON and passed unchanged to both solvers.
Each experiment family writes `normalized_rmse.pdf`, `peak_ram_mib.pdf`, a
standalone `legend.pdf`, and a combined `timings.pdf`. The timing document
contains the boxplot and line pages for wall, setup, GCV, final-fit, solver,
prediction, and CPU times.

### Makefile

The `Makefile` provided in this repository includes several targets to automate common tasks related to installation, testing, building, and cleaning up the project environment. Below is a brief description of each target:

- `install_femR`: Installs the `glue` and `femR` packages through `src/installation/install_femR.R`.
- `install`: Installs repository R dependencies.
- `build`: Writes `.env`, creates generated directories, and installs dependencies.
- `compile`: Compiles one model using the profile compile strategy.
- `compile_all`: Compiles every model using the profile compile strategy.
- `run_test`: Runs one test using the profile execution strategy.
- `SMOKE_TEST=1 make run_test ...`: Runs the suite's reduced smoke grid.
- `clean_tmp`: Cleans temporary queue/log files.
- `clean`: Removes temporary files, logs, and R session files.
- `distclean`: Combines the `clean` target with removal of generated images, results, test data, temporary directories, and the repository-local `libraries/` directory. It prompts for confirmation before executing.

Refer to the [`Makefile`](./Makefile) for implementation details and additional customization options.

## Repository structure

```bash
.
├── LICENSE
├── Makefile
├── README.md
├── config.R
├── cpp
├── data
│   └── mesh
│       ├── ...
├── src
│   ├── installation
│   │   ├── install_fdaPDE.R
│   │   └── install_femR.R
│   └── utils
│       ├── cat.R
│       ├── config.R
│       ├── directories.R
│       ├── domain_utils.R
│       ├── error_metrics.R
│       ├── load_results_utils.R
│       ├── mesh_utils.R
│       ├── options.R
│       ├── plotting_utils.R
│       └── test_groups.R
└── tests
```

**Files**:

- **LICENSE**: GPL v3 License file specifying the terms and conditions for using the repository.
- **Makefile**: Makefile for automating build tasks or running commands.
- **README.md**: This documentation file providing an overview of the repository and its usage instructions.
- **config.R**: Runtime profiles and execution strategy defaults.
- **cpp/**: C++ model drivers plus local, Singularity, and Slurm compile helpers.

**Directories**:

- **data**: Directory storing general data files, including mesh data used in tests.
- **src**: Source code directory containing installation scripts and utility functions.
- **tests**: Directory for storing test scripts and related resources.
- **analysis**: Directory containing analysis-related scripts or resources.

## Authorship

This test bench repository is maintained by Pietro Donelli.

## License

This repository is licensed under the GPL v3 License. See the [LICENSE](./LICENSE) file for details.

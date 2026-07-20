# fdaPDE Methods Test Bench

## Overview

This repository serves as a test bench specifically designed for evaluating methods related to [fdaPDE](https://fdapde.github.io) (Physics-Informed Spatial and Functional Data Analysis). It provides a collection of utilities and scripts to facilitate the testing process, including model evaluation metrics computation, plot generation, and automation of tests with various parameter configurations.

## Capabilities

See [`docs/testbench-capabilities.md`](docs/testbench-capabilities.md) for the
full functionality map, including suite lifecycle, caching, plotting utilities,
ParaView palettes, and generated outputs.

## Repository Structure

```bash
.
├── LICENSE
├── Makefile
├── README.md
├── config.R
├── cpp
├── data/mesh
├── src
│   ├── installation
│   └── utils
└── tests
```

`cpp/` contains C++ drivers and compilation helpers, `src/` contains shared
testbench utilities, and `tests/` contains the individual suites and template.

## Main Commands

- `make help`: list the available commands;
- `make build PROFILE=<profile>`: prepare a runtime profile and its dependencies;
- `make compile MODEL=<suite>`: compile one suite explicitly;
- `make compile_all`: compile every available C++ driver;
- `make run_test TEST_SUITE=<suite> TEST_NAME=<test>`: compile and run a test;
- `make clean_test TEST_SUITE=<suite> TEST_NAME=<test-or-group>`: remove that
  test's generated results, images, and data;
- `make clean`: remove temporary files and logs;
- `make distclean`: remove all generated outputs and dependencies after
  confirmation.

## Configuration

Runtime profiles are defined in `config.R`. Choose one when preparing the
testbench:

```bash
make build PROFILE=<profile>
```

Compilation and test commands automatically use the profile selected by the
most recent build. After changing a profile in `config.R`, run its build command
again to apply the changes.

Important fields are:

- `TEST_EXECUTION_STRATEGY`: `serial`, `parallel`, `slurm`, or `pbs`;
- `COMPILE_STRATEGY`: `local` or `slurm`;
- `TESTBENCH_OUTPUT`: optional generated-output root;
- `FDAPDE_CPP_REPOSITORY`, `FDAPDE_CPP_BRANCH`, and `PATH_FDAPDE_CPP`;
- `FDAPDE_CPP_MANAGED`: whether the testbench may clone, fetch, and check out
  the configured fdaPDE repositories;
- `SINGULARITY_IMAGE`, `SINGULARITY_IMAGE_SOURCE`, and `DOCKER_IMAGE` for
  container profiles.

Every profile field can be overridden for one build with a
`TESTBENCH_<FIELD>` environment variable. For example, to use an existing local
fdaPDE-cpp checkout without modifying it:

```bash
TESTBENCH_PATH_FDAPDE_CPP=/absolute/path/to/fdaPDE-cpp \
TESTBENCH_FDAPDE_CPP_MANAGED=false \
make build PROFILE=macbook
```

The existing checkout needs an initialized `fdaPDE/core` submodule. With
`FDAPDE_CPP_MANAGED=false`, the build validates the checkout and leaves its Git
state unchanged. With the default `FDAPDE_CPP_MANAGED=true`, the
`libraries/fdaPDE-cpp` destination is cloned only when absent; later builds
reuse it and refresh the configured branches. `FDAPDE_CPP_REPOSITORY` may also
be an absolute path to a local Git repository when it should be used as the
source for the testbench-managed clone.

All builds prepare pinned nlohmann/json under `libraries/nlohmann-json` and
install the required host R packages. Generated dependencies, builds, queues,
logs, results, and images remain ignored.

## Runtime Profiles

### macOS: `macbook`

The `macbook` profile compiles on the host and runs option files locally. It
requires Bash, Make, Git, R, `Rscript`, `/usr/bin/time`, a C++20 compiler,
Eigen, and Ipopt when required by the selected driver. Its defaults expect
Homebrew GCC 15 at `/opt/homebrew/bin/g++-15` and Eigen at
`/opt/homebrew/opt/eigen/include/eigen3`. By default, builds contact GitHub to
refresh fdaPDE-cpp and may contact CRAN to install missing R packages.

The default execution strategy is `parallel`, which also requires GNU Parallel.
To disable parallel execution, set `TEST_EXECUTION_STRATEGY = "serial"` in the
`macbook` profile and rebuild.

```bash
make build PROFILE=macbook
make run_test TEST_SUITE=smoothing-example TEST_NAME=all
```

For a quick reduced run, prefix the run command with `SMOKE_TEST=1`.
Use `TESTBENCH_CXX` and `TESTBENCH_PATH_EIGEN_INCLUDE` when those installations
differ from the defaults.

### Windows: `windows`

Native Windows compilation is not supported. Run the testbench from a WSL2
Linux distribution with Docker Desktop installed, running, and integrated with
that distribution. Inside WSL2, install Bash, Make, Git, R, `Rscript`, GNU
Parallel, and the system requirements of the testbench's R packages. The first
build needs the Docker registry; managed dependency preparation also contacts
GitHub and may contact CRAN.

The `windows` profile runs option files in parallel. Docker supplies G++, Eigen,
Ipopt, and `/usr/bin/time` for C++ compilation, execution, and peak-RAM
telemetry. To disable parallel execution, set
`TEST_EXECUTION_STRATEGY = "serial"` in the `windows` profile and rebuild.

```bash
make build PROFILE=windows
make run_test TEST_SUITE=smoothing-example TEST_NAME=all
```

For a quick reduced run, prefix the run command with `SMOKE_TEST=1`.
The build pulls `aldoclemente/fdapde-docker:latest` only when absent and reuses
the local image afterward. Set `DOCKER_IMAGE` to select another compatible
local tag or immutable digest. Refresh the mutable default explicitly with:

```bash
docker pull aldoclemente/fdapde-docker:latest
```

The repository and configured output directory must be visible to Docker
Desktop through WSL2.

### HPC/Slurm: `hpc-slurm`

The `hpc-slurm` profile requires Bash, Make, Git, host R and `Rscript`,
`/usr/bin/time`, Slurm with `sbatch`, and either Apptainer or SingularityCE.
The container supplies the C++ compiler, Eigen, and Ipopt; the host performs R
orchestration, plotting, and Slurm submission. The first build requires access
to the configured image registry; managed dependency preparation also contacts
GitHub and may contact CRAN.

```bash
make build PROFILE=hpc-slurm
make run_test TEST_SUITE=smoothing-example TEST_NAME=all
```

For a quick reduced run, prefix the run command with `SMOKE_TEST=1`.
The default build pulls `docker://aldoclemente/fdapde-docker:latest` to
`libraries/fdapde-docker-latest.sif` only when that file is absent. To reuse an
existing SIF elsewhere without pulling, select it during the build:

```bash
SINGULARITY_IMAGE=/absolute/path/to/fdapde.sif make build PROFILE=hpc-slurm
```

Set `SINGULARITY_IMAGE_SOURCE` to an immutable digest URI for a frozen image.
Inspect compile and test submissions without scheduling jobs with:

```bash
SLURM_DRY_RUN=1 make run_test TEST_SUITE=smoothing-example TEST_NAME=all
```

### HPC/Torque: `hpc-torque`

The `hpc-torque` profile targets Torque/PBS clusters such as DMAT's KAMI. It
compiles on the host and submits test configurations with `qsub`. By default, ordinary workers use
one CPU, 8 GB, and four hours. Multi-threaded tests request one complete CPU
node (96 CPUs and 512 GB). At most 15 worker jobs are submitted; configurations
are distributed across them and run sequentially within each worker.

```bash
make build PROFILE=hpc-torque
make run_test TEST_SUITE=smoothing-example TEST_NAME=all
```

The profile assumes host R, a C++20 compiler, Eigen, and any solver libraries
needed by the suite. Override paths during the build when the cluster's installations
differ, for example `TESTBENCH_PATH_EIGEN_INCLUDE=/path/to/eigen3`.

Resource requests can be overridden per run with `PBS_CPUS`, `PBS_MEM`,
`PBS_TIME`, their `PBS_MULTI_*` counterparts, and `PBS_MAX_JOBS`. Optional
`PBS_QUEUE` and `PBS_ACCOUNT` values are passed to `qsub`. Preview submissions
without scheduling jobs with:

```bash
PBS_DRY_RUN=1 make run_test TEST_SUITE=smoothing-example TEST_NAME=all
```

The GPU node is intentionally not configured because its PBS resource syntax
has not yet been established.

## Test Suites

The suite layout and execution contract are documented in
[`tests/README.md`](tests/README.md). The bundled SRPDE example has its own
scientific and output documentation in
[`tests/smoothing-example/README.md`](tests/smoothing-example/README.md).

## Authorship

This test bench repository is maintained by Pietro Donelli.

## License

This repository is licensed under the GPL v3 License. See the [LICENSE](./LICENSE) file for details.

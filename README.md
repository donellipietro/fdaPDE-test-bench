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

   Local C++ suites also need a compiled model. Set `PATH_FDAPDE_CPP` to a
   checkout containing `fdaPDE/models.h`; on macOS, Homebrew GCC, Eigen, and
   Ipopt worked for the bundled example:

   ```bash
   PATH_FDAPDE_CPP=/path/to/fdaPDE-cpp \
   PATH_EIGEN_INCLUDE=/opt/homebrew/opt/eigen/include/eigen3 \
   CXX=/opt/homebrew/bin/g++-15 \
   make build PROFILE=macbook

   PATH_IPOPT_INCLUDE=/opt/homebrew/opt/ipopt/include/coin-or \
   PATH_IPOPT_LIB=/opt/homebrew/opt/ipopt/lib \
   LDLIBS=-lipopt \
   make compile MODEL=fPCA-2D
   ```

3. Run a suite through the strategy declared by the active profile:

   ```bash
   make run_test TEST_SUITE=example_data_decomposition TEST_NAME=test1
   ```

Profiles can set `TEST_EXECUTION_STRATEGY` to `serial`, `parallel`, or `slurm`,
and `COMPILE_STRATEGY` to `local` or `slurm`.

For a small queue/batch check, pass `SMOKE_TEST=1`:

```bash
SMOKE_TEST=1 make run_test TEST_SUITE=example_data_decomposition TEST_NAME=test1
```

### Makefile

The `Makefile` provided in this repository includes several targets to automate common tasks related to installation, testing, building, and cleaning up the project environment. Below is a brief description of each target:

- `install_femR`: Installs the `femR` package by executing the `install_femR.R` script located in the `src/installation/` directory.
- `install`: Installs repository R dependencies.
- `build`: Writes `.env`, creates generated directories, and installs dependencies.
- `compile`: Compiles one model using the profile compile strategy.
- `compile_all`: Compiles every model using the profile compile strategy.
- `run_test`: Runs one test using the profile execution strategy.
- `SMOKE_TEST=1 make run_test ...`: Runs the suite's reduced smoke grid.
- `clean_tmp`: Cleans temporary queue/log files.
- `clean`: Removes temporary files, logs, and R session files.
- `distclean`: Combines the `clean` target with further cleanup actions, including the removal of additional generated files like images and results. It prompts for confirmation before executing to avoid accidental deletion.

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

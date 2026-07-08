# Test Suite Guide

Each test suite lives in `tests/<suite_name>/` and is run through the root
Makefile:

```bash
make run_test TEST_SUITE=example_data_decomposition TEST_NAME=test1
```

`make run_test` uses the active profile from `config.R`: `serial`, `parallel`,
or `slurm`.

## Suite Layout

```text
tests/<suite_name>/
├── config.R
├── main.R
├── aggregate_results.R
├── inspect_results.R              # optional, used by make inspect_results
└── utils/
    ├── adjust_results.R
    ├── fit_and_evaluate.R
    ├── generate_data.R
    ├── generate_options.R
    ├── load_qualitative_results.R # optional, used by qualitative inspection
    ├── models_evaluation.R
    ├── plot_results.R             # optional, used by reports/inspection
    └── wrappers.R
```

Only `config.R`, `main.R`, `aggregate_results.R`, and
`utils/generate_options.R` are required by the generic runners. The other files
are either sourced by the suite's own `main.R` or used by inspection/reporting
scripts.

## Bundled Suites

- `example_data_decomposition`: runnable fPCA-oriented example.
- `template_base`: copy this when starting a new suite, then fill in the
  placeholders.

## Execution Flow

1. `src/init.R` sources `tests/<suite>/utils/generate_options.R`.
2. `generate_options(test_suite, test_name, path_queue)` writes JSON option
   files into `tmp/queue/<suite>/<test_name>/`.
3. The selected runner calls `tests/<suite>/main.R <test_name> <option_file>`
   once per JSON file.
4. After all options finish, the runner calls
   `tests/<suite>/aggregate_results.R <test_name>`.

Use `tests/<suite>/config.R` for suite names, default test names, and local run
flags. Use the root `config.R` for machine paths and execution strategy.

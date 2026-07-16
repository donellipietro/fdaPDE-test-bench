---
name: fdapde-test-bench
description: Use when working in the fdaPDE test bench repository: building runtime profiles, compiling C++ drivers, running/adding test suites, handling option queues, cached batch data, result aggregation, plotting utilities, ParaView palettes, or generated outputs.
---

# fdaPDE Test Bench

Use this skill inside `fdaPDE-test-bench` or when the user asks about its
runtime profiles, suites, result flow, plotting, or generated outputs.

## Read First

- For the full capability map, read
  `docs/testbench-capabilities.md`.
- For setup, profiles, and commands, read `README.md`.
- For suite structure and execution flow, read `tests/README.md`.
- For the bundled SRPDE example, read `tests/smoothing-example/README.md`.

## Core Workflow

- Build/select a runtime profile with `make build PROFILE=<profile>`.
- Compile suite drivers with `make compile MODEL=<suite>` or
  `make compile MODEL=<suite> TARGET=<executable>`.
- Run tests with `make run_test TEST_SUITE=<suite> TEST_NAME=<test-or-group>`.
- Use `SMOKE_TEST=1` for quick reduced runs.
- Clean generated outputs with `make clean_test TEST_SUITE=<suite> TEST_NAME=<test-or-group>`.

## What Is Available

- Runtime profiles: `macbook`, `windows`, `hpc-slurm`.
- Execution modes: serial, GNU Parallel, Slurm arrays.
- Standard suite flow: `generate_options.R` -> queued JSON options ->
  `main.R` batches -> fitted model/evaluation `.RData` files ->
  `aggregate_results.R`.
- Batch caching: complete matching batches can be skipped; matching generated
  data can be reused when fits/evaluations need refreshing.
- Shared utilities: directories/options/config, domain/mesh import and
  generation, data generators, error metrics, memory/timing telemetry, result
  loading, and aggregate plotting.
- Plotting: standard ggplot themes, point/curve/field plots, grouped
  boxplots/violins/lines, aggregated result pages.
- ParaView palettes: `plot.field_tile(..., palette = "<name>")`;
  `paraview_colormap_names()` lists the 199 bundled presets.

## Editing Guidance

- Start new suites from `tests/template_base`.
- Keep generated outputs under configured output/tmp directories; do not commit
  queue, log, result, image, data, dependency, or build artifacts.
- Before changing runners or caching, trace `Makefile`, `src/init.R`, the suite
  `main.R`, and `src/utils/load_results_utils.R`.
- Prefer existing helpers in `src/utils` and existing suite patterns over new
  abstractions.

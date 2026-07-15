# SRPDE Smoothing Example

This suite compares `SRPDE-FEM` and `SRPDE-SPLINES` on paired reproducible 1D
smoothing experiments. Build one runtime profile as documented in the root
README, then run the full suite with:

```bash
make run_test TEST_SUITE=smoothing-example TEST_NAME=all
```

Prefix that command with `SMOKE_TEST=1` for a quick reduced run.
The suite requires Eigen but does not require Ipopt.

## Data-Generating Process

For repetition `r`, the truth on `[0,1]` is
`a1_r*sin(2*pi*x) + a2_r*sin(4*pi*x) + a3_r*sin(8*pi*x)`. The coefficients are
independent Gaussian draws with means `(1, 0.5, 0.25)` and standard deviations
`(0.1, 0.05, 0.025)`. One sampled coefficient vector and one noise vector are
shared by `SRPDE-FEM` and `SRPDE-SPLINES`.

For observation locations `x_i`, the configured SNR is
`mean((f(x_i) - mean(f(x_i)))^2) / sigma^2`. Noise is independent
`N(0, sigma^2)` with recorded seeds.

## Experiments

The full suite uses 30 repetitions for every cell:

- `vary_n_locs`: `20, 40, 80, 160, 320`, with `n_nodes=81` and `SNR=10`;
- `vary_n_nodes`: `11, 21, 41, 81, 161`, with `n_locs=120` and `SNR=10`;
- `vary_snr`: `1, 2, 5, 10, 20, 50`, with `n_locs=120` and `n_nodes=81`.

The fixed GCV grid is `10^seq(-6, 0, length.out=9)` and is passed unchanged to
both solvers.

## Metrics

Normalized RMSE is
`sqrt(mean((f_hat-f)^2)) / sqrt(mean((f-mean(f))^2))` on 1001 common points.

Peak RAM is the maximum resident set size reported for each external C++ fit by
`/usr/bin/time`: bytes are divided by `1024^2` on macOS and KiB by `1024` on
Linux, so `peak_ram_mib` is always MiB. Docker runs measure `/usr/bin/time`
inside the container.

Wall time uses a monotonic clock. CPU time is C++ process CPU seconds from
`std::clock`; CPU usage is `100 * CPU seconds / wall seconds`. Timings cover
domain/model construction, GCV, the final fit, and dense-grid evaluation. Both
models evaluate all 1001 grid points in C++ as part of `prediction_seconds`.
`solver_seconds` is GCV plus the final fit, while total wall time includes setup
and evaluation.

## Testbench Flow And Outputs

Each family defines an explicit `options` list, expands only
`test_options$varying_options` with `explode_options()`, and writes one JSON file
per level with `write_options_json()`. Repetitions use the standard wrapper,
evaluation, result-loader, and `plot.aggregated_data()` flow.

Each experiment family writes `normalized_rmse.pdf`, `peak_ram_mib.pdf`, a
standalone `legend.pdf`, and a combined `timings.pdf`. The timing document
contains boxplot and line pages for wall, setup, GCV, final-fit, solver,
prediction, and CPU times.

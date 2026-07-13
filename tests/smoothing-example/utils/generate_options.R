# = ========================================================================== =
# - Script: generate_options.R
# - Desc: Generates JSON option files for the SRPDE smoothing experiments.
# = ========================================================================== =

## Function: generate_options
# - Args:
#   * test_suite: name of the calling test suite
#   * name_main_test: one of vary_n_locs, vary_n_nodes, or vary_snr
#   * path_queue: directory where JSON option files are written
# - Desc:
#   Defines one explicit one-factor experiment, expands only its varying option,
#   and writes one JSON file per level using the standard testbench utilities.
generate_options <- function(test_suite, name_main_test, path_queue) {
  ## Create the queue directory if it does not exist yet
  mkdir(c(path_queue))

  ## Models compared in every experiment
  # - model_names: internal indexing and binary selection
  # - model_labels: plot labels
  model_names <- c("SRPDE-FEM", "SRPDE-SPLINES")
  model_labels <- model_names
  model_colors <- c("#0072B2", "#D55E00")

  ## Options common to all three experiments
  n_reps <- if (SMOKE_TEST) 2L else 30L
  n_evaluation_points <- 1001L
  seed <- 141200L

  ## Sine coefficients are sampled once per repetition and shared by both models
  # - means retain the reference mixture used by the original fixed truth
  # - standard deviations are 10 percent of the corresponding means
  coefficient_mean <- c(1, 0.5, 0.25)
  coefficient_sd <- c(0.1, 0.05, 0.025)

  ## Fixed GCV candidate grid passed unchanged to both normalized solvers
  lambda_grid <- 10^seq(-6, 0, length.out = 9L)
  gcv_probes <- 20L

  switch(name_main_test,
    vary_n_locs = {
      ## Vary observation count; hold mesh resolution and SNR fixed
      options <- list(
        model_names = model_names,
        model_labels = model_labels,
        model_colors = model_colors,
        cpp_script = "smoothing-example",
        test_options = list(
          n_reps = n_reps,
          varying_options = "n_locs",
          threading = "single"
        ),
        dimensions = list(
          n_nodes = 81L,
          n_locs = if (SMOKE_TEST) 40L else c(40L, 80L, 160L),
          n_evaluation_points = n_evaluation_points
        ),
        data = list(
          coefficient_mean = coefficient_mean,
          coefficient_sd = coefficient_sd
        ),
        noise = list(
          SNR = 10,
          seed = seed
        ),
        regularization = list(
          lambda_grid = lambda_grid,
          gcv_probes = gcv_probes
        )
      )

      ## File naming policy: include the varying observation count
      name_fun <- function(opts_i, comb_row) {
        paste(name_main_test, "nl", sprintf("%04d", comb_row$n_locs), sep = "_")
      }

      ## Expand only n_locs, then write one JSON file per level
      options_list <- explode_options(
        options,
        by = options$test_options$varying_options,
        name_fun = name_fun
      )
      write_options_json(options_list, dir = path_queue, name_field = "name_test")
    },
    vary_n_nodes = {
      ## Vary mesh/basis resolution; hold locations and SNR fixed
      options <- list(
        model_names = model_names,
        model_labels = model_labels,
        model_colors = model_colors,
        cpp_script = "smoothing-example",
        test_options = list(
          n_reps = n_reps,
          varying_options = "n_nodes",
          threading = "single"
        ),
        dimensions = list(
          n_nodes = if (SMOKE_TEST) 21L else c(21L, 41L, 81L),
          n_locs = 120L,
          n_evaluation_points = n_evaluation_points
        ),
        data = list(
          coefficient_mean = coefficient_mean,
          coefficient_sd = coefficient_sd
        ),
        noise = list(
          SNR = 10,
          seed = seed
        ),
        regularization = list(
          lambda_grid = lambda_grid,
          gcv_probes = gcv_probes
        )
      )

      ## File naming policy: include the varying mesh/basis resolution
      name_fun <- function(opts_i, comb_row) {
        paste(name_main_test, "nn", sprintf("%04d", comb_row$n_nodes), sep = "_")
      }

      ## Expand only n_nodes, then write one JSON file per level
      options_list <- explode_options(
        options,
        by = options$test_options$varying_options,
        name_fun = name_fun
      )
      write_options_json(options_list, dir = path_queue, name_field = "name_test")
    },
    vary_snr = {
      ## Vary SNR; hold locations and mesh/basis resolution fixed
      options <- list(
        model_names = model_names,
        model_labels = model_labels,
        model_colors = model_colors,
        cpp_script = "smoothing-example",
        test_options = list(
          n_reps = n_reps,
          varying_options = "SNR",
          threading = "single"
        ),
        dimensions = list(
          n_nodes = 81L,
          n_locs = 120L,
          n_evaluation_points = n_evaluation_points
        ),
        data = list(
          coefficient_mean = coefficient_mean,
          coefficient_sd = coefficient_sd
        ),
        noise = list(
          SNR = if (SMOKE_TEST) 2 else c(2, 5, 10, 20),
          seed = seed
        ),
        regularization = list(
          lambda_grid = lambda_grid,
          gcv_probes = gcv_probes
        )
      )

      ## File naming policy: include the varying signal-to-noise ratio
      name_fun <- function(opts_i, comb_row) {
        paste(name_main_test, "snr", sprintf("%.1f", comb_row$SNR), sep = "_")
      }

      ## Expand only SNR, then write one JSON file per level
      options_list <- explode_options(
        options,
        by = options$test_options$varying_options,
        name_fun = name_fun
      )
      write_options_json(options_list, dir = path_queue, name_field = "name_test")
    },
    {
      stop(paste("The test", name_main_test, "does not exist"))
    }
  )
}

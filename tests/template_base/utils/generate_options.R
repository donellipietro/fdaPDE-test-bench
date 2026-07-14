# = ========================================================================== =
# - Script: generate_options.R
# - Desc: Generates JSON option files for test configurations.
# = ========================================================================== =

## Function: generate_options(test_suite, name_main_test, path_queue)
# - Args:
#   * test_suite: name of the calling test suite (used for directory structure)
#   * name_main_test: identifier of the specific test to generate options for
#   * path_queue: directory where JSON files will be written
# - Desc:
#   Defines model parameters, expands selected grid options, and writes the
#   resulting combinations to JSON files ready for execution.
generate_options <- function(test_suite, name_main_test, path_queue) {
  ## Create the directory (if it does not exist yet)
  mkdir(c(path_queue))

  ## Names of the models you want to compare
  # - model_names: used for indexing (no spaces, please)
  # - model_labels: used for plotting
  model_names <- c("model_a")
  model_labels <- c("Model A")

  ## Define the color palette
  model_colors <- brewer.pal(max(3, length(model_labels)), "Set1")[seq_along(model_labels)]

  ## Options that you want to be common across tests
  lambda_grid <- 10^seq(-12, 1, by = 1)
  n_reps <- 1

  switch(name_main_test,
    test1 = {
      ## Set the desired options
      options <- list(
        model_names = model_names,
        model_labels = model_labels,
        model_colors = model_colors,
        cpp_script = "model-name",
        test_options = list(
          n_reps = n_reps,
          varying_options = c("n_nodes", "n_stat_units", "NSR")
        ),
        domain_and_locations = list(
          name_mesh = "unit_square",
          locs_eq_nodes = TRUE
        ),
        dimensions = list(
          n_nodes = 100,
          n_stat_units = 50,
          n_nodes_HR_grid = 1000
        ),
        model_options = list(
          ## ....
        ),
        data = list(
          ## ....
        ),
        noise = list(
          NSR = 0
        ),
        regularization = list(
          lambda_grid = lambda_grid
        )
      )

      ## File naming policy
      name_fun <- function(opts_i, comb_row) {
        glue::glue(
          ## Include all the varying options!
          "{name_main_test}_nsr_{sprintf('%.3f', comb_row$NSR)}_",
          "nn_{sprintf('%04d', comb_row$n_nodes)}_",
          "nsu_{sprintf('%04d', comb_row$n_stat_units)}"
          # Add `_nl_{sprintf('%04d', comb_row$n_locs)}` when n_locs varies.
        )
      }

      ## Expand ONLY the varying options
      options_list <- explode_options(
        options,
        by = options$test_options$varying_options,
        name_fun = name_fun
      )

      ## Write JSON files
      write_options_json(
        options_list,
        dir = path_queue,
        name_field = "name_test"
      )
    },
    {
      stop(glue::glue("The test {name_main_test} does not exist"))
    }
  )
}

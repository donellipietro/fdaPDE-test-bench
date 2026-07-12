generate_options <- function(test_suite, name_main_test, path_queue) {
  smoke <- tolower(Sys.getenv("SMOKE_TEST", "0")) %in% c("1", "true", "yes", "y")
  spec <- smoothing_experiment_spec(smoke)
  values <- spec$grids[[name_main_test]]
  if (is.null(values)) stop("unknown smoothing experiment family: ", name_main_test)

  options_list <- list()
  index <- 1L
  for (value in values) {
    for (repetition in seq_len(spec$repetitions)) {
      dimensions <- spec$defaults
      if (name_main_test == "vary_n_locs") dimensions$n_locs <- as.integer(value)
      if (name_main_test == "vary_n_nodes") dimensions$n_nodes <- as.integer(value)
      if (name_main_test == "vary_snr") dimensions$snr <- as.numeric(value)

      value_label <- gsub("\\.", "p", format(value, trim = TRUE, scientific = FALSE))
      options_list[[index]] <- list(
        name_test = sprintf("%s_value_%s_rep_%02d", name_main_test, value_label, repetition),
        cpp_script = "smoothing-example",
        family = name_main_test,
        level = as.numeric(value),
        repetition = repetition,
        seed = spec$seed_base + repetition,
        expected_repetitions = spec$repetitions,
        smoke_test = smoke,
        dimensions = c(dimensions, list(evaluation_points = spec$evaluation_points)),
        regularization = list(
          lambda_exponents = spec$lambda_exponents,
          gcv_probes = spec$gcv_probes
        ),
        test_options = list(threading = "single")
      )
      index <- index + 1L
    }
  }

  write_options_json(options_list, path_queue)
}

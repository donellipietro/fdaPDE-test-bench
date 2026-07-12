generate_options <- function(test_suite, name_main_test, path_queue) {
  smoke <- tolower(Sys.getenv("SMOKE_TEST", "0")) %in% c("1", "true", "yes", "y")
  spec <- smoothing_experiment_spec(smoke)
  values <- spec$grids[[name_main_test]]
  if (is.null(values)) stop("unknown smoothing experiment family: ", name_main_test)

  varying_option <- sub("^vary_", "", name_main_test)
  options_list <- lapply(values, function(value) {
    dimensions <- spec$defaults
    dimensions[[varying_option]] <- value
    value_label <- gsub("\\.", "p", format(value, trim = TRUE, scientific = FALSE))
    list(
      name_test = sprintf("%s_%s_%s", name_main_test, varying_option, value_label),
      cpp_script = "smoothing-example",
      family = name_main_test,
      model_names = c("fem", "spline"),
      model_labels = c("FEM", "Spline"),
      model_colors = c("#0072B2", "#D55E00"),
      dimensions = c(dimensions, list(evaluation_points = spec$evaluation_points)),
      regularization = list(
        lambda_exponents = spec$lambda_exponents,
        gcv_probes = spec$gcv_probes
      ),
      noise = list(seed_base = spec$seed_base),
      test_options = list(
        n_reps = spec$repetitions,
        varying_options = varying_option,
        threading = "single",
        smoke_test = smoke
      )
    )
  })

  write_options_json(options_list, path_queue)
}

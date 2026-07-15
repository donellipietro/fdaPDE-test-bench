# = ========================================================================== =
# - Script: wrappers.R
# - Desc: Exports one smoothing data set, runs the selected C++ SRPDE driver,
#         and returns results in the standard testbench model structure.
# = ========================================================================== =

## Function: fit_model
# - Args:
#   * model_name: SRPDE-FEM or SRPDE-SPLINES
#   * domain: unused; retained for the standard wrapper signature
#   * data: generated locations, response, evaluation grid, and seed
#   * path_list: standard testbench data, result, log, and binary paths
#   * test_options: one expanded option JSON plus batch_index
# - Desc:
#   Routes FEM and spline to distinct binaries, checks the binary-reported
#   discretization, and collects timing, RAM, fit, and prediction outputs.
fit_model <- function(model_name, domain, data, path_list, test_options) {
  solver_name <- switch(
    model_name,
    "SRPDE-FEM" = "fem",
    "SRPDE-SPLINES" = "spline",
    stop(glue::glue("The model {model_name} does not exist"))
  )

  ## Paths ----
  prefix <- glue::glue("batch_{test_options$batch_index}_{model_name}")
  locations_file <- file.path(path_list$tmp_data, glue::glue("{prefix}_locations.csv"))
  response_file <- file.path(path_list$tmp_data, glue::glue("{prefix}_response.csv"))
  evaluation_file <- file.path(path_list$tmp_data, glue::glue("{prefix}_evaluation.csv"))
  prediction_file <- file.path(path_list$tmp_results, glue::glue("{prefix}_prediction.csv"))
  telemetry_file <- file.path(path_list$tmp_results, glue::glue("{prefix}_telemetry.json"))
  params_file <- file.path(path_list$tmp_data, glue::glue("{prefix}_params.json"))
  log_file <- file.path(path_list$logs, glue::glue("log_{test_options$name_test}.txt"))

  ## Write paired data for the C++ driver ----
  write.csv(data.frame(x = data$locations[, 1]), locations_file, row.names = FALSE)
  write.csv(data.frame(y = data$response[, 1]), response_file, row.names = FALSE)
  write.csv(data.frame(x = data$evaluation[, 1]), evaluation_file, row.names = FALSE)

  ## Write JSON arguments for the selected C++ solver ----
  params <- list(
    n_nodes = test_options$dimensions$n_nodes,
    gcv_probes = test_options$regularization$gcv_probes,
    gcv_seed = data$seed + 100000L,
    lambda_grid = test_options$regularization$lambda_grid,
    locations_file = locations_file,
    response_file = response_file,
    evaluation_file = evaluation_file,
    prediction_file = prediction_file,
    metrics_file = telemetry_file
  )
  write_json(params, params_file, auto_unbox = TRUE, digits = NA, pretty = TRUE)

  ## Run the model-specific binary and measure its peak resident memory ----
  binary <- file.path(path_list$cpp_script, glue::glue("fit_model_{solver_name}"))
  runner <- file.path(path_list$repo, "cpp", "run.sh")
  command <- glue::glue(
    "{shQuote(runner)} --quiet -- {shQuote(binary)} {shQuote(params_file)} ",
    ">> {shQuote(log_file)} 2>&1"
  )
  run_stats <- system_with_memory(command, ignore.stdout = IGNORE_CPP_OUTPUT)
  if (!identical(run_stats$status, 0L)) {
    stop(glue::glue("C++ fit failed; see {log_file}"))
  }
  cat(glue::glue(
    "finished after {run_stats$execution_time} ",
    "{attr(run_stats$execution_time, 'units')}\n",
    .trim = FALSE
  ))
  if (!is.finite(run_stats$peak_ram_mib)) {
    stop(glue::glue("peak RAM measurement unavailable for {model_name}"))
  }

  ## Load and validate outputs ----
  telemetry <- fromJSON(telemetry_file)
  if (!identical(telemetry$discretization, solver_name)) {
    stop(glue::glue(
      "binary/model mismatch: requested {model_name} ",
      "but driver reported {telemetry$discretization}"
    ))
  }
  prediction <- read.csv(prediction_file, header = TRUE)[[1]]
  if (length(prediction) != length(data$truth_evaluation)) stop("prediction grid length mismatch")

  ## Return the standard testbench model object ----
  list(
    results = list(
      prediction = prediction,
      peak_ram_mib = run_stats$peak_ram_mib,
      execution_time = telemetry$wall_seconds,
      cpu_seconds = telemetry$cpu_seconds,
      cpu_usage_percent = telemetry$cpu_usage_percent,
      setup_seconds = telemetry$setup_seconds,
      gcv_seconds = telemetry$gcv_seconds,
      final_fit_seconds = telemetry$final_fit_seconds,
      solver_seconds = telemetry$gcv_seconds + telemetry$final_fit_seconds,
      prediction_seconds = telemetry$prediction_seconds,
      n_basis = telemetry$n_basis,
      linear_system_dimension = telemetry$linear_system_dimension,
      lambda = telemetry$lambda,
      gcv = telemetry$gcv
    ),
    model_traits = list(is_functional = TRUE, has_interpolator = TRUE)
  )
}

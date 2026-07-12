fit_model <- function(model_name, domain, data, path_list, test_options) {
  if (!model_name %in% c("fem", "spline")) stop("unknown smoothing model: ", model_name)

  prefix <- paste0("batch_", test_options$batch_index, "_", model_name)
  locations_file <- file.path(path_list$tmp_data, paste0(prefix, "_locations.csv"))
  response_file <- file.path(path_list$tmp_data, paste0(prefix, "_response.csv"))
  evaluation_file <- file.path(path_list$tmp_data, paste0(prefix, "_evaluation.csv"))
  prediction_file <- file.path(path_list$tmp_results, paste0(prefix, "_prediction.csv"))
  telemetry_file <- file.path(path_list$tmp_results, paste0(prefix, "_telemetry.json"))
  params_file <- file.path(path_list$tmp_data, paste0(prefix, "_params.json"))
  log_file <- file.path(path_list$logs, paste0(test_options$name_test, "_", prefix, ".log"))

  write.csv(data.frame(x = data$locations[, 1]), locations_file, row.names = FALSE)
  write.csv(data.frame(y = data$response[, 1]), response_file, row.names = FALSE)
  write.csv(data.frame(x = data$evaluation[, 1]), evaluation_file, row.names = FALSE)

  params <- list(
    n_nodes = test_options$dimensions$n_nodes,
    gcv_probes = test_options$regularization$gcv_probes,
    gcv_seed = data$seed + 100000L,
    lambda_grid = 10^test_options$regularization$lambda_exponents / nrow(data$locations),
    locations_file = locations_file,
    response_file = response_file,
    evaluation_file = evaluation_file,
    prediction_file = prediction_file,
    metrics_file = telemetry_file
  )
  write_json(params, params_file, auto_unbox = TRUE, digits = NA, pretty = TRUE)

  binary <- file.path(path_list$cpp_script, paste0("fit_model_", model_name))
  command <- paste(shQuote(binary), shQuote(params_file), ">", shQuote(log_file), "2>&1")
  run_stats <- system_with_memory(command, ignore.stdout = IGNORE_CPP_OUTPUT)
  if (!identical(run_stats$status, 0L)) stop("C++ fit failed; see ", log_file)
  if (!is.finite(run_stats$peak_ram_mib)) stop("peak RAM measurement unavailable for ", model_name)

  telemetry <- fromJSON(telemetry_file)
  prediction <- read.csv(prediction_file, header = TRUE)[[1]]
  model <- list(
    results = list(
      prediction = prediction,
      peak_ram_mib = run_stats$peak_ram_mib,
      execution_time = telemetry$wall_seconds,
      cpu_seconds = telemetry$cpu_seconds,
      cpu_usage_percent = telemetry$cpu_usage_percent,
      lambda = telemetry$lambda,
      gcv = telemetry$gcv
    ),
    model_traits = list(is_functional = TRUE, has_interpolator = TRUE)
  )
  model
}

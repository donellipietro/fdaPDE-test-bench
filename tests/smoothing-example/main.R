suppressMessages(library(jsonlite))

source("src/utils/directories.R")
source("tests/smoothing-example/config.R")

truth_function <- function(x) {
  sin(2 * pi * x) + 0.5 * sin(4 * pi * x) + 0.25 * sin(8 * pi * x)
}

normalized_rmse <- function(estimate, truth) {
  sqrt(mean((estimate - truth)^2)) / sqrt(mean((truth - mean(truth))^2))
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("usage: main.R <test-name> <option-file>")

name_main_test <- args[1]
option_file <- args[2]
cfg <- load_config()
queue_file <- file.path(cfg$PATH_QUEUE, test_suite, name_main_test, option_file)
options <- fromJSON(queue_file, simplifyVector = TRUE)

work_dir <- file.path(cfg$PATH_TMP_DATA, test_suite, name_main_test, options$name_test)
result_dir <- file.path(cfg$PATH_RESULTS, test_suite, name_main_test, options$name_test)
log_dir <- file.path(cfg$PATH_LOGS, test_suite, name_main_test)
dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)

n_locs <- options$dimensions$n_locs
n_nodes <- options$dimensions$n_nodes
snr <- options$dimensions$snr
locations <- seq(0, 1, length.out = n_locs)
truth_observed <- truth_function(locations)
signal_variance <- mean((truth_observed - mean(truth_observed))^2)
noise_sigma <- sqrt(signal_variance / snr)
set.seed(options$seed)
response <- truth_observed + rnorm(n_locs, sd = noise_sigma)
evaluation <- seq(0, 1, length.out = options$dimensions$evaluation_points)
truth_evaluation <- truth_function(evaluation)

write.csv(data.frame(x = locations), file.path(work_dir, "locations.csv"), row.names = FALSE)
write.csv(data.frame(y = response), file.path(work_dir, "response.csv"), row.names = FALSE)
write.csv(data.frame(x = evaluation), file.path(work_dir, "evaluation.csv"), row.names = FALSE)

lambda_grid <- 10^options$regularization$lambda_exponents / n_locs
rows <- list()
for (discretization in c("fem", "spline")) {
  prediction_file <- file.path(work_dir, paste0("prediction_", discretization, ".csv"))
  telemetry_file <- file.path(work_dir, paste0("telemetry_", discretization, ".json"))
  params_file <- file.path(work_dir, paste0("params_", discretization, ".json"))
  params <- list(
    n_nodes = n_nodes,
    gcv_probes = options$regularization$gcv_probes,
    gcv_seed = options$seed + 100000L,
    lambda_grid = lambda_grid,
    locations_file = file.path(work_dir, "locations.csv"),
    response_file = file.path(work_dir, "response.csv"),
    evaluation_file = file.path(work_dir, "evaluation.csv"),
    prediction_file = prediction_file,
    metrics_file = telemetry_file
  )
  write_json(params, params_file, auto_unbox = TRUE, digits = NA, pretty = TRUE)

  binary <- file.path(cfg$PATH_BUILD, "smoothing-example", paste0("fit_model_", discretization))
  log_file <- file.path(log_dir, paste0(options$name_test, "_", discretization, ".log"))
  status <- system2(binary, params_file, stdout = log_file, stderr = log_file)
  if (!identical(status, 0L)) stop("C++ fit failed; see ", log_file)

  telemetry <- fromJSON(telemetry_file)
  prediction <- read.csv(prediction_file, header = TRUE)[[1]]
  if (length(prediction) != length(truth_evaluation)) stop("prediction grid length mismatch")

  rows[[discretization]] <- data.frame(
    family = options$family,
    level = options$level,
    repetition = options$repetition,
    seed = options$seed,
    smoke_test = options$smoke_test,
    n_locs = n_locs,
    n_nodes = n_nodes,
    snr = snr,
    signal_variance = signal_variance,
    noise_sigma = noise_sigma,
    discretization = discretization,
    source_ref = if (discretization == "fem") cfg$FDAPDE_CPP_FEM_REF else cfg$FDAPDE_CPP_SPLINE_REF,
    wall_seconds = telemetry$wall_seconds,
    cpu_seconds = telemetry$cpu_seconds,
    cpu_usage_percent = telemetry$cpu_usage_percent,
    lambda = telemetry$lambda,
    gcv = telemetry$gcv,
    normalized_rmse = normalized_rmse(prediction, truth_evaluation),
    stringsAsFactors = FALSE
  )

  if (options$repetition == 1L) {
    write.csv(
      data.frame(x = evaluation, truth = truth_evaluation, estimate = prediction),
      file.path(result_dir, paste0("curve_", discretization, ".csv")),
      row.names = FALSE
    )
  }
}

metrics <- do.call(rbind, rows)
numeric_metrics <- c("wall_seconds", "cpu_seconds", "cpu_usage_percent", "lambda", "gcv", "normalized_rmse")
if (any(!is.finite(as.matrix(metrics[numeric_metrics])))) stop("non-finite fit metric")
write.csv(metrics, file.path(result_dir, "metrics.csv"), row.names = FALSE)
unlink(queue_file)

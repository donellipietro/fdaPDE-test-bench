# = ========================================================================== =
# - Test: SRPDE smoothing example
# - Desc: Loads one option JSON, runs all repetitions and models, and saves the
#         standard fitted-model and evaluation RData files for aggregation.
# - Args:
#   [1] name_main_test: vary_n_locs, vary_n_nodes, or vary_snr
#   [2] file_options: JSON option file selected from the test queue
# = ========================================================================== =

rm(list = ls())
graphics.off()

## Load libraries ----
suppressMessages(library(jsonlite))

## Load general and test-specific functions ----
source("src/utils/cat.R")
source("src/utils/directories.R")
source("src/utils/load_results_utils.R")
source("tests/smoothing-example/config.R")
source("tests/smoothing-example/utils/generate_data.R")
source("tests/smoothing-example/utils/wrappers.R")
source("tests/smoothing-example/utils/fit_and_evaluate.R")
source("tests/smoothing-example/utils/adjust_results.R")
source("tests/smoothing-example/utils/models_evaluation.R")

## Read the requested option ----
path_list <- create_paths(test_suite)
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("usage: main.R <test-name> <option-file>")

name_main_test <- args[1]
file_options <- args[2]
path_list$queue <- config_path(path_list$queue, name_main_test)
path_list$logs <- config_path(path_list$logs, name_main_test)
mkdir(c(path_list$queue, path_list$logs))

queue_file <- file.path(path_list$queue, file_options)
test_options <- fromJSON(queue_file, simplifyVector = TRUE)
path_list <- update_paths(path_list, name_main_test, test_options)

## Log file ----
run_message <- glue::glue(
  "- Running: {test_suite} / {test_options$name_test}\n",
  .trim = FALSE
)
cat(run_message)
sink(file.path(path_list$logs, "log.txt"), append = TRUE)
cat(run_message)
sink()
sink(
  file.path(path_list$logs, glue::glue("log_{test_options$name_test}.txt")),
  append = TRUE
)
cat(run_message)

## Recursive fit ----
for (batch_index in seq_len(test_options$test_options$n_reps)) {
  cat(glue::glue("\nBatch {batch_index}:\n", .trim = FALSE))

  ## Create the standard batch directory
  path_list$batch <- config_path(path_list$results, glue::glue("batch_{batch_index}"))
  mkdir(path_list$batch)

  ## Generate paired FEM/spline data with a distinct repetition seed
  cat("- Generate data\n")
  seed <- test_options$noise$seed + batch_index
  data <- generate_smoothing_data(test_options, seed)
  if (batch_index == 1L) {
    save(data, file = file.path(path_list$data, glue::glue("{test_options$name_test}.RData")))
  }

  ## Fit, adjust, evaluate, and save both models using template utilities
  cat("- Fit models\n")
  test_options$batch_index <- batch_index
  fit_and_evaluate_models(
    path_list = path_list,
    data = data,
    domain = NULL,
    batch_index = batch_index,
    test_options = test_options
  )
}

## Test finalization ----
unlink(queue_file)
sink()

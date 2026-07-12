rm(list = ls())
graphics.off()

suppressMessages(library(jsonlite))

source("src/utils/cat.R")
source("src/utils/directories.R")
source("src/utils/load_results_utils.R")
source("tests/smoothing-example/config.R")
source("tests/smoothing-example/utils/generate_data.R")
source("tests/smoothing-example/utils/wrappers.R")
source("tests/smoothing-example/utils/fit_and_evaluate.R")
source("tests/smoothing-example/utils/adjust_results.R")
source("tests/smoothing-example/utils/models_evaluation.R")

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

cat("- Running:", test_suite, "/", test_options$name_test, "\n")
for (batch_index in seq_len(test_options$test_options$n_reps)) {
  cat("- Batch", batch_index, "of", test_options$test_options$n_reps, "\n")
  path_list$batch <- config_path(path_list$results, paste0("batch_", batch_index))
  mkdir(path_list$batch)

  seed <- test_options$noise$seed_base + batch_index
  data <- generate_smoothing_data(test_options, seed)
  if (batch_index == 1L) {
    save(data, file = file.path(path_list$data, paste0(test_options$name_test, ".RData")))
  }

  test_options$batch_index <- batch_index
  fit_and_evaluate_models(
    path_list = path_list,
    data = data,
    domain = NULL,
    batch_index = batch_index,
    test_options = test_options
  )
}

unlink(queue_file)

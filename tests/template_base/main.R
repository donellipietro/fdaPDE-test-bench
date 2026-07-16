# = ========================================================================== =
# - Test: Template Base
# - Desc: Automates a full test cycle: picks an option, runs all methods,
#         and saves results, logs, and plots for later analysis.
# - Args (when calling it from terminal):
#   [1] name_main_test : name of the main test to run (e.g., "test1")
#   [2] file_options : JSON file containing the test options to use
# = ========================================================================== =

rm(list = ls())
graphics.off()
options(warn = -1)


# README ----

## Welcome!
# Hi there, this script aims to make your life easier when it comes
# to testing your brand-new method in different scenarios.

## IMPORTANT!
# Before starting:
# - Remember to set your working directory to the root directory.
# - Updated the config.R file in the directory of the test
# - Type "make help" in your terminal to discover all the shortcuts!


# Configuration ----

## Load libraries ----

invisible(suppressMessages(sapply(c(
  # discretization
  "fdaPDE", "femR",
  # algebraic utils
  "pracma",
  # data manipulation
  "MASS", "tidyr", "dplyr",
  # visualization
  "ggplot2", "viridis", "stringr", "RColorBrewer", "grid", "gridExtra",
  # json
  "jsonlite",
  # sampling
  "sf", "sp", "raster"
), require, character.only = TRUE)))


## Load functions ----

## Load general utility functions
source("src/utils/cat.R")
source("src/utils/directories.R")
source("src/utils/options.R")
source("src/utils/mesh_utils.R")
source("src/utils/domain_utils.R")
source("src/utils/plotting_utils.R")
source("src/utils/error_metrics.R")
source("src/utils/load_results_utils.R")


## Load configuration file
path_this <- get_script_path()
source(file.path(path_this, "config.R"))

## Load test-specific functions
source(file.path("tests", test_suite, "utils", "wrappers.R"))
source(file.path("tests", test_suite, "utils", "fit_and_evaluate.R"))
source(file.path("tests", test_suite, "utils", "adjust_results.R"))
source(file.path("tests", test_suite, "utils", "generate_data.R"))
source(file.path("tests", test_suite, "utils", "models_evaluation.R"))


## Create suite directories ----

## Define and create work directories for the test suite
path_list <- create_paths(test_suite)


# Test ----

## Options ----

## Read arguments passed from the terminal
args <- commandArgs(trailingOnly = TRUE)

## Parse the arguments, if any
if (length(args) == 0) {
  ## Switch to interactive mode
  INTERACTIVE <- TRUE
  
  ## Load the option-generation function
  source(file.path("tests", test_suite, "utils", "generate_options.R"))
  
  ## Select the test you're interested in
  name_main_test <- name_main_test_default
  
  ## Update directories according to the new test
  path_list$queue <- config_path(path_list$queue, name_main_test)
  path_list$logs <- config_path(path_list$logs, name_main_test)
  mkdir(c(path_list$queue, path_list$logs))
  
  ## Generate all the options for that test
  generate_options(test_suite, name_main_test, path_list$queue)
  
  ## Read all the available options
  file_options_list <- sort(list.files(path_list$queue), decreasing = FALSE)
  file_options <- NULL
} else {
  ## Switch to non-interactive mode
  INTERACTIVE <- FALSE
  
  ## Set the requested configuration
  name_main_test <- args[1]
  file_options <- args[2]
  
  ## Update directories according to the new test
  path_list$queue <- config_path(path_list$queue, name_main_test)
  path_list$logs <- config_path(path_list$logs, name_main_test)
  mkdir(c(path_list$queue, path_list$logs))
}

## Select the test option
if (is.null(file_options)) {
  file_options_list
  file_options <- file_options_list[1] ## <====== INPUT HERE
}

## Load selected options
test_options <- fromJSON(file.path(path_list$queue, file_options))

## Update and create work directories for the test selected
path_list <- update_paths(path_list, name_main_test, test_options)

## Log file
file_log_global <- file.path(path_list$logs, "log.txt")
file_log_specific <- file.path(
  path_list$logs,
  glue::glue("log_{test_options$name_test}.txt")
)
if (!INTERACTIVE) {
  ## Console
  cat(glue::glue(
    "- Running: {test_suite} / {test_options$name_test}\n",
    .trim = FALSE
  ))
  ## Global log
  sink(file_log_global, append = TRUE)
  cat(glue::glue(
    "- Running: {test_suite} / {test_options$name_test}\n",
    .trim = FALSE
  ))
  sink()
  ## Test specific log
  sink(file_log_specific, append = TRUE)
}

## Options visualization
cat.script_title(glue::glue("Test: {TEST_SUITE}"))
cat.section_title("Options")
cat.json(test_options)

batch_data_signature <- function(test_options, seed) {
  list(
    dimensions = test_options$dimensions,
    data = test_options$data,
    noise = test_options$noise,
    seed = seed
  )
}

batch_run_signature <- function(test_options, seed) {
  test_options$batch_index <- NULL
  list(
    options = test_options,
    seed = seed
  )
}

same_signature <- function(left, right) {
  isTRUE(all.equal(left, right, check.attributes = TRUE))
}

annotate_cached_data <- function(data, test_options, seed) {
  attr(data, "testbench_cache") <- list(
    data_signature = batch_data_signature(test_options, seed),
    run_signature = batch_run_signature(test_options, seed)
  )
  data
}

read_cached_data <- function(file) {
  if (!file.exists(file)) return(NULL)
  readRDS(file)
}

cached_data_matches <- function(data, signature_name, signature) {
  cache <- attr(data, "testbench_cache", exact = TRUE)
  !is.null(cache) && same_signature(cache[[signature_name]], signature)
}


## Load domain and locations ----

## Generate the domain and its mesh
domain <- generate_domain(
  test_options$domain_and_locations$name_mesh,
  test_options$dimensions$n_nodes
)

## Sample the locations
locations <- generate_locations(
  domain,
  test_options$domain_and_locations$locs_eq_nodes,
  test_options$dimensions$n_locs
)

## Plot domain and locations
plot.points(
  locations = locations,
  boundary = domain$boundary,
  group_colors = "darkblue", size = 1
) + std_plot_settings_fields() + ggtitle("Domain and locations")


## Recursive fit ----

## Fit the models n_reps times
if (RUN$tests) {
  for (batch_idx in 1:test_options$test_options$n_reps) {
    cat(glue::glue("\nBatch {batch_idx}:\n", .trim = FALSE))
    
    ## Create batch directory
    path_list$batch <- config_path(path_list$results, glue::glue("batch_{batch_idx}"))
    mkdir(path_list$batch)
    
    ## File names where cached data and results should be found
    seed <- 4 * batch_idx + test_options$noise$seed
    data_file <- file.path(path_list$batch, "generated_data.rds")
    evaluation_file <- file.path(
      path_list$batch,
      glue::glue("batch_{batch_idx}_results_evaluation.RData")
    )
    file_model_vect <- file.path(
      path_list$batch,
      glue::glue("batch_{batch_idx}_fitted_model_{test_options$model_names}.RData")
    )
    data_signature <- batch_data_signature(test_options, seed)
    run_signature <- batch_run_signature(test_options, seed)
    data <- read_cached_data(data_file)
    if (!FORCE_FIT && !FORCE_EVALUATE &&
        all(file.exists(c(evaluation_file, file_model_vect))) &&
        cached_data_matches(data, "run_signature", run_signature)) {
      cat("- Existing complete batch; skipped\n")
      next
    }

    ## Generate data only if necessary, or reuse matching cached data
    if (!FORCE_FIT && cached_data_matches(data, "data_signature", data_signature)) {
      cat("- Load generated data\n")
    } else {
      cat("- Generate data\n")
      data <- generate_data(
        domain = domain, locations = locations,
        test_options = test_options,
        ## ....
        seed = seed
      )
      data <- annotate_cached_data(data, test_options, seed)
      saveRDS(data, data_file)

      ## Save data for qualitative results analysis
      if (batch_idx == 1) {
        save(data, file = file.path(path_list$data, glue::glue("{test_options$name_test}.RData")))
      }
    }
    
    ## Fit and evaluation ----
    cat("- Fit models\n")
    
    fit_and_evaluate_models(
      path_list = path_list,
      data = data,
      domain = domain,
      batch_index = batch_idx,
      test_options = test_options
    )
    
  }
} else {
  cat("Skipped, relying on the saved results!\n")
}

# Test finalization ----

## Remove options file from the queue ----
file.remove(file.path(path_list$queue, file_options))

## Close the log file
if (!INTERACTIVE) {
  sink()
}

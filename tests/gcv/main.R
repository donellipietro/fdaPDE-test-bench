# % %%%%%%%%%%%%%% %
# % % Test: fPCA % %
# % %%%%%%%%%%%%%% %

#' TODO:
#' - remove lambda_grid, put it in the test_options list

rm(list = ls())
graphics.off()

## global variables ----

test_suite <- "gcv"
TEST_SUITE <- "gcv"

# sources ----
invisible(suppressMessages(
  sapply(c(
    "fdaPDE","femR", #discretisation
    "pracma", #algebraic utils
    "MASS","tidyr","dplyr", #data manipulation
    "ggplot2","viridis","stringr","RColorBrewer","grid","gridExtra", #visualisation
    "jsonlite", #json
    "sf","sp","raster" #sampling
    ), require, character.only = TRUE)))

## general functions
sapply(list.files("src/utils", pattern = "\\.R$", full.names = TRUE), source)
source("src/data-generation/generate_2D_fpca_data.R")

## test specific functions
source(paste("tests/", test_suite, "/utils/models_evaluation.R", sep = ""))
source(paste("tests/", test_suite, "/utils/generate_options.R", sep = ""))

# paths ----
path_results <- paste("results/", test_suite, "/", sep = "")
path_images <- paste("images/", test_suite, "/", sep = "")
mkdir(c(path_results, path_images))

path_queue <- paste("queue/", sep = "")
path_logs <- paste("logs/", sep = "")
mkdir(c(path_logs))

cpp_scripts_path <- "/Users/marcogalliani/Projects/fdaPDE-test-bench/cpp-scripts/"
data_path <- paste(cpp_scripts_path,"data",sep="")
mesh_path <- paste(cpp_scripts_path,"mesh",sep="")

path_list <- list(data_path = data_path, mesh_path = mesh_path,
                  cpp_scripts_path = cpp_scripts_path)
  
# options ----
## force testing even if a fit is already available
FORCE_FIT <- T
FORCE_EVALUATE <- T

## execution flow modifiers
RUN <- list()
RUN$tests <- TRUE
RUN$analysis <- TRUE
RUN$quantitative_analysis <- TRUE
RUN$qualitative_analysis <- T

## global variables
RSTUDIO <- FALSE

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


# Test: gcv-cirves ----
cat.script_title(paste("Test:", TEST_SUITE))

## options ----
cat.section_title("Options")

## check arguments passed by terminal, set default if not present
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  RSTUDIO <- TRUE
  source(paste("tests/", test_suite, "/utils/generate_options.R", sep = ""))
  args[1] <- "test1"
  generate_options(args[1], path_queue)
  args[2] <- sort(list.files(path_queue),decreasing = T)[1]
}

## read arguments provided
name_main_test <- args[1]
file_options <- args[2]

## load options
test_options <- fromJSON(paste(path_queue, file_options, sep = ""))

## log file
file_log <- paste(path_logs, "log_",test_options$name_test,".txt", sep = "")
if(!RSTUDIO){
  sink(file_log, append = TRUE)
}

## options visualization
cat.json(test_options)

## create results directory
path_results <- paste(path_results, name_main_test, "/", sep = "")
mkdir(path_results)
path_results <- paste(path_results, test_options$name_test, "/", sep = "")
mkdir(path_results)
path_list$path_results <- path_results

## create images directory
path_images <- paste(path_images, name_main_test, "/", sep = "")
mkdir(path_images)
path_images <- paste(path_images, "single_tests/", sep = "")
mkdir(path_images)
path_list$path_images <- path_images

## test functions ----
## load domain
generated_domain <- generate_domain(test_options$mesh$name_mesh, 
                                    test_options$dimensions$n_nodes)
## loadings generator
loadings_true_generator <- function(locs,i) { 
  translated_laplacian_eigenfunction(locs,i,x_t=0.2,y_t=0)
}

## test ----
cat.section_title("Test")
batch_idx <- 0 # batch index
source(paste("tests/", test_suite, "/templates/fit_and_evaluate.R", sep = ""))
## fit the models n_reps times
if (RUN$tests) {
  ## message
  cat(paste("\nBatch ", batch_idx, ":\n", sep = ""))
  
  ## create batch directory
  path_batch <- paste(path_results, "batch_", batch_idx, "/", sep = "")
  mkdir(path_batch)
  ## generate data if necessary
  file_model_vect <- paste(path_batch, "batch_", batch_idx, "_fitted_model_", test_options$model_names, ".RData", sep = "")
  if (any(!file.exists(file_model_vect)) || FORCE_FIT || FORCE_EVALUATE) {
    ## generate data
    cat("- Data generation\n")
    generated_data <- generate_2D_fpca_data(
      domain = generated_domain,
      test_options = test_options,
      loadings_true_generator = loadings_true_generator,
      mean_generator = ifelse(F, log_mean_generator, function(locs) { return(locs[,1]*0) }),
      seed = 4*batch_idx + test_options$noise$seed
    )
  }
  ## fit models
  fit_and_evaluate_models(
    path_list = path_list, 
    generated_data = generated_data,
    domain = generated_domain,
    batch_index = batch_idx,
    test_options = test_options,
    FORCE_EVALUATE, FORCE_FIT)
  
} else { ## end run tests
  cat("Skipped, relying on the saved results!\n")
}

## results analysis ----
cat.section_title("Results analysis")

## load saved results
if (RUN$analysis) {
  source(paste("tests/", test_suite, "/templates/load_results.R", sep = ""))
  
  quantitative_analysis <- load_quantitative_results(test_options, path_list)
  # qualitative_analysis <- load_qualitative_results(
  #   test_options = test_options,
  #   generated_data = generated_data,
  #   generated_domain = generated_domain,
  #   loadings_true_generator = loadings_true_generator, 
  #   path_list = path_list)
}

## colors used in the plots
colors <- c(
  "sequential" = "coral3",
  "subspace" = "aquamarine4",
  "subspace_experimental" = "darkorchid3",
  "direct" = "blue4"
)

colors_fPCs <- c(
  "fPC1" = "brown2",
  "fPC2" = "blueviolet",
  "fPC3" = "darkorange"
)
### quantitative analysis ----
cat.subsection_title("Quantitative analysis")

if (RUN$quantitative_analysis) {
  pdf(file = paste(path_images, test_options$name_test, "_quantitative.pdf", sep = ""), width = 14, height = 7)
  source(paste("tests/", test_suite, "/templates/plot_quantitative_results.R", sep = ""))
  plot_quantitative_analysis(quantitative_analysis, test_options, colors_fPCs)
  dev.off()
}

# ### qualitative analysis ----
# cat.subsection_title("Qualitative analysis")
# 
# ## plots
# if (RUN$qualitative_analysis) {
#   pdf(file = paste(path_images, test_options$name_test, "_qualitative.pdf", sep = ""), width = 10, height = 7)
#   source(paste("tests/", test_suite, "/templates/plot_qualitative_results.R", sep = ""))
#   plot_qualitative_results(qualitative_analysis, quantitative_analysis, 
#                            generated_domain)
#   dev.off()
# }
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

## remove options file
file.remove(paste(path_queue, file_options, sep = ""))

cat("\n\n")

if(!RSTUDIO){
  sink()
}

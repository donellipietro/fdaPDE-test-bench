# % %%%%%%%%%%%%%% %
# % % Test: fPCA % %
# % %%%%%%%%%%%%%% %

rm(list = ls())
graphics.off()

## global variables ----

test_suite <- "gcv-curves"
TEST_SUITE <- "gcv-curves"

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

# templates
source(paste("tests/", test_suite, "/templates/load_results.R", sep = ""))

# test specific functions
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
FORCE_FIT <- F
FORCE_EVALUATE <- F

## execution flow modifiers
RUN <- list()
RUN$tests <- TRUE
RUN$analysis <- TRUE
RUN$quantitative_analysis <- TRUE
RUN$qualitative_analysis <- F

## global variables
RSTUDIO <- FALSE


## calibration parameters ----
seed <- 0 # for gcv calibration procedure
lambda_grid <- 10^seq(-6, 2, by = 0.5)

cpp_params_json <- fromJSON(paste(cpp_scripts_path, "calibrated-fpca/params.json", sep = ""))

cpp_params_json$RunParams$lambda_grid <- lambda_grid
write_json(path = paste(cpp_scripts_path, "calibrated-fpca/params.json", sep = ""), 
           cpp_params_json, auto_unbox=T, pretty=T, digits=10
)

## visualization options ----

## names and labels
names_models <- c("sequential", 
                  "subspace", 
                  "subspace_experimental",
                  "direct"
                  )
lables_models <- c("sequential", 
                   "subspace", 
                   "subspace_experimental",
                   "direct"
                   )
## colors used in the plots
colors <- c(
  "sequential" = "coral3",
  "subspace" = "aquamarine4",
  "subspace_experimental" = "darkorchid3",
  "direct" = "blue4"
)

## resolution of the high resolution grid
n_nodes_HR_grid <- 1000


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Test: fPCA missing ----
cat.script_title(paste("Test:", TEST_SUITE))

## options ----
cat.section_title("Options")

## check arguments passed by terminal, set default if not present
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  RSTUDIO <- TRUE
  args[1] <- "test1"
  generate_options(args[1], path_queue)
  args[2] <- sort(list.files(path_queue),decreasing = T)[1]
}

## read arguments provided
name_main_test <- args[1]
file_options <- args[2]

## load options
parsed_json <- fromJSON(paste(path_queue, file_options, sep = ""))
name_test <- parsed_json$test$name_test
name_mesh <- parsed_json$mesh$name_mesh
n_nodes <- parsed_json$dimensions$n_nodes
n_locs <- parsed_json$dimensions$n_locs
n_stat_units <- parsed_json$dimensions$n_stat_units
n_comp <- parsed_json$dimensions$n_comp
generate_mean <- parsed_json$data$mean
locs_eq_nodes <- parsed_json$data$locs_eq_nodes
NSR <- parsed_json$noise$NSR
# ... (add options if necessary)

## log file
file_log <- paste(path_logs, "log_",name_test,".txt", sep = "")
if(!RSTUDIO){
  sink(file_log, append = TRUE)
}

## options visualization
cat.json(parsed_json)

## create results directory
path_results <- paste(path_results, name_main_test, "/", sep = "")
mkdir(path_results)
path_results <- paste(path_results, name_test, "/", sep = "")
mkdir(path_results)
path_list$path_results <- path_results

## create images directory
path_images <- paste(path_images, name_main_test, "/", sep = "")
mkdir(path_images)
path_images <- paste(path_images, "single_tests/", sep = "")
mkdir(path_images)


## test ----
cat.section_title("Test")

## load domain
generated_domain <- generate_domain(name_mesh, n_nodes)
domain <- generated_domain$domain
domain_boundary <- generated_domain$domain_boundary
mesh <- generated_domain$mesh

## locations
locations <- generate_locations(generated_domain, n_locs = n_locs, locs_eq_nodes=locs_eq_nodes)

## grid
HR_grid <- spsample(domain_boundary, n_nodes_HR_grid, "regular")@coords

## loadings generator
loadings_true_generator <- function(locs,i) { 
  translated_laplacian_eigenfunction(locs,i,x_t=0.2,y_t=0)
}

## fit the models n_reps times
batch_index <- 0 # batch index

source(paste("tests/", test_suite, "/templates/fit_and_evaluate.R", sep = ""))
if (RUN$tests) {
  ## message
  cat(paste("\nBatch: ",batch_index,"\n", sep = ""))
  
  ## generate data if necessary
  path_batch <- paste(path_list$path_results, "batch_", batch_index, "/", sep = "")
  mkdir(path_batch)
  file_model_vect <- paste(path_batch, "batch_", batch_index, "_fitted_model_", names_models, ".RData", sep = "")
  if (any(!file.exists(file_model_vect)) || FORCE_FIT || FORCE_EVALUATE) {
    ## generate data
    cat("- Data generation\n")
    generated_data <- generated_data(
      domain = domain,
      locs = locations,
      n_stat_units = n_stat_units,
      n_comp = n_comp,
      seed = 0,
      NSR = NSR,
      loadings_true_generator = loadings_true_generator,
      mean_generator = ifelse(generate_mean, log_mean_generator, function(locs) { return(locs[,1]*0) })
    )
  }
  ## fit models
  fit_and_evaluate_models(path_list = path_list, 
                          model_names = names_models, 
                          generated_data = generated_data,
                          mesh = mesh,
                          batch_index = batch_index,
                          params_json = cpp_params_json,
                          lambda_grid = lambda_grid,
                          FORCE_EVALUATE = FORCE_EVALUATE, FORCE_FIT = FORCE_FIT)
} else { ## end run tests
  cat("Skipped, relying on the saved results!\n")
}

## results analysis ----
cat.section_title("Results analysis")

### quantitative analysis ----
cat.subsection_title("Quantitative analysis")

source(paste("tests/", test_suite, "/templates/plot_quantitative_results.R", sep = ""))
if (RUN$quantitative_analysis) {
  loaded_results <- load_quantitative_results(
    batch_index = batch_index,  
    model_names = names_models, 
    path_list = path_list, 
    name_test = name_test
  )
  ## open a pdf where to save plots (quantitative analysis)
  pdf(file = paste(path_images, name_test, "_quantitative.pdf", sep = ""),  width = 14, height = 7)
  ## plots
  plot_quantitative_analysis(loaded_results, parsed_json)
  ## close pdf (quantitative analysis)
  dev.off()
}
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

## remove options file
file.remove(paste(path_queue, file_options, sep = ""))

cat("\n\n")

if(!RSTUDIO){
  sink()
}
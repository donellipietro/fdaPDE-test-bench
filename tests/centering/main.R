# % %%%%%%%%%%%%%%%%%%% %
# % % Test: Centering % %
# % %%%%%%%%%%%%%%%%%%% %

rm(list = ls())
graphics.off()

## global variables ----

test_suite <- "centering"
TEST_SUITE <- "Centering"


# libraries ----

## fda
#suppressMessages(library(femR))
suppressMessages(library(fdaPDE))

## algebraic utils
suppressMessages(library(pracma))

## statistical utils
suppressMessages(library(MASS))

## data visualization
suppressMessages(library(tidyr))
suppressMessages(library(dplyr))
suppressMessages(library(ggplot2))
suppressMessages(library(viridis))
suppressMessages(library(stringr))
suppressMessages(library(RColorBrewer))
suppressMessages(library(grid))
suppressMessages(library(gridExtra))

## json
suppressMessages(library(jsonlite))

## sampling
suppressMessages(library(sf))
suppressMessages(library(sp))
suppressMessages(library(raster))


# sources ----

## general functions
source("src/utils/cat.R")
source("src/utils/directories.R")
source("src/utils/meshes.R")
source("src/utils/domain_and_locations.R")
source("src/utils/wrappers.R")
source("src/utils/errors.R")
source("src/utils/results_management.R")
source("src/utils/plots.R")

## test specific functions
source(paste("tests/", test_suite, "/utils/generate_2D_data.R", sep = ""))
source(paste("tests/", test_suite, "/utils/models_evaluation.R", sep = ""))


# paths ----

path_results <- paste("results/", test_suite, "/", sep = "")
path_images <- paste("images/", test_suite, "/", sep = "")
mkdir(c(path_results, path_images))

path_queue <- paste("queue/", sep = "")
path_logs <- paste("logs/", sep = "")
mkdir(c(path_logs))
  
  
# options ----

## force testing even if a fit is already available
FORCE_FIT <- FALSE
FORCE_EVALUATE <- FALSE

## execution flow modifiers
RUN <- list()
RUN$tests <- TRUE
RUN$analysis <- TRUE
RUN$quantitative_analysis <- TRUE
RUN$qualitative_analysis <- F

## global variables
RSTUDIO <- F

## calibration parameters ----
seed <- 0 # for gcv calibration procedure
lambda_grid <- 10^seq(-9, -1, by = 0.1)

scripts_path <- "/Users/marcogalliani/Projects/fdaPDE-test-bench/tests/centering/cpp-scripts/"
params_json <- fromJSON(paste(scripts_path, "params.json", sep = ""))

params_json$RunParams$lambda_grid <- lambda_grid
write_json(path = paste(scripts_path, "params.json", sep = ""), 
       params_json, auto_unbox=T, pretty=T, digits=10
           )

## visualization options ----

## names and labels
names_models <- c("FRPDE-miss", 
                  "FRPDE-weights", 
                  "FRPDE-old",
                  "DINEOF-colMeans")
lables_models <- c("FRPDE-miss", 
                   "FRPDE-weights", 
                   "FRPDE-old",
                   "DINEOF-colMeans")

## colors used in the plots
colors <- brewer.pal(length(lables_models), "Set3")

## resolution of the high resolution grid
n_nodes_HR_grid <- 1000


# Test: centering ----
cat.script_title(paste("Test:", TEST_SUITE))


## options ----
cat.section_title("Options")

## check arguments passed by terminal, set default if not present
args <- commandArgs(trailingOnly = T)
if (length(args) == 0) {
  RSTUDIO <- T
  source(paste("tests/", test_suite, "/utils/generate_options.R", sep = ""))
  args[1] <- "test2"
  generate_options(args[1], path_queue)
  args[2] <- sort(list.files(path_queue))[1]
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
n_reps <- parsed_json$dimensions$n_reps
locs_eq_nodes <- parsed_json$data$locs_eq_nodes
only_mean <- parsed_json$data$only_mean
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
locations <- generate_locations(generated_domain, locs_eq_nodes, n_locs=n_locs)

## grid
grid <- spsample(domain_boundary, n_nodes_HR_grid, "regular")@coords

## fit the models n_reps times
if (RUN$tests) {
  for (i in 1:n_reps) {
    ## message
    cat(paste("\nBatch ", i, ":\n", sep = ""))
    
    ## create batch directory
    path_batch <- paste(path_results, "batch_", i, "/", sep = "")
    mkdir(path_batch)
    
    ## generate data if necessary
    file_model_vect <- paste(path_batch, "batch_", i, "_fitted_model_", names_models, ".RData", sep = "")
    if (any(!file.exists(file_model_vect)) || FORCE_FIT || FORCE_EVALUATE) {
      ## generate data
      cat("- Data generation\n")
      generated_data <- generate_2D_data(
        domain = domain,
        locs = locations,
        mean_generator = log_mean_generator,#function(locs) { translate_laplacian_eigenfunction(locs,1,1,0.2,0.2)},
        n_stat_units = n_stat_units,
        only_mean = only_mean,
        seed = i,
        NSR = NSR
      )

      
      scripts_path <- "/Users/marcogalliani/Projects/fdaPDE-test-bench/tests/centering/cpp-scripts/"
      #data: data matrix, locs
      data_path <- paste(scripts_path,"data",sep="")
      write.csv(format(generated_data$X_partial,digits=16), 
                file = paste(data_path,"/y.csv",sep=""))
      write.csv(format(locations,digits=16), 
                file = paste(data_path,"/locs.csv",sep=""))
      #mesh
      mesh_path <- paste(scripts_path,"mesh",sep="")
      write.csv(format(mesh$nodes, digits = 16), paste(mesh_path,"/points.csv", sep = ""))
      write.csv(format(mesh$triangles, digits = 16), paste(mesh_path,"/elements.csv", sep = ""))
      write.csv(format(1 * mesh$nodesmarkers, digits = 16), paste(mesh_path,"/boundary.csv", sep = ""))
      write.csv(format(mesh$neighbors, digits = 16), paste(mesh_path,"/neigh.csv", sep = ""))
      write.csv(format(mesh$edges, digits = 16), paste(mesh_path,"/edges.csv", sep = ""))
    }
    ## fit models
    source(paste("tests/", test_suite, "/templates/fit_and_evaluate.R", sep = ""))
  }
} else { ## end run tests
  cat("Skipped, relying on the saved results!\n")
}


## results analysis ----
cat.section_title("Results analysis")

## load saved results
if (RUN$analysis) {
  source(paste("tests/", test_suite, "/templates/load_results.R", sep = ""))
}


### quantitative analysis ----
cat.subsection_title("Quantitative analysis")


if (RUN$quantitative_analysis) {
  ## open a pdf where to save plots (quantitative analysis)

  pdf(file = paste(path_images, name_test, "_quantitative.pdf", sep = ""))
  
  
  ## plots
  source(paste("tests/", test_suite, "/templates/plot_quantitative_results.R", sep = ""))
  
  ## close pdf (quantitative analysis)
  dev.off()
}


### qualitative analysis ----
cat.subsection_title("Qualitative analysis")

## plots
if (RUN$qualitative_analysis) {
  ## open a pdf where to save plots (qualitative analysis)
  if (!RSTUDIO) {
    pdf(file = paste(path_images, name_test, "_qualitative.pdf", sep = ""), width = 10, height = 7)
  }
  
  ## plot
  source(paste("tests/", test_suite, "/templates/plot_qualitative_results.R", sep = ""))
  
  ## close pdf (qualitative analysis)
  dev.off()
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


## remove options file
file.remove(paste(path_queue, file_options, sep = ""))

cat("\n\n")

if(!RSTUDIO){
  sink()
}
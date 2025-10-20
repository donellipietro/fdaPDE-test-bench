## room for solutions
results_evaluation <- list()

## load results_evaluation if available
if (file.exists(paste(path_batch, "batch_", i, "_results_evaluation.RData", sep = ""))) {
  load(paste(path_batch, "batch_", i, "_results_evaluation.RData", sep = ""))
}

### Model FRPDE-old----
model_FRPDE_old <- NULL
file_model <- paste(path_batch, "batch_", i, "_fitted_model_FRPDE_old.RData", sep = "")
if (file.exists(file_model) && !FORCE_FIT) {
  if(FORCE_EVALUATE) {
    cat("- Loading fitted FRPDE-old ... \n")
    load(file_model)
  }
} else if ("FRPDE-old" %in% names_models) {
  cat("- Fitting FRPDE-old ... ")
  
  ## model fit
  start.time <- Sys.time()
  script_path <- "/Users/marcogalliani/Projects/fdaPDE-test-bench/tests/centering/cpp-scripts/frpde-old"
  system(paste("cd ",script_path,"; ./frpde-old",sep=""),ignore.stdout = T)
  end.time <- Sys.time()
  cat(paste("finished after", end.time - start.time, attr(end.time - start.time, "units"), "\n"))
  
  ## add flags
  model_FRPDE_old$model_traits$is_functional <- F
  model_FRPDE_old$model_traits$has_interpolator <- FALSE
  
  ## add execution time to results
  model_FRPDE_old$results$execution_time <- end.time - start.time
  
  ## save fitted model
  save(
    index_batch = i,
    model_FRPDE_old,
    file = file_model
  )
}
if(!is.null(model_FRPDE_old)) {
  
  ## X_mean
  model_FRPDE_old$results$X_mean_locs <- read.csv(paste(script_path,"/results/center_locs.csv",sep=""))
  model_FRPDE_old$results$X_mean <- read.csv(paste(script_path,"/results/center.csv",sep=""))

  ## model evaluation
  results_evaluation[["FRPDE-old"]] <- evaluate_results(model_FRPDE_old, generated_data)
  
  ## clean the workspace
  rm(model_FRPDE_old)
}

### Model FRPDE-weighted----
model_FRPDE_weighted <- NULL
file_model <- paste(path_batch, "batch_", i, "_fitted_model_FRPDE-weights.RData", sep = "")
if (file.exists(file_model) && !FORCE_FIT) {
  if(FORCE_EVALUATE) {
    cat("- Loading fitted FRPDE-weighted ... \n")
    load(file_model)
  }
} else if ("FRPDE-weights" %in% names_models) {
  cat("- Fitting FRPDE-weighted ... ")
  
  ## model fit
  start.time <- Sys.time()
  
  script_path <- "/Users/marcogalliani/Projects/fdaPDE-test-bench/tests/centering/cpp-scripts/frpde-weights"
  system(paste("cd ",script_path,"; ./frpde-weights",sep=""),ignore.stdout = T)
  
  end.time <- Sys.time()
  cat(paste("finished after", end.time - start.time, attr(end.time - start.time, "units"), "\n"))
  
  
  ## add flags
  model_FRPDE_weighted$model_traits$is_functional <- F
  model_FRPDE_weighted$model_traits$has_interpolator <- FALSE
  
  ## add execution time to results
  model_FRPDE_weighted$results$execution_time <- end.time - start.time
  
  ## save fitted model
  save(
    index_batch = i,
    model_FRPDE_weighted,
    file = file_model
  )
}
if(!is.null(model_FRPDE_weighted)) {
  
  ## X_mean
  model_FRPDE_weighted$results$X_mean_locs <- read.csv(paste(script_path,"/results/center_locs.csv",sep=""))
  model_FRPDE_weighted$results$X_mean <- read.csv(paste(script_path,"/results/center.csv",sep=""))
    
  ## model evaluation
  results_evaluation[["FRPDE-weights"]] <- evaluate_results(model_FRPDE_weighted, generated_data)
  
  ## clean the workspace
  rm(model_FRPDE_weighted)
}


### Model FRPDE-partially_obs----
model_FRPDE_miss <- NULL
file_model <- paste(path_batch, "batch_", i, "_fitted_model_FRPDE-miss.RData", sep = "")
if (file.exists(file_model) && !FORCE_FIT) {
  if(FORCE_EVALUATE) {
    cat("- Loading fitted FRPDE-miss ... \n")
    load(file_model)
  }
} else if ("FRPDE-miss" %in% names_models) {
  cat("- Fitting FRPDE-partially_obs ... ")
  
  ## model fit
  start.time <- Sys.time()
  
  script_path <- "/Users/marcogalliani/Projects/fdaPDE-test-bench/tests/centering/cpp-scripts/frpde-miss"
  system(paste("cd ",script_path,"; ./frpde-miss",sep=""))
  
  end.time <- Sys.time()
  cat(paste("finished after", end.time - start.time, attr(end.time - start.time, "units"), "\n"))
  
  ## X_mean
  model_FRPDE_miss$results$X_mean_locs <- read.csv(paste(script_path,"/results/center_locs.csv",sep=""))
  model_FRPDE_miss$results$X_mean <- read.csv(paste(script_path,"/results/center.csv",sep=""))
  
  ## add flags
  model_FRPDE_miss$model_traits$is_functional <- TRUE
  model_FRPDE_miss$model_traits$has_interpolator <- FALSE
  
  ## add execution time to results
  model_FRPDE_miss$results$execution_time <- end.time - start.time
  
  ## save fitted model
  save(
    index_batch = i,
    model_FRPDE_miss,
    file = file_model
  )
}
if(!is.null(model_FRPDE_miss)) {
  ## model evaluation
  results_evaluation[["FRPDE-miss"]] <- evaluate_results(model_FRPDE_miss, generated_data)
  ## clean the workspace
  rm(model_FRPDE_miss)
}

### Model DINEOF_colMeans----
model_DINEOF_colMeans <- NULL
file_model <- paste(path_batch, "batch_", i, "_fitted_model_DINEOF-colMeans.RData", sep = "")
if (file.exists(file_model) && !FORCE_FIT) {
  if(FORCE_EVALUATE) {
    cat("- Loading fitted DINEOF-colMeans ... \n")
    load(file_model)
  }
} else if ("FRPDE-miss" %in% names_models) {
  cat("- Fitting DINEOF-colMeans ... ")
  
  ## model fit
  start.time <- Sys.time()
  dineof_fit <- sinkr::dineof(generated_data$X_partial)
  model_DINEOF_colMeans$results$X_mean_locs <- colMeans(dineof_fit$Xa)
  end.time <- Sys.time()
  cat(paste("finished after", end.time - start.time, attr(end.time - start.time, "units"), "\n"))
  
  ## add flags
  model_DINEOF_colMeans$model_traits$is_functional <- FALSE
  model_DINEOF_colMeans$model_traits$has_interpolator <- FALSE
  
  ## add execution time to results
  model_DINEOF_colMeans$results$execution_time <- end.time - start.time
  
  ## save fitted model
  save(
    index_batch = i,
    model_DINEOF_colMeans,
    file = file_model
  )
}
if(!is.null(model_DINEOF_colMeans)) {
  ## model evaluation
  results_evaluation[["DINEOF-colMeans"]] <- evaluate_results(model_DINEOF_colMeans, generated_data)
  ## clean the workspace
  rm(model_DINEOF_colMeans)
}


### save results evaluation ----
save(
  ## batch index
  index_batch = i,
  ## results
  results_evaluation,
  ## path
  file = paste(path_batch, "batch_", i, "_results_evaluation.RData", sep = "")
)

## clean the workspace
if("generated_data" %in% ls()) rm(generated_data)
rm(results_evaluation)

cat(paste("- Batch", i, "compleated.\n"))

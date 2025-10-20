## room for solutions
results_evaluation <- list()
data_path <- paste(scripts_path,"data/",sep="")

## load results_evaluation if available
if (file.exists(paste(path_batch, "batch_", i, "_results_evaluation.RData", sep = ""))) {
  load(paste(path_batch, "batch_", i, "_results_evaluation.RData", sep = ""))
}

### Model DINEOF ----
model_DINEOF <- NULL
file_model <- paste(path_batch, "batch_", i, "_fitted_model_dineof.RData", sep = "")
if (file.exists(file_model) && !FORCE_FIT) {
  if(FORCE_EVALUATE) {
    cat("- Loading fitted DINEOF \n")
    load(file_model)
  }
} else if ("dineof" %in% names_models) {
  cat("- Fitting DINEOF ... ")
  
  ## model fit
  start.time <- Sys.time()
  dineof_fit <- sinkr::dineof(data$X)
  model_DINEOF <- MV_PCA_wrapped(dineof_fit$Xa, n_comp = n_comp, center = mean)
  end.time <- Sys.time()
  cat(paste("finished after", end.time - start.time, attr(end.time - start.time, "units"), "\n"))
  
  ## add flags
  model_DINEOF$model_traits$is_functional <- FALSE
  model_DINEOF$model_traits$has_interpolator <- FALSE
  
  ## add execution time to results
  model_DINEOF$results$execution_time <- end.time - start.time
  model_DINEOF$results$X_imputed <- dineof_fit$Xa
  
  ## save fitted model
  save(
    index_batch = i,
    model_DINEOF,
    file = file_model
  )
}
if(!is.null(model_DINEOF)) {
  ## X_mean
  if(mean) {
    model_DINEOF$results$X_mean_locs <- model_DINEOF$results$X_mean_locs
  } else {
    model_DINEOF$results$X_mean_locs <- NULL
  }
  
  ## model evaluation
  results_evaluation$dineof <- evaluate_results(model_DINEOF, generated_data)
  
  ## clean the workspace
  rm(dineof_fit)
  rm(model_DINEOF)
}


### Model fPCA (kcv calibration) ----
model_fPCA_kcv <- NULL
file_model <- paste(path_batch, "batch_", i, "_fitted_model_fpca_kcv.RData", sep = "")
if (file.exists(file_model) && !FORCE_FIT) {
  if(FORCE_EVALUATE) {
    cat("- Loading fitted fPCA (kcv calibration) ... \n")
    load(file_model)
  }
} else if ("fpca_kcv" %in% names_models) {
  cat("- Fitting fPCA (kcv calibration) ... ")
  
  ## model fit
  start.time <- Sys.time()
  script_path <- "/Users/marcogalliani/Projects/fdaPDE-test-bench/tests/fpca-missing/cpp-scripts/fpca-kcv"
  system(paste("cd ",script_path,"; ./fpca_kcv",sep=""),ignore.stdout = T)
  
  end.time <- Sys.time()
  cat(paste("finished after", end.time - start.time, attr(end.time - start.time, "units"), "\n"))
  
  ## save results
  ## 1) mean
  model_fPCA_kcv$results$X_mean <- as.matrix(read.csv(paste(script_path,"/test-results/center.csv",sep="")))
  model_fPCA_kcv$results$X_mean_locs <- as.matrix(read.csv(paste(script_path,"/test-results/center_locs.csv",sep="")))
  ## 2) loadings
  model_fPCA_kcv$results$loadings <- as.matrix(read.csv(paste(script_path,"/test-results/loadings.csv",sep="")))
  model_fPCA_kcv$results$loadings_locs <- as.matrix(read.csv(paste(script_path,"/test-results/loadings_locs.csv",sep="")))
  ## 3) scores
  model_fPCA_kcv$results$scores <- as.matrix(read.csv(paste(script_path,"/test-results/scores.csv",sep="")))
  ## 4) reconstruction
  model_fPCA_kcv$results$X_hat <- as.matrix(read.csv(paste(script_path,"/test-results/reconstruction.csv",sep="")))
  model_fPCA_kcv$results$X_hat_locs <- as.matrix(read.csv(paste(script_path,"/test-results/reconstruction_at_locs.csv",sep="")))
  ## 5) imputation
  model_fPCA_kcv$results$X_imputed <- as.matrix(read.csv(paste(script_path,"/test-results/imputation.csv",sep="")))
  
  ## add flag
  model_fPCA_kcv$model_traits$is_functional <- F
  model_fPCA_kcv$model_traits$has_interpolator <- F
  
  ## add execution time to results
  model_fPCA_kcv$results$execution_time <- end.time - start.time
  
  ## save fitted model
  save(
    index_batch = i,
    model_fPCA_kcv,
    file = file_model
  )
  
}
if(!is.null(model_fPCA_kcv)) {
  ## model evaluation
  results_evaluation$fpca_kcv <- evaluate_results(model_fPCA_kcv, generated_data)
  
  ## clean the workspace
  rm(model_fPCA_kcv)
}



### Model fPCA (gcv calibration) ----
model_fPCA_gcv <- NULL
file_model <- paste(path_batch, "batch_", i, "_fitted_model_fpca_gcv.RData", sep = "")
if (file.exists(file_model) && !FORCE_FIT) {
  if(FORCE_EVALUATE) {
    cat("- Loading fitted fPCA (gcv calibration) ... \n")
    load(file_model)
  }
} else if ("fpca_gcv" %in% names_models) {
  cat("- Fitting fPCA (gcv calibration) ... ")
  
  ## model fit
  start.time <- Sys.time()
  script_path <- "/Users/marcogalliani/Projects/fdaPDE-test-bench/tests/fpca-missing/cpp-scripts/fpca-gcv"
  system(paste("cd ",script_path,"; ./fpca_gcv",sep=""),ignore.stdout = T)
  
  end.time <- Sys.time()
  cat(paste("finished after", end.time - start.time, attr(end.time - start.time, "units"), "\n"))
  
  ## save results
  ## 1) mean
  model_fPCA_gcv$results$X_mean <- as.matrix(read.csv(paste(script_path,"/test-results/center.csv",sep="")))
  model_fPCA_gcv$results$X_mean_locs <- as.matrix(read.csv(paste(script_path,"/test-results/center_locs.csv",sep="")))
  ## 2) loadings
  model_fPCA_gcv$results$loadings <- as.matrix(read.csv(paste(script_path,"/test-results/loadings.csv",sep="")))
  model_fPCA_gcv$results$loadings_locs <- as.matrix(read.csv(paste(script_path,"/test-results/loadings_locs.csv",sep="")))
  ## 3) scores
  model_fPCA_gcv$results$scores <- as.matrix(read.csv(paste(script_path,"/test-results/scores.csv",sep="")))
  ## 4) reconstruction
  model_fPCA_gcv$results$X_hat <- as.matrix(read.csv(paste(script_path,"/test-results/reconstruction.csv",sep="")))
  model_fPCA_gcv$results$X_hat_locs <- as.matrix(read.csv(paste(script_path,"/test-results/reconstruction_at_locs.csv",sep="")))
  ## 5) imputation
  model_fPCA_gcv$results$X_imputed <- as.matrix(read.csv(paste(script_path,"/test-results/imputation.csv",sep="")))
  
  ## add flag
  model_fPCA_gcv$model_traits$is_functional <- F
  model_fPCA_gcv$model_traits$has_interpolator <- F
  
  ## add execution time to results
  model_fPCA_gcv$results$execution_time <- end.time - start.time
  
  ## save fitted model
  save(
    index_batch = i,
    model_fPCA_gcv,
    file = file_model
  )
}
if(!is.null(model_fPCA_gcv)) {
  ## model evaluation
  results_evaluation$fpca_gcv <- evaluate_results(model_fPCA_gcv, generated_data)
  
  ## clean the workspace
  rm(model_fPCA_gcv)
}


### Model fPCA-centering (gcv calibration) ----
model_fPCA_gcv_center <- NULL
file_model <- paste(path_batch, "batch_", i, "_fitted_model_fpca_gcv_center.RData", sep = "")
if (file.exists(file_model) && !FORCE_FIT) {
  if(FORCE_EVALUATE) {
    cat("- Loading fitted fPCA center (gcv calibration) ... \n")
    load(file_model)
  }
} else if ("fpca_gcv_center" %in% names_models) {
  cat("- Fitting fPCA center (gcv calibration) ... ")
  
  ## model fit
  start.time <- Sys.time()
  script_path <- "/Users/marcogalliani/Projects/fdaPDE-test-bench/tests/fpca-missing/cpp-scripts/fpca-gcv-centering"
  system(paste("cd ",script_path,"; ./fpca_gcv",sep=""),ignore.stdout = T)
  
  end.time <- Sys.time()
  cat(paste("finished after", end.time - start.time, attr(end.time - start.time, "units"), "\n"))
  
  ## save results
  ## 1) mean
  model_fPCA_gcv_center$results$X_mean <- as.matrix(read.csv(paste(script_path,"/test-results/center.csv",sep="")))
  model_fPCA_gcv_center$results$X_mean_locs <- as.matrix(read.csv(paste(script_path,"/test-results/center_locs.csv",sep="")))
  ## 2) loadings
  model_fPCA_gcv_center$results$loadings <- as.matrix(read.csv(paste(script_path,"/test-results/loadings.csv",sep="")))
  model_fPCA_gcv_center$results$loadings_locs <- as.matrix(read.csv(paste(script_path,"/test-results/loadings_locs.csv",sep="")))
  ## 3) scores
  model_fPCA_gcv_center$results$scores <- as.matrix(read.csv(paste(script_path,"/test-results/scores.csv",sep="")))
  ## 4) reconstruction
  model_fPCA_gcv_center$results$X_hat <- as.matrix(read.csv(paste(script_path,"/test-results/reconstruction.csv",sep="")))
  model_fPCA_gcv_center$results$X_hat_locs <- as.matrix(read.csv(paste(script_path,"/test-results/reconstruction_at_locs.csv",sep="")))
  ## 5) imputation
  model_fPCA_gcv_center$results$X_imputed <- as.matrix(read.csv(paste(script_path,"/test-results/imputation.csv",sep="")))
  
  ## add flag
  model_fPCA_gcv_center$model_traits$is_functional <- F
  model_fPCA_gcv_center$model_traits$has_interpolator <- F
  
  ## add execution time to results
  model_fPCA_gcv_center$results$execution_time <- end.time - start.time
  
  ## save fitted model
  save(
    index_batch = i,
    model_fPCA_gcv_center,
    file = file_model
  )
}
if(!is.null(model_fPCA_gcv_center)) {
  ## model evaluation
  results_evaluation$fpca_gcv_center <- evaluate_results(model_fPCA_gcv_center, generated_data)
  
  ## clean the workspace
  rm(model_fPCA_gcv_center)
}

### Model dineof + fPCA----
model_dineof_fpca <- NULL
file_model <- paste(path_batch, "batch_", i, "_fitted_model_dineof_fpca.RData", sep = "")
if (file.exists(file_model) && !FORCE_FIT) {
  if(FORCE_EVALUATE) {
    cat("- Loading fitted dineof_fpca ... \n")
    load(file_model)
  }
} else if ("dineof_fpca" %in% names_models) {
  cat("- Fitting dineof_fpca ... ")
  
  ## model fit
  start.time <- Sys.time()
  dineof_fit <- sinkr::dineof(data$X)
  write.csv(format(as.matrix(dineof_fit$Xa), digits = 16),
            paste(data_path,"y.csv",sep=""))
  script_path <- "/Users/marcogalliani/Projects/fdaPDE-test-bench/tests/fpca-missing/cpp-scripts/fpca-gcv-centering"
  system(paste("cd ",script_path,"; ./fpca_gcv",sep=""),ignore.stdout = T)
  end.time <- Sys.time()
  cat(paste("finished after", end.time - start.time, attr(end.time - start.time, "units"), "\n"))
  # return to initial data
  write.csv(format(as.matrix(data$X), digits = 16),
            paste(data_path,"y.csv",sep=""))
  
  ## save results
  ## 1) mean
  model_dineof_fpca$results$X_mean <- as.matrix(read.csv(paste(script_path,"/test-results/center.csv",sep="")))
  model_dineof_fpca$results$X_mean_locs <- as.matrix(read.csv(paste(script_path,"/test-results/center_locs.csv",sep="")))
  ## 2) loadings
  model_dineof_fpca$results$loadings <- as.matrix(read.csv(paste(script_path,"/test-results/loadings.csv",sep="")))
  model_dineof_fpca$results$loadings_locs <- as.matrix(read.csv(paste(script_path,"/test-results/loadings_locs.csv",sep="")))
  ## 3) scores
  model_dineof_fpca$results$scores <- as.matrix(read.csv(paste(script_path,"/test-results/scores.csv",sep="")))
  ## 4) reconstruction
  model_dineof_fpca$results$X_hat <- as.matrix(read.csv(paste(script_path,"/test-results/reconstruction.csv",sep="")))
  model_dineof_fpca$results$X_hat_locs <- as.matrix(read.csv(paste(script_path,"/test-results/reconstruction_at_locs.csv",sep="")))
  ## 5) imputation
  model_dineof_fpca$results$X_imputed <- as.matrix(read.csv(paste(script_path,"/test-results/imputation.csv",sep="")))
  
  ## add flag
  model_dineof_fpca$model_traits$is_functional <- F
  model_dineof_fpca$model_traits$has_interpolator <- F
  
  ## add execution time to results
  model_dineof_fpca$results$execution_time <- end.time - start.time
  
  ## save fitted model
  save(
    index_batch = i,
    model_dineof_fpca,
    file = file_model
  )
}
if(!is.null(model_dineof_fpca)) {
  ## model evaluation
  results_evaluation$dineof_fpca <- evaluate_results(model_dineof_fpca, generated_data)
  ## clean the workspace
  rm(model_dineof_fpca)
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

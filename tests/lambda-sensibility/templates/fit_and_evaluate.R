## room for solutions
results_evaluation <- list()
data_path <- paste(cpp_scripts_path,"data/",sep="")
uncal_fpca_path <- paste(cpp_scripts_path,"uncalibrated-fpca/",sep="")

## load results_evaluation if available
if (file.exists(paste(path_batch, "batch_", i, "_results_evaluation.RData", sep = ""))) {
  load(paste(path_batch, "batch_", i, "_results_evaluation.RData", sep = ""))
}


for(solver_name in names_models){
  model_fPCA <- NULL
  file_model <- paste(path_batch, "batch_", i, "_fitted_model_fpca_",solver_name,".RData", sep = "")
  if (file.exists(file_model) && !FORCE_FIT) {
    if(FORCE_EVALUATE) {
      cat("- Loading fitted fPCA ... \n")
      load(file_model)
    }
  } else {
    cat("- Fitting fPCA ", solver_name, " ... ")
    ## model fit
    params_json$RunParams$fpca_solver <- solver_name
    write_json(path = paste(uncal_fpca_path, "params.json", sep = ""), 
               params_json, auto_unbox=T, pretty=T, digits=10
    )
    start.time <- Sys.time()
    system(paste("cd ",uncal_fpca_path,"; ./uncalibrated_fpca",sep=""), ignore.stdout = T)
    end.time <- Sys.time()
    cat(paste("finished after", end.time - start.time, attr(end.time - start.time, "units"), "\n"))
    
    ## save results
    ## 1) mean (in this case we're assuming zero-mean data)
    #model_fPCA$results$X_mean <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/center.csv",sep="")))
    #model_fPCA$results$X_mean_locs <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/center_locs.csv",sep="")))
    ## 2) loadings
    model_fPCA$results$loadings <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/loadings.csv",sep="")))
    model_fPCA$results$loadings_locs <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/loadings_locs.csv",sep="")))
    model_fPCA$results$loadings_norms <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/loadings_norms.csv",sep="")))
    ## 3) scores
    model_fPCA$results$scores <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/scores.csv",sep="")))
    ## 4) reconstruction
    model_fPCA$results$X_hat <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/reconstruction.csv",sep="")))
    model_fPCA$results$X_hat_locs <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/reconstruction_at_locs.csv",sep="")))
    ## 5) lambda
    model_fPCA$results$lambda <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/lambda.csv",sep="")))

    ## add flag
    model_fPCA$model_traits$is_functional <- F
    model_fPCA$model_traits$has_interpolator <- F
    
    ## add execution time to results
    model_fPCA$results$execution_time <- end.time - start.time
    
    assign(paste("model_fPCA_",solver_name,sep=""), model_fPCA)
    ## save fitted model
    save(
      index_batch = i,
      list = paste("model_fPCA_",solver_name,sep=""),
      file = file_model
    )
    rm(list = paste("model_fPCA_",solver_name,sep=""))
    
  }
  if(!is.null(model_fPCA)) {
    ## model evaluation
    results_evaluation[[solver_name]] <- evaluate_results(model_fPCA, generated_data)
    
    ## clean the workspace
    rm(model_fPCA)
  }
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

cat(paste("- Batch", i, "completed.\n"))

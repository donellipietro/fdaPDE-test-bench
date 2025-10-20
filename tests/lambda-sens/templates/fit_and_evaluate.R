fit_and_evaluate_models <- function(path_list, 
                                    generated_data,
                                    domain,
                                    batch_index,
                                    test_options,
                                    FORCE_EVALUATE, FORCE_FIT){
  
  ## paths----
  data_path <- path_list$data_path
  mesh_path <- path_list$mesh_path
  uncal_fpca_path <- paste(path_list$cpp_scripts_path,"uncalibrated-fpca/",sep="")
  path_batch <- paste(path_list$path_results, "batch_", batch_index, "/", sep = "")
  
  ## cpp params json
  cpp_params_json <- fromJSON(paste(uncal_fpca_path, "params.json", sep = ""))
  
  ## room for solutions
  results_evaluation <- list()
  
  ## write data for cpp-scripts----
  ## data matrix, locations
  write.csv(format(generated_data$X,digits=16), 
            file = paste(data_path,"/y.csv",sep=""))
  write.csv(format(generated_data$locations,digits=16), 
            file = paste(data_path,"/locs.csv",sep=""))
  ## mesh
  mesh <- generated_domain$fdapde_mesh
  write.csv(format(mesh$nodes, digits = 16), paste(mesh_path,"/points.csv", sep = ""))
  write.csv(format(mesh$triangles, digits = 16), paste(mesh_path,"/elements.csv", sep = ""))
  write.csv(format(1 * mesh$nodesmarkers, digits = 16), paste(mesh_path,"/boundary.csv", sep = ""))
  write.csv(format(mesh$neighbors, digits = 16), paste(mesh_path,"/neigh.csv", sep = ""))
  write.csv(format(mesh$edges, digits = 16), paste(mesh_path,"/edges.csv", sep = ""))
  
  ## load results_evaluation if available----
  if (file.exists(paste(path_batch, "batch_", batch_index, "_results_evaluation.RData", sep = ""))) {
    load(paste(path_batch, "batch_", batch_index, "_results_evaluation.RData", sep = ""))
  }
  ## fit & evaluate----
  for(solver_name in test_options$model_names){
    model_fPCA <- NULL
    file_model <- paste(path_batch, "batch_", batch_index, "_fitted_model_fpca_",solver_name,".RData", sep = "")
    if (file.exists(file_model) && !FORCE_FIT) {
      if(FORCE_EVALUATE) {
        cat("- Loading fitted fPCA ... \n")
        load(file_model)
      }
    } else {
      cat("- Fitting fPCA ", solver_name, " ... ")
      ## model fit
      cpp_params_json$RunParams$fpca_solver <- solver_name
      cpp_params_json$RunParams$lambda_grid <- I(test_options$regularization$lambda)
      write_json(path = paste(uncal_fpca_path, "params.json", sep = ""), 
                 cpp_params_json, auto_unbox=T, pretty=T, digits=10)
      start.time <- Sys.time()
      system(paste("cd ",uncal_fpca_path,"; ./uncalibrated_fpca",sep=""), ignore.stdout = T)
      end.time <- Sys.time()
      cat(paste("finished after", end.time - start.time, attr(end.time - start.time, "units"), "\n"))
      ## save results
      ## 1) mean (in this case we're assuming zero-mean data)
      # model_fPCA$results$X_mean <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/center.csv",sep="")))
      # model_fPCA$results$X_mean_locs <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/center_locs.csv",sep="")))
      ## 2) loadings
      model_fPCA$results$loadings <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/loadings.csv",sep="")))
      model_fPCA$results$loadings_locs <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/loadings_locs.csv",sep="")))
      #model_fPCA$results$loadings_norms <- as.matrix(read.csv(paste(uncal_fpca_path,"/test-results/loadings_norms.csv",sep="")))
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
        index_batch = batch_index,
        list = paste("model_fPCA_",solver_name,sep=""),
        file = file_model
      )
      rm(list = paste("model_fPCA_",solver_name,sep=""))
      
    }
    if(!is.null(model_fPCA)) {
      ## model evaluation
      results_evaluation[[solver_name]] <- evaluate_results(model_fPCA, generated_data)
    }
  }
  
  ### save results evaluation ----
  save(
    ## batch index
    index_batch = batch_index,
    ## results
    results_evaluation,
    ## path
    file = paste(path_batch, "batch_", batch_index, "_results_evaluation.RData", sep = "")
  )
  cat(paste("- Batch", batch_index, "completed.\n"))
}
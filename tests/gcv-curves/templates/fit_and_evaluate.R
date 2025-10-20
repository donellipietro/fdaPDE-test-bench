fit_and_evaluate_models <- function(path_list, 
                                    model_names, 
                                    generated_data,
                                    mesh,
                                    batch_index,
                                    params_json,
                                    lambda_grid,
                                    FORCE_EVALUATE = F, FORCE_FIT = F){
  
  ## paths
  data_path <- path_list$data_path
  mesh_path <- path_list$mesh_path
  cal_fpca_path <- paste(path_list$cpp_scripts_path,"calibrated-fpca/",sep="")
  uncal_fpca_path <-  paste(path_list$cpp_scripts_path,"uncalibrated-fpca/",sep="")
  path_batch <- paste(path_list$path_results, "batch_", batch_index, "/", sep = "")
  
  ## room for solutions
  results_evaluation <- list()
  
  ## Write data for cpp-scripts
  ## data matrix, locations
  write.csv(format(generated_data$X,digits=16), 
            file = paste(data_path,"/y.csv",sep=""))
  write.csv(format(locations,digits=16), 
            file = paste(data_path,"/locs.csv",sep=""))
  ## mesh
  write.csv(format(mesh$nodes, digits = 16), paste(mesh_path,"/points.csv", sep = ""))
  write.csv(format(mesh$triangles, digits = 16), paste(mesh_path,"/elements.csv", sep = ""))
  write.csv(format(1 * mesh$nodesmarkers, digits = 16), paste(mesh_path,"/boundary.csv", sep = ""))
  write.csv(format(mesh$neighbors, digits = 16), paste(mesh_path,"/neigh.csv", sep = ""))
  write.csv(format(mesh$edges, digits = 16), paste(mesh_path,"/edges.csv", sep = ""))
  
  ## load results_evaluation if available
  if (file.exists(paste(path_batch, "batch_", batch_index, "_results_evaluation.RData", sep = ""))) {
    load(paste(path_batch, "batch_", batch_index, "_results_evaluation.RData", sep = ""))
  }
  
  for(solver_name in model_names){
    ### fPCA power ----
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
      params_json$RunParams$fpca_solver <- solver_name
      write_json(path = paste(cal_fpca_path, "params.json", sep = ""), 
                 params_json, auto_unbox=T, pretty=T, digits=10
      )
      start.time <- Sys.time()
      system(paste("cd ",cal_fpca_path,"; ./calibrated_fpca",sep=""), ignore.stdout = T)
      end.time <- Sys.time()
      cat(paste("finished after", end.time - start.time, attr(end.time - start.time, "units"), "\n"))
      
      ## save results
      model_fPCA$results$gcv_scores <- as.matrix(read.csv(paste(cal_fpca_path,"/test-results/gcv_scores.csv",sep="")))
      
      ## true mse
      mse <- numeric(length(lambda_grid))
      for(j in 1:length(lambda_grid)){
        params_json$RunParams$lambda_grid <- I(lambda_grid[j])
        write_json(path = paste(uncal_fpca_path, "params.json", sep = ""), 
                   params_json, auto_unbox=T, pretty=T, digits=10
        )
        system(paste("cd ",uncal_fpca_path,"; ./uncalibrated_fpca",sep=""), ignore.stdout = T)
        X_hat <- as.matrix(read.csv(paste(uncal_fpca_path,"test-results/reconstruction_at_locs.csv",sep="")))
        mse[j] <- mean((X_hat-generated_data$X_true_locs)^2)
      }
      # recover the lambda grid
      params_json$RunParams$lambda_grid <- lambda_grid
      write_json(path = paste(uncal_fpca_path, "params.json", sep = ""), 
                 params_json, auto_unbox=T, pretty=T, digits=10
      )
      
      model_fPCA$results$mse <- mse
      
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
    }
    if(!is.null(model_fPCA)) {
      ## model evaluation
      results_evaluation[[solver_name]] <- model_fPCA$results
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
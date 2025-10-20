## Quantitative analysis----
load_quantitative_results <- function(batch_index, 
                         model_names, 
                         path_list, 
                         name_test
                         ){
  cat("\nLoading results for quantitative analysis ...\n")
  ## Path
  path_batch <- paste(path_list$path_results, "batch_", batch_index, "/", sep = "")
  
  ## room for solutions
  names_columns <- c("Group", model_names)
  empty_df <- data.frame(matrix(NaN, nrow = 0, ncol = length(names_columns)))
  colnames(empty_df) <- names_columns
  
  gcv_scores <- list()
  ## load batch and log if not present
  tryCatch(
    {
      load(paste(path_batch, "batch_", batch_index, "_results_evaluation.RData", sep = ""))
    },
    error = function(e) {
      cat(paste("Error in test ", name_test, " - batch ", batch_index, ": ", conditionMessage(e), "\n", sep = ""))
    }
  )
  ## gcv_scores: results_evaluation comes from the .RData previously loaded
  gcv_scores <- extract_new_results(results_evaluation, model_names, "gcv_scores")
  mse <- extract_new_results(results_evaluation, model_names, "mse")
  cat(paste("- Batch", batch_index, "loaded\n"))
  
  return(list(
    gcv_scores = gcv_scores,
    mse = mse
  ))
}


## Qualitative analysis ----
load_qualitative_results <- function(batch_index, 
                                     model_names, 
                                     path_list, 
                                     name_test, 
                                     FEM_eval_tools){
  
  cat("\nLoading results for qualitative analysis ...\n")
  ## Path
  path_batch <- paste(path_results, "batch_", batch_index, "/", sep = "")
  ## room for solutions
  scores <- list()
  loadings <- list()
  loadings_locs <- list()
  loadings_HR <- list()
  
  ## FEM eval tools
  domain <- FEM_eval_tools$domain #femR object
  n_nodes <- nrow(domain$nodes())
  locations <- FEM_eval_tools$locations
  n_locs <- nrow(locations)
  n_comp <- FEM_eval_tools$n_comp
  loadings_true_generator <- FEM_eval_tools$loadings_true_generator
  HR_grid <- FEM_eval_tools$HR_grid
  
  ## -> extracting the mass matrix  
  Vh <- FunctionSpace(domain, fe_order=1)
  u <- Function(Vh)
  Lu <- -laplace(u) ## poisson problem
  f <- function(points) { return(0*points[,1])}
  pde <- Pde(Lu, f)
  
  ## load batch and log if not present
  tryCatch(
    {
      for(name_model in model_names) {
        load(paste(path_batch, "batch_", batch_index, "_fitted_model_fpca_", name_model, ".RData", sep = ""))
      }
    },
    error = function(e) {
      cat(paste("Error in test ", name_test, " - batch ", batch_index, ": ", conditionMessage(e), "\n", sep = ""))
    }
  )
  ## adjust loadings true
  loadings_true <- matrix(0, nrow = n_nodes, ncol = n_comp)
  loadings_true_locs <- matrix(0, nrow = nrow(locations), ncol = n_comp)
  loadings_true_HR <- matrix(0, nrow = nrow(HR_grid), ncol = n_comp)
  for (i in 1:n_comp) {
    loadings_true[, i] <- loadings_true_generator(mesh$nodes, i)
    norm <- norm_L2(loadings_true[, i], pde$mass())
    loadings_true[, i] <- loadings_true[, i] / norm
    loadings_true_locs[, i] <- loadings_true_generator(locations, i) / norm
    loadings_true_HR[, i] <- loadings_true_generator(HR_grid, i) / norm
  }
  for(model_name in model_names){
    # retrieve model
    model <- get(paste("model_fPCA_",model_name,sep=""))
    # evaluate at grid
    loads_HR <- matrix(nrow = nrow(HR_grid), ncol = n_comp)
    for(fpc_idx in 1:n_comp){
      loads_HR[,fpc_idx] <- evaluate_field(HR_grid, model$results$loadings[,fpc_idx], mesh)
    } 
    # adjust sign
    adjusted_result <- adjust_results(
      model$results$loadings_locs, 
      model$results$scores,
      loadings_true_locs,
      list(
        loadings = model$results$loadings,
        loadings_HR = loads_HR
      ))
    # save adjusted results
    scores[[model_name]][[i]] <- adjusted_result$scores
    loadings[[model_name]][[i]] <- adjusted_result$loadings_evaluated_list$loadings
    loadings_locs[[model_name]][[i]] <- adjusted_result$loadings_locs
    loadings_HR[[model_name]][[i]] <- adjusted_result$loadings_evaluated_list$loadings_HR
  }
  cat(paste("- Batch", batch_index, "loaded\n"))
  return(list(
    scores = scores, 
    loadings = loadings, loadings_locs = loadings_locs,
    loadings_HR = loadings_HR
  ))
}







# performances evaluation ----

## utils
evaluate_results <- function(model, generated_data) {
  
  ## execution time
  execution_time <- model$results$execution_time
  
  ## room for results
  rmse <- list()
  irmse <- list()
  
  # centering at mesh nodes
  norm <- ifelse(RMSE(generated_data$X_mean_true) == 0, 1, RMSE(generated_data$X_mean_true))
  rmse$centering <- RMSE(model$results$X_mean - generated_data$X_mean_true) / norm
  
  # centering at locations  
  norm <- ifelse(RMSE(generated_data$X_mean_true_locs) == 0, 1, RMSE(generated_data$X_mean_true_locs))
  rmse$centering_locs <- RMSE(model$results$X_mean_locs - generated_data$X_mean_true_locs) / norm
  
  ## IRMSE (if possible)
  if (model$model_traits$is_functional) {
    
  }
  return(list(
    execution_time = execution_time,
    rmse = rmse,
    irmse = irmse
  ))
}
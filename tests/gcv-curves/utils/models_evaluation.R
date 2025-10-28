# = ========================================================================== =
# - Script: mnodels_evaluation.R
# - Desc: Utilities for adjusting model outputs and evaluating performance
#         via RMSE/IRMSE and angular measures on loadings and subspaces.
# = ========================================================================== =


# - Function: evaluate_results
# - Args:
#   * model: fitted model object with $results and $model_traits fields
#   * data: list from data generator with true quantities
# - Desc:
#   Return GCV scores and true MSE with varying lambda
evaluate_results <- function(model, data) {
  return(list(
    execution_time = model$results$execution_time,
    gcv_scores = model$results$gcv_scores,
    mse = model$results$mse
  ))
}
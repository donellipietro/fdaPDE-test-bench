# = ========================================================================== =
# - Script: models_evaluation.R
# - Desc: Evaluates smoothing accuracy and exposes per-fit telemetry.
# = ========================================================================== =

## Function: normalized_rmse
# - Desc:
#   Computes RMSE(f_hat, f) / sqrt(mean((f - mean(f))^2)) on the common grid.
normalized_rmse <- function(estimate, truth) {
  sqrt(mean((estimate - truth)^2)) / sqrt(mean((truth - mean(truth))^2))
}

## Function: evaluate_results
# - Args:
#   * model: fitted model object returned by fit_model
#   * data: generated data containing the dense-grid truth
# - Desc:
#   Returns fit metrics and the realized data-generating quantities in the
#   standard nested structure loaded by the shared aggregation utilities.
evaluate_results <- function(model, data) {
  list(
    seed = data$seed,
    signal_variance = data$signal_variance,
    noise_sigma = data$noise_sigma,
    coefficients = list(
      sin_2pi = data$coefficients[1],
      sin_4pi = data$coefficients[2],
      sin_8pi = data$coefficients[3]
    ),
    execution_time = model$results$execution_time,
    peak_ram_mib = model$results$peak_ram_mib,
    cpu_seconds = model$results$cpu_seconds,
    cpu_usage_percent = model$results$cpu_usage_percent,
    setup_seconds = model$results$setup_seconds,
    gcv_seconds = model$results$gcv_seconds,
    final_fit_seconds = model$results$final_fit_seconds,
    solver_seconds = model$results$solver_seconds,
    prediction_seconds = model$results$prediction_seconds,
    n_basis = model$results$n_basis,
    linear_system_dimension = model$results$linear_system_dimension,
    lambdas = model$results$lambda,
    gcv = model$results$gcv,
    rmse = list(
      normalized = normalized_rmse(model$results$prediction, data$truth_evaluation)
    )
  )
}

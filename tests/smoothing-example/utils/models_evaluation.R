normalized_rmse <- function(estimate, truth) {
  sqrt(mean((estimate - truth)^2)) / sqrt(mean((truth - mean(truth))^2))
}

evaluate_results <- function(model, data) {
  list(
    execution_time = model$results$execution_time,
    peak_ram_mib = model$results$peak_ram_mib,
    cpu_seconds = model$results$cpu_seconds,
    cpu_usage_percent = model$results$cpu_usage_percent,
    lambdas = model$results$lambda,
    gcv = model$results$gcv,
    rmse = list(
      normalized = normalized_rmse(model$results$prediction, data$truth_evaluation)
    )
  )
}

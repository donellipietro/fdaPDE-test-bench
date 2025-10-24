# = ========================================================================== =
# - Script: mnodels_evaluation.R
# - Desc: Utilities for adjusting model outputs and evaluating performance
#         via RMSE/IRMSE and angular measures on loadings and subspaces.
# = ========================================================================== =


# - Function: adjust_norms
# - Args:
#   * FF: matrix of loadings evaluated at locations (n_locs x n_comp)
#   * SS: matrix of scores (n_stat_units x n_comp)
# - Desc:
#   Adjusts loadings and scores by component-wise norms to keep reconstruction
#   invariant. Returns adjusted loadings at locations, scores, and the norms.
adjust_norms <- function(FF, SS) {
  ## Number of components
  n_comp <- ncol(SS)
  ## Component norms (placeholder as in original code)
  f_norms <- ones(ncol(FF))
  for (h in 1:n_comp) {
    f_norms[h] <- norm_l2(FF[, h])
    FF[, h] <- FF[, h] / f_norms[h]
    SS[, h] <- SS[, h] * f_norms[h]
  }
  return(list(loadings_locs = FF, scores = SS, norms = f_norms))
}


# - Function: adjust_results
# - Args:
#   * F_hat_locs: estimated loadings at locations (n_locs x n_comp)
#   * S_hat: estimated scores (n_stat_units x n_comp)
#   * F_true_locs: true loadings at locations (n_locs x n_comp)
#   * Fs_hat_evaluated: optional list of loadings evaluated on nodes (for functional metrics)
# - Desc:
#   Aligns the sign of estimated components to match the true ones, normalizes
#   results at locations, and adjusts node-evaluated loadings accordingly.
adjust_results <- function(F_hat_locs, S_hat, F_true_locs, Fs_hat_evaluated = NULL) {
  
  ## Number of components
  n_comp <- ncol(S_hat)
  
  ## Change signs to match the true ones
  for (h in 1:n_comp) {
    if (RMSE(F_hat_locs[, h] + F_true_locs[, h]) < RMSE(F_hat_locs[, h] - F_true_locs[, h])) {
      F_hat_locs[, h] <- -F_hat_locs[, h]
      S_hat[, h] <- -S_hat[, h]
      if (!is.null(Fs_hat_evaluated)) {
        for (i in 1:length(Fs_hat_evaluated)) {
          Fs_hat_evaluated[[i]][, h] <- -Fs_hat_evaluated[[i]][, h]
        }
      }
    }
  }
  
  ## Normalize results at locations
  adjusted_results <- adjust_norms(F_hat_locs, S_hat)
  
  ## Adjust data at nodes accordingly
  for (h in 1:n_comp) {
    if (!is.null(Fs_hat_evaluated)) {
      for (i in 1:length(Fs_hat_evaluated)) {
        Fs_hat_evaluated[[i]][, h] <- Fs_hat_evaluated[[i]][, h] / adjusted_results$norms[h]
      }
    }
  }
  
  return(list(
    loadings_locs = adjusted_results$loadings_locs,
    scores = adjusted_results$scores,
    loadings_evaluated_list = Fs_hat_evaluated
  ))
}


# - Function: evaluate_results
# - Args:
#   * model: fitted model object with $results and $model_traits fields
#   * data: list from data generator with true quantities
# - Desc:
#   Computes RMSE/IRMSE metrics for centering, loadings, scores, and
#   reconstructions; and angular measures for components and subspaces.
evaluate_results <- function(model, data) {
  
  ## Number of computed components ----
  n_comp <- data$dimensions$n_comp
  
  ## Room for results ----
  rmse <- list()
  irmse <- list()
  angles <- list()
  lambdas <- numeric(n_comp)
  
  ## Execution time ----
  execution_time <- model$results$execution_time
  
  ## Lambdas ----
  lambdas <- as.vector(model$results$lambda)
  
  ## RMSE at locations ----
  
  ## Centering
  if (!is.null(model$results$X_mean_locs)) {
    norm <- ifelse(RMSE(data$X_mean_true_locs) == 0, 1, RMSE(data$X_mean_true_locs))
    rmse$centering_locs <- RMSE(model$results$X_mean_locs - data$X_mean_true_locs) / norm
  }
  
  ### Loadings & scores ----
  if (!is.null(model$results$loadings)) {
    Fs_hat_evaluated <- list(loadings = model$results$loadings)
  } else {
    Fs_hat_evaluated <- NULL
  }
  adjusted_results <- adjust_results(
    model$results$loadings_locs,
    model$results$scores,
    data$loadings_true_locs,
    Fs_hat_evaluated
  )
  for (h in 1:n_comp) {
    norm <- RMSE(data$loadings_true_locs[, h])
    rmse$loadings_locs[h] <- RMSE(adjusted_results$loadings_locs[, h] - data$loadings_true_locs[, h]) / norm
    norm <- RMSE(data$scores_true[, h])
    rmse$scores[h] <- RMSE(adjusted_results$scores[, h] - data$scores_true[, h]) / norm
  }
  scores_normalized <- adjusted_results$scores
  scores_norms <- apply(scores_normalized, MARGIN = 2, function(x) { sqrt(sum(x^2)) })
  scores_normalized <- sweep(scores_normalized, MARGIN = 2, scores_norms, FUN = "/")
  rmse$scores_orth <- RMSE(diag(n_comp) - t(scores_normalized) %*% scores_normalized)
  
  ### Data reconstruction ----
  norm <- RMSE(data$X_true_locs)
  rmse$reconstruction_locs <- RMSE(model$results$X_hat_locs - data$X_true_locs) / norm
  
  ### RMSE at nodes (if possible) ----
  if (model$model_traits$has_interpolator) {
    norm <- ifelse(RMSE(data$X_mean_true) == 0, 1, RMSE(data$X_mean_true))
    rmse$centering <- RMSE(model$results$X_mean - data$X_mean_true) / norm
    for (h in 1:n_comp) {
      norm <- RMSE(data$loadings_true[, h])
      rmse$loadings[h] <- RMSE(adjusted_results$loadings_evaluated_list$loadings[, h] - data$loadings_true[, h]) / norm
    }
    norm <- RMSE(data$X_true)
    rmse$reconstruction <- RMSE(model$results$X_hat - data$X_true) / norm
  }
  
  ## IRMSE (if possible) ----
  if (model$model_traits$is_functional) {
    if (!is.null(model$results$X_mean)) {
      norm <- IRMSE(data$X_mean_true, model$R0())
      norm <- ifelse(norm == 0, 1, norm)
      irmse$centering <- IRMSE(model$results$X_mean - data$X_mean_true, model$R0()) / norm
    }
    for (h in 1:n_comp) {
      norm <- IRMSE(data$loadings_true[, h], model$R0())
      irmse$loadings[h] <- IRMSE(adjusted_results$loadings_evaluated_list$loadings[, h] - data$loadings_true[, h], model$R0()) / norm
    }
    norm <- IRMSE(t(data$X_true), model$R0())
    irmse$reconstruction <- IRMSE(t(model$results$X_hat - data$X_true), model$R0()) / norm
  }
  
  ## Angles ----
  for (h in 1:n_comp) {
    angles$subspaces_m[h] <- 180 * subspace(adjusted_results$loadings_locs[, 1:h], data$loadings_true_locs[, 1:h]) / pi
    angles$components_m[h] <- 180 * subspace(adjusted_results$loadings_locs[, h], data$loadings_true_locs[, h]) / pi
    if (model$model_traits$is_functional) {
      angles$components_f[h] <- 180 * angle_between_functions(
        adjusted_results$loadings_evaluated_list$loadings[, h],
        data$loadings_true[, h],
        model$R0()
      ) / pi
    }
    if (h < n_comp) {
      for (j in (h + 1):n_comp) {
        angles$orthogonality_m[h + j - 2] <- 180 * subspace(adjusted_results$loadings_locs[, h], adjusted_results$loadings_locs[, j]) / pi
        if (model$model_traits$is_functional) {
          angles$orthogonality_f[h + j - 2] <- 180 * angle_between_functions(
            adjusted_results$loadings_evaluated_list$loadings[, h],
            adjusted_results$loadings_evaluated_list$loadings[, j],
            model$R0()
          ) / pi
        }
      }
    }
  }
  
  return(list(
    execution_time = execution_time,
    lambdas = lambdas,
    rmse = rmse,
    irmse = irmse,
    angles = angles
  ))
}
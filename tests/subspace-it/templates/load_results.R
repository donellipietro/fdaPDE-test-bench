
cat("\nLoading results for quantitative analysis ...\n")

## room for solutions
names_columns <- c("Group", names_models)
empty_df <- data.frame(matrix(NaN, nrow = 0, ncol = length(names_columns)))
colnames(empty_df) <- names_columns
times <- empty_df
rmses <- list()
irmses <- list()
angles <- list()
lambdas <- list()

## laod pers' results seqly
for (i in 1:n_reps) {
  ## laod batch and log if not present
  tryCatch(
    {
      path_batch <- paste(path_results, "batch_", i, "/", sep = "")
      load(paste(path_batch, "batch_", i, "_results_evaluation.RData", sep = ""))
    },
    error = function(e) {
      cat(paste("Error in test ", name_test, " - batch ", i, ": ", conditionMessage(e), "\n", sep = ""))
    }
  )
  
  ## times
  times <- add_results(
    times, extract_new_results(results_evaluation, names_models, "execution_time"),
    names_columns
  )
  ## lambdas
  lambdas <- add_results(
    lambdas,extract_new_results(results_evaluation, names_models, "lambdas"),
    names_columns)
  ## rmse
  for (name in c("centering", "centering_locs", "loadings", "loadings_locs", "scores","proj_scores", "reconstruction", "reconstruction_locs")) {
    rmses[[name]] <- add_results(
      rmses[[name]], extract_new_results(results_evaluation, names_models, c("rmse", name)),
      names_columns
    )
  }
  ## irmse
  for (name in c("centering", "loadings", "reconstruction")) {
    irmses[[name]] <- add_results(
      irmses[[name]], extract_new_results(results_evaluation, names_models, c("irmse", name)),
      names_columns
    )
  }
  ## angles
  for (name in c("subspaces_m", "components_m", "components_f", "orthogonality_m", "orthogonality_f")) {
    angles[[name]] <- add_results(
      angles[[name]], extract_new_results(results_evaluation, names_models, c("angles", name)),
      names_columns
    )
  }
  cat(paste("- Batch", i, "loaded\n"))
}



if(RUN$qualitative_analysis) {
  cat("\nLoading results for qualitative analysis ...\n")
  
  ## room for solutions
  scores <- list()
  loadings <- list()
  loadings_locs <- list()
  loadings_HR <- list()
  
  ## load batches
  for (i in 1:n_reps) {
    
    ## laod batch and log if not present
    tryCatch(
      {
        path_batch <- paste(path_results, "/", "batch_", i, "/", sep = "")
        for(name_model in names_models) {
          load(paste(path_batch, "batch_", i, "_fitted_model_", name_model, ".RData", sep = ""))
        }
      },
      error = function(e) {
        cat(paste("Error in test ", name_test, " - batch ", i, ": ", conditionMessage(e), "\n", sep = ""))
      }
    )

    ## adjust loadings true
    loadings_true_locs <- cbind(
      loadings_true_generator(locations, 1),
      loadings_true_generator(locations, 2),
      loadings_true_generator(locations, 3)
    )
    loadings_true <- cbind(
      loadings_true_generator(domain$nodes, 1),
      loadings_true_generator(domain$nodes, 2),
      loadings_true_generator(domain$nodes, 3)
    )
    loadings_true_HR <- cbind(
      loadings_true_generator(grid, 1),
      loadings_true_generator(grid, 2),
      loadings_true_generator(grid, 3)
    )
    norms <- c()
    for(h in 1:ncol(loadings_true_locs)) {
      norms[h] <- norm_l2(loadings_true_locs[, h])
      loadings_true_locs[, h] <- loadings_true_locs[, h] / norms[h]
      loadings_true[, h] <- loadings_true[, h] / norms[h]
      loadings_true_HR[, h] <- loadings_true_HR[, h] / norms[h]
    }
    
    ## ajust loadings model_MV_PCA
    adjusted_results_DINEOF <- adjust_results(
      model_DINEOF$results$loadings_locs, 
      model_DINEOF$results$scores,
      loadings_true_locs)
    
    # ajust loadings model_fPCA_kcv
    adjusted_results_fPCA_kcv <- adjust_results(
      model_fPCA_kcv$results$loadings_locs,
      model_fPCA_kcv$results$scores,
      loadings_true_locs)
    
    ## ajust loadings model_fPCA_gcv
  
    adjusted_results_fPCA_gcv <- adjust_results(
      model_fPCA_gcv_center$results$loadings_locs, 
      model_fPCA_gcv_center$results$scores,
      loadings_true_locs)
    
    ## save adjusted loadings at locations
    scores$dineof[[i]] <- adjusted_results_DINEOF$scores
    loadings_locs$dineof[[i]] <- adjusted_results_DINEOF$loadings_locs
    scores$fpca_kcv[[i]] <- adjusted_results_fPCA_kcv$scores
    loadings_locs$fpca_kcv[[i]] <- adjusted_results_fPCA_kcv$loadings_locs
    scores$fpca_gcv_center[[i]] <- adjusted_results_fPCA_gcv$scores
    loadings_locs$fpca_gcv_center[[i]] <- adjusted_results_fPCA_gcv$loadings_locs

    cat(paste("- Batch", i, "loaded\n"))
  }
}

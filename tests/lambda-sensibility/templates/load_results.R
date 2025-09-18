
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
  for (name in c("centering", "centering_locs", "loadings", "loadings_locs", "scores", "reconstruction", "reconstruction_locs")) {
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
  
  ## pde: needed to normalise the fPCs
  Vh <- FunctionSpace(domain, fe_order=1)
  u <- Function(Vh)
  Lu <- -laplace(u) ## poisson problem
  f <- function(points) { return(0*points[,1])}
  pde <- Pde(Lu, f)
  ## load batches
  for (i in 1:n_reps) {
    ## generating & normalising the fPCs
    loadings_true <- matrix(0, nrow = nrow(domain$nodes()), ncol = n_comp)
    loadings_true_locs <- matrix(0, nrow = nrow(locations), ncol = n_comp)
    loadings_true_HR <- matrix(0, nrow = nrow(grid), ncol = n_comp)
    for (m in 1:n_comp) {
      loadings_true[, m] <- loadings_true_generator(domain$nodes(), m)
      norm <- norm_L2(loadings_true[, m], pde$mass())
      loadings_true[, m] <- loadings_true[, m] / norm
      loadings_true_locs[, m] <- loadings_true_generator(locations, m) / norm
      loadings_true_HR[,m] <- loadings_true_generator(grid, m) / norm
    }
    ## laod batch and log if not present
    tryCatch(
      {
        path_batch <- paste(path_results, "/", "batch_", i, "/", sep = "")
        for(name_model in names_models) {
          #load the model
          load(paste(path_batch, "batch_", i, "_fitted_model_fpca_", name_model, ".RData", sep = ""))
          fPCA_model <- get(paste("model_fPCA_",name_model,sep=""))
          #adjust results (sign swap)
          adjusted_results <- adjust_results(
            fPCA_model$results$loadings_locs, 
            fPCA_model$results$scores,
            loadings_true_locs,
            list(
              loadings = fPCA_model$results$loadings,
              loadings_HR = evaluate_field(grid, fPCA_model$results$loadings, mesh)
              )
            )
          ## save adjusted scores, loadings, loadings at locs and at grid
          scores[[name_model]][[i]] <- adjusted_results$scores
          loadings[[name_model]][[i]] <- adjusted_results$loadings_evaluated_list$loadingsings_locs
          loadings_locs[[name_model]][[i]] <- adjusted_results$loadings_locs
          loadings_HR[[name_model]][[i]] <- adjusted_results$loadings_evaluated_list$loadings_HR
        }
      },
      error = function(e) {
        cat(paste("Error in test ", name_test, " - batch ", i, ": ", conditionMessage(e), "\n", sep = ""))
      }
    )
    cat(paste("- Batch", i, "loaded\n"))
  }
}

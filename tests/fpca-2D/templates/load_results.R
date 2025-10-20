## Quantitative analysis ----
load_quantitative_results <- function(test_options, path_list){
  cat("\nLoading results for quantitative analysis ...\n")
  
  ## room for solutions
  model_names <- test_options$model_names
  names_columns <- c("Group", model_names)
  empty_df <- data.frame(matrix(NaN, nrow = 0, ncol = length(names_columns)))
  colnames(empty_df) <- names_columns
  times <- empty_df
  rmses <- list()
  irmses <- list()
  angles <- list()
  lambdas <- list()
  
  ## laod pers' results seqly
  for (batch_index in 1:test_options$dimensions$n_reps) {
    ## laod batch and log if not present
    tryCatch(
      {
        path_batch <- paste(path_list$path_results, "batch_", batch_index, "/", sep = "")
        load(paste(path_batch, "batch_", batch_index, "_results_evaluation.RData", sep = ""))
      },
      error = function(e) {
        cat(paste("Error in test ", test_options$name_test, " - batch ", batch_index, ": ", conditionMessage(e), "\n", sep = ""))
      }
    )
    ## times
    times <- add_results(
      times, extract_new_results(results_evaluation, model_names, "execution_time"),
      names_columns
    )
    ## lambdas
    lambdas <- add_results(
      lambdas,extract_new_results(results_evaluation, model_names, "lambdas"),
      names_columns)
    ## rmse
    for (name in c("centering", "centering_locs", "loadings", "loadings_locs", "scores", "scores_orth", "reconstruction", "reconstruction_locs")) {
      rmses[[name]] <- add_results(
        rmses[[name]], extract_new_results(results_evaluation, model_names, c("rmse", name)),
        names_columns
      )
    }
    ## irmse
    for (name in c("centering", "loadings", "reconstruction")) {
      irmses[[name]] <- add_results(
        irmses[[name]], extract_new_results(results_evaluation, model_names, c("irmse", name)),
        names_columns
      )
    }
    ## angles
    for (name in c("subspaces_m", "components_m", "components_f", "orthogonality_m", "orthogonality_f")) {
      angles[[name]] <- add_results(
        angles[[name]], extract_new_results(results_evaluation, model_names, c("angles", name)),
        names_columns
      )
    }
    cat(paste("- Batch", batch_index, "loaded\n"))
  }
  return(list(
    model_names = model_names,
    times = times,
    lambdas = lambdas,
    rmses = rmses,
    irmses = irmses,
    angles = angles
  ))
}


## Qualitative analysis----
load_qualitative_results <- function(
    test_options,
    generated_data,
    generated_domain,
    loadings_true_generator, 
    path_list){
  
  cat("\nLoading results for qualitative analysis ...\n")

  n_comp <- test_options$dimensions$n_comp
  
  ## locations
  nodes <- generated_domain$fdapde_mesh$nodes
  locations <- generated_data$locations
  grid <- spsample(generated_domain$domain_boundary, test_options$dimensions$n_nodes_HR_grid, "regular")@coords
  
  ## room for solutions
  scores <- list()
  loadings <- list()
  loadings_locs <- list()
  loadings_HR <- list()
  
  ## pde: needed to normalise the fPCs
  Vh <- FunctionSpace(generated_domain$femr_mesh, fe_order=1)
  u <- Function(Vh)
  Lu <- -laplace(u) ## poisson problem
  f <- function(points) { return(0*points[,1])}
  pde <- Pde(Lu, f)
  ## load batches
  for (batch_index in 1:test_options$dimensions$n_reps) {
    ## generating & normalising the fPCs
    loadings_true <- matrix(0, nrow = nrow(nodes), ncol = n_comp)
    loadings_true_locs <- matrix(0, nrow = nrow(locations), ncol = n_comp)
    loadings_true_HR <- matrix(0, nrow = nrow(grid), ncol = n_comp)
    for (m in 1:n_comp) {
      loadings_true[, m] <- loadings_true_generator(nodes, m)
      norm <- norm_L2(loadings_true[, m], pde$mass())
      loadings_true[, m] <- loadings_true[, m] / norm
      loadings_true_locs[, m] <- loadings_true_generator(locations, m) / norm
      loadings_true_HR[,m] <- loadings_true_generator(grid, m) / norm
    }
    ## laod batch and log if not present
    tryCatch(
      {
        path_batch <- paste(path_list$path_results, "/", "batch_", batch_index, "/", sep = "")
        for(name_model in test_options$model_names) {
          #load the model
          load(paste(path_batch, "batch_", batch_index, "_fitted_model_fpca_", name_model, ".RData", sep = ""))
          fPCA_model <- get(paste("model_fPCA_",name_model,sep=""))
          #adjust results (sign swap)
          adjusted_results <- adjust_results(
            fPCA_model$results$loadings_locs,
            fPCA_model$results$scores,
            loadings_true_locs,
            list(
              loadings = fPCA_model$results$loadings,
              loadings_HR = evaluate_field(grid, fPCA_model$results$loadings, generated_domain$fdapde_mesh)
            )
          )
          ## save adjusted scores, loadings, loadings at locs and at grid
          scores[[name_model]][[batch_index]] <- adjusted_results$scores
          loadings[[name_model]][[batch_index]] <- adjusted_results$loadings_evaluated_list$loadingsings_locs
          loadings_locs[[name_model]][[batch_index]] <- adjusted_results$loadings_locs
          loadings_HR[[name_model]][[batch_index]] <- adjusted_results$loadings_evaluated_list$loadings_HR
        }
      },
      error = function(e) {
        cat(paste("Error in test ", test_options$name_test, " - batch ", batch_index, ": ", conditionMessage(e), "\n", sep = ""))
      }
    )
    cat(paste("- Batch", batch_index, "loaded\n"))
  }
  return(list(
    model_names = test_options$model_names,
    model_labels = test_options$model_labels,
    scores = scores, 
    loadings_true = loadings_true,
    loadings_true_locs = loadings_true_locs,
    loadings_true_HR = loadings_true_HR, 
    loadings = loadings, 
    loadings_locs = loadings_locs,
    loadings_HR = loadings_HR,
    nodes = nodes,
    locations = locations,
    grid = grid
  ))
}



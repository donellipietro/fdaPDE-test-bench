## Function: extract_new_results
# - Args:
#   * results_evaluation: nested list containing results per model
#   * names_models: character vector with model identifiers
#   * name_result: character or vector specifying which result(s) to extract
# - Desc:
#   Extracts specific evaluation metrics from each model’s result structure.
#   Handles nested lists, converts time units to seconds, and replaces NULLs
#   with NaN values for consistency.
extract_new_results <- function(results_evaluation, names_models, name_result) {
  
  ## Room for new results
  new_results <- list()
  for (name_model in names_models) {
    ## Router for reading the data
    if (length(name_result) == 1) {
      new_results[[name_model]] <- results_evaluation[[name_model]][[name_result]]
    } else if (length(name_result) == 2) {
      new_results[[name_model]] <- results_evaluation[[name_model]][[name_result[1]]][[name_result[2]]]
    } else {
      stop()
    }
    ## Convert time units if necessary
    if (length(new_results[[name_model]]) == 1 &&
        "units" %in% names(attributes(new_results[[name_model]]))) {
      new_results[[name_model]] <- format_time(new_results[[name_model]])
    }
    ## Replace NULL with NaN
    if (is.null(new_results[[name_model]])) {
      new_results[[name_model]] <- c(NaN)
    }
  }
  return(new_results)
}

## Quantitative analysis ----
load_quantitative_results <- function(test_options, path_list){
  cat(paste0("\nLoading quantitative results for ", test_options$name_test, " ...\n"))
  batch_index <- 1 # test on GCV curves use a single batch
  ## Get model names, labels, and colors
  model_names  <- test_options$model_names
  model_labels <- test_options$model_labels
  model_colors <- test_options$model_colors
  ## Load the first batch
  batch_index <- 1
  ok <- tryCatch({
    path_batch <- file.path(path_list$results, paste0("batch_", batch_index))
    load(file.path(path_batch, paste0("batch_", batch_index, "_results_evaluation.RData")))
    TRUE
  }, error = function(e) {
    cat(sprintf("Error in test %s - batch %d: %s\n", test_options$name_test, batch_index, conditionMessage(e)))
    FALSE
  })
  if (!ok) next
  
  ## Load gcv scores and mse
  gcv_scores <- extract_new_results(results_evaluation, model_names, "gcv_scores")
  mse <- extract_new_results(results_evaluation, model_names, "mse")
  cat(sprintf("- Batch %d loaded\n", batch_index))

  return(list(
    gcv_scores = gcv_scores,
    mse = mse,
    model_names = model_names,
    model_labels = model_labels,
    model_colors = model_colors,
    varying_options = test_options$test_options$varying_options
  ))
}

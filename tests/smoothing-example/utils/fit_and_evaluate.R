# = ========================================================================== =
# - Script: fit_and_evaluate.R
# - Desc: Fits both smoothing models and writes standard batch RData outputs.
# = ========================================================================== =

## Function: fit_and_evaluate_models
# - Args:
#   * path_list: standard suite and batch paths
#   * data: one generated repetition shared by both models
#   * domain: unused; retained for the standard template signature
#   * batch_index: repetition index
#   * test_options: one expanded option JSON plus model metadata
# - Desc:
#   Reuses cached fitted models unless fitting is forced, evaluates each model,
#   and saves both fitted-model and evaluation files under the batch directory.
fit_and_evaluate_models <- function(path_list, data, domain, batch_index, test_options) {
  ## Room for model evaluations ----
  results_evaluation <- list()
  evaluation_file <- file.path(
    path_list$batch,
    glue::glue("batch_{batch_index}_results_evaluation.RData")
  )

  ## Fit and evaluate each requested model ----
  for (model_name in test_options$model_names) {
    model_file <- file.path(
      path_list$batch,
      glue::glue("batch_{batch_index}_fitted_model_{model_name}.RData")
    )
    object_name <- glue::glue("model_{model_name}")

    ## Load a cached fit or run the model wrapper
    if (file.exists(model_file) && !FORCE_FIT) {
      load(model_file)
      model <- get(object_name)
    } else {
      cat(glue::glue("  fitting {model_name}\n", .trim = FALSE))
      model <- fit_model(model_name, domain, data, path_list, test_options)
      model <- adjust_results(model, data)

      ## Save using the standard model_<name> object convention
      assign(object_name, model)
      save(list = object_name, file = model_file)
      rm(list = object_name)
    }

    results_evaluation[[model_name]] <- evaluate_results(model, data)
  }

  ## Save the standard batch evaluation object ----
  save(index_batch = batch_index, results_evaluation, file = evaluation_file)
  cat("  batch complete\n")
}

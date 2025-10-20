
cat("\nLoading results for quantitative analysis ...\n")

## room for solutions
names_columns <- c("Group", names_models)
empty_df <- data.frame(matrix(NaN, nrow = 0, ncol = length(names_columns)))
colnames(empty_df) <- names_columns
times <- empty_df
rmses <- list()
irmses <- list()

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
  ## rmse
  for (name in c("centering", "centering_locs")) {
    rmses[[name]] <- add_results(
      rmses[[name]], extract_new_results(results_evaluation, names_models, c("rmse", name)),
      names_columns
    )
  }
  ## irmse
  for (name in c("centering")) {
    irmses[[name]] <- add_results(
      irmses[[name]], extract_new_results(results_evaluation, names_models, c("irmse", name)),
      names_columns
    )
  }
  cat(paste("- Batch", i, "loaded\n"))
}



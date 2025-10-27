# = ========================================================================== =
# - Script: plot_results.R
# - Desc: Provides visualization utilities for simulation results. Includes
#         quantitative summaries (e.g., RMSE, time) and qualitative comparisons
#         of reconstructed loadings, both at locations and on high-resolution
#         grids, for different functional PCA approaches.
# = ========================================================================== =


## Function: plot_quantitative_results
# - Args:
#   * loaded_results: list containing aggregated quantitative results and model info.
#       Expected fields include:
#         - $model_names, $model_labels, $model_colors
#         - $execution_time, $rmse (with nested lists for various metrics)
# - Desc:
#   Generates boxplots summarizing execution times and RMSE-based performance metrics
#   for all models. Separate figures are produced for reconstruction accuracy,
#   score orthogonality deviation, and component-wise RMSE for loadings and scores.
plot_quantitative_results <- function(loaded_results) {
  ## Get models details
  model_names <- loaded_results$model_names
  model_labels <- loaded_results$model_labels
  model_colors <- loaded_results$model_colors
  ## Time ----
  times <- loaded_results$execution_time
  indexes <- which(!is.nan(colSums(times[, model_names])))
  plot <- plot.grouped_boxplots(
    times[, c("Group", names(indexes))],
    values_name = "Time [seconds]",
    group_name = "",
    group_labels = "",
    subgroup_name = "Approaches",
    subgroup_labels = model_labels[indexes],
    subgroup_colors = model_colors[indexes]
  ) + std_plot_settings() + ggtitle("Time")
  print(plot)
  ## RMSE ----
  ## Overall measures
  rmses <- loaded_results$rmse
  names <- c("reconstruction_locs", "scores_orth")
  titles <- c("Reconstruction at locations", "Deviation from scores orthogonality")

  for (i in seq_along(names)) {
    name <- names[i]
    title <- titles[i]
    indexes <- which(!is.nan(colSums(rmses[[name]][, model_names])))
    plot <- plot.grouped_boxplots(
      rmses[[name]][, c("Group", names(indexes))],
      values_name = "RMSE",
      group_name = "",
      group_labels = "",
      subgroup_name = "Approaches",
      subgroup_labels = model_names[indexes],
      subgroup_colors = model_colors[indexes]
    ) + std_plot_settings() + ggtitle(title)
    print(plot)
  }

  ## Component-by-component measures
  names <- c("loadings_locs", "scores")
  titles <- c("Loadings at locations", "Scores")

  for (i in seq_along(names)) {
    name <- names[i]
    title <- titles[i]
    indexes <- which(!is.nan(colSums(rmses[[name]][, model_names])))
    plot <- plot.grouped_boxplots(
      rmses[[name]][, c("Group", names(indexes))],
      values_name = "RMSE",
      subgroup_name = "Approaches",
      subgroup_labels = model_names[indexes],
      subgroup_colors = model_colors[indexes]
    ) + std_plot_settings() + ggtitle(title)
    print(plot)
  }

  ## Angles ----
  angles <- loaded_results$angles
  ## Component by component measures
  names <- c("components_m")
  titles <- c("Angle between true and estimated loading")
  for (i in seq_along(names)) {
    name <- names[i]
    title <- titles[i]
    indexes <- which(!is.nan(colSums(angles[[name]][, model_names])))
    plot <- plot.grouped_boxplots(
      angles[[name]][, c("Group", names(indexes))],
      values_name = "Angle",
      subgroup_name = "Approaches",
      subgroup_labels = model_names[indexes],
      subgroup_colors = model_colors[indexes]
    ) + std_plot_settings() + ggtitle(title)
    print(plot)
  } 
}

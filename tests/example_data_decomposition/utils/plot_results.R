
plot_quantitative_analysis <- function(loaded_results){
  
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
  for (i in 1:length(names)) {
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
  
  ## Component by component measures
  names <- c("loadings_locs", "scores")
  titles <- c("Loadings at locations", "Scores")
  for (i in 1:length(names)) {
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
}

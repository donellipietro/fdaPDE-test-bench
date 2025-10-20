## time
indexes <- which(!is.nan(colSums(times[, names_models])))
plot <- plot.grouped_boxplots(
  times[, c("Group", names(indexes))],
  values_name = "Time [seconds]",
  group_name = "",
  group_labels = "",
  subgroup_name = "Approaches",
  subgroup_labels = lables_models[indexes],
  subgroup_colors = colors[indexes]
) + standard_plot_settings() + ggtitle("Time")
print(plot)

## RMSE
names <- c("centering", "centering_locs")
titles <- c("Centering", "Centering at locations")

for (i in 1:length(names)) {
  name <- names[i]
  title <- titles[i]
  indexes <- which(!is.nan(colSums(rmses[[name]][, names_models])))
  plot <- plot.grouped_boxplots(
    rmses[[name]][, c("Group", names(indexes))],
    values_name = "RMSE",
    group_name = "",
    group_labels = "",
    subgroup_name = "Approaches",
    subgroup_labels = lables_models[indexes],
    subgroup_colors = colors[indexes]
  ) + standard_plot_settings() + ggtitle(title)
  print(plot)
}



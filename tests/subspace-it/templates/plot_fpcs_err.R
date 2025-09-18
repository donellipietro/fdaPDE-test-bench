

## Data filtering
data_plot_trimmed <- data_plot[, c("Group","NSR", names_models)]

colnames(data_plot_trimmed) <- c("fPC","Group",names_models)

# Skip if empty
if (nrow(data_plot_trimmed) == 0) next

# Remove models with all NaNs
valid_models <- names_models[!apply(data_plot_trimmed[, names_models], 2, function(x) all(is.nan(x)))]
if (length(valid_models) == 0) next

boxplot_list <- list()

# Set plot limits if not already defined

limits <- range(data_plot[, names_models])

for(j in 1:n_comp){
  ## plots
  boxplot_list[[j]] <- plot.grouped_boxplots(
    data_plot_trimmed[data_plot_trimmed$fPC==j, c("Group", valid_models)],
    values_name = NULL,
    group_name = "NSR",
    subgroup_name = "methods",
    subgroup_labels = lables_models[match(valid_models, names_models)],
    subgroup_colors = colors[match(valid_models, names_models)],
    limits = limits,
    LEGEND = F
  ) + standard_plot_settings()
}
boxplot <- arrangeGrob(grobs = boxplot_list, ncol = 1)
title <- NULL
labels_cols <- ""
labels_rows <- paste("fPC",1:n_comp,sep="")
boxplot <- labled_plots_grid(boxplot, title, labels_cols, labels_rows, 7, 7)
grid.arrange(boxplot)




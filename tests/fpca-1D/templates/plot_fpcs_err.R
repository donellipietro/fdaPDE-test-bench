plot_fpcs_err <- function(test_options, data_plot, group_name, colors){
  ## Data filtering
  data_plot_trimmed <- data_plot[, c("Group",group_name, test_options$model_names)]
  colnames(data_plot_trimmed) <- c("fPC","Group",test_options$model_names)
  
  # Skip if empty
  if (nrow(data_plot_trimmed) == 0) next
  
  # Remove models with all NaNs
  valid_models <- test_options$model_names[!apply(data_plot_trimmed[, test_options$model_names], 2, function(x) all(is.nan(x)))]
  if (length(valid_models) == 0) next
  
  boxplot_list <- list()
  
  # Set plot limits if not already defined
  limits <- range(data_plot[, test_options$model_names])
  
  for(j in 1:test_options$dimensions$n_comp){
    ## plots
    boxplot_list[[j]] <- plot.grouped_boxplots(
      data_plot_trimmed[data_plot_trimmed$fPC==j, c("Group", valid_models)],
      values_name = NULL,
      group_name = group_name,
      subgroup_name = "methods",
      subgroup_labels = test_options$model_labels[match(valid_models, test_options$model_names)],
      subgroup_colors = colors[match(valid_models, test_options$model_names)],
      limits = limits,
      LEGEND = F
    ) + standard_plot_settings()
  }
  boxplot <- arrangeGrob(grobs = boxplot_list, ncol = 1)
  title <- NULL
  labels_cols <- ""
  labels_rows <- paste("fPC",1:test_options$dimensions$n_comp,sep="")
  boxplot <- labled_plots_grid(boxplot, title, labels_cols, labels_rows, 7, 7)
  grid.arrange(boxplot)
}






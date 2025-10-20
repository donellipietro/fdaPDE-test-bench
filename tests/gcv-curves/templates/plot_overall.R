## options
options_grid <- list()
for (name_ao in name_aggregation_option_vect) {
  options_grid[[name_ao]] <- unique(data_plot[, name_ao])
}

## plots
for (i in 1:length(name_aggregation_option_vect)) {
  
  boxplot_list <- list()
  plot_list <- list()
  
  name_aggregation_option <- name_aggregation_option_vect[i]
  group_name <- name_group_vect[i]
  title <- title_vect[i]
  
  options_grid_selected <- options_grid
  options_grid_selected[[name_aggregation_option]] <- NULL
  names_options_selected <- names(options_grid_selected)
  labels_options_selected <- name_group_vect[-i]
  
  # Handle 1D case (no other grouping)
  if (length(options_grid_selected) == 0) {
    combinations_options <- data.frame(dummy = 1)
    labels_rows <- ""
    labels_cols <- ""
  } else {
    mg <- do.call(expand.grid, options_grid_selected)
    combinations_options <- do.call(data.frame, lapply(mg, as.vector))
    colnames(combinations_options) <- names_options_selected
    
    labels_rows <- if (length(labels_options_selected) >= 1) paste(labels_options_selected[1], "=", options_grid_selected[[1]]) else ""
    labels_cols <- if (length(labels_options_selected) >= 2) paste(labels_options_selected[2], "=", options_grid_selected[[2]]) else ""
  }
  
  # Set plot limits if not already defined
  if (is.null(limits)) {
    limits <- c(0, max(data_plot[, names_models], na.rm = TRUE))
  }
  
  for (j in 1:nrow(combinations_options)) {
    
    ## Data filtering
    if (length(names_options_selected) == 0) {
      data_plot_trimmed <- data_plot[, c(name_aggregation_option, names_models)]
    } else {
      condition <- rep(TRUE, nrow(data_plot))
      for (k in seq_along(names_options_selected)) {
        condition <- condition & (data_plot[[names_options_selected[k]]] == combinations_options[j, k])
      }
      data_plot_trimmed <- data_plot[condition, c(name_aggregation_option, names_models)]
    }
    
    # Skip if empty
    if (nrow(data_plot_trimmed) == 0) next
    
    colnames(data_plot_trimmed)[1] <- "Group"
    
    # Remove models with all NaNs
    valid_models <- names_models[!apply(data_plot_trimmed[, names_models], 2, function(x) all(is.nan(x)))]
    if (length(valid_models) == 0) next
    
    data_plot_aggregated <- aggregate(. ~ Group, data = data_plot_trimmed[, c("Group", valid_models)], FUN = median)
    
    ## plots
    plot_list[[j]] <- plot.multiple_lines(
      data_plot_aggregated,
      values_name = NULL,
      x_name = group_name,
      x_breaks = TRUE,
      subgroup_name = "Approaches",
      subgroup_labels = lables_models[match(valid_models, names_models)],
      subgroup_colors = colors[match(valid_models, names_models)],
      LEGEND = FALSE,
      limits = limits,
      NORMALIZED = FALSE,
      LOGX = TRUE
    ) + standard_plot_settings()
  }
  
  # Fallback column layout for 1D
  ncols <- if (length(labels_cols) == 0) 1 else length(labels_cols)
  
  
  plot <- arrangeGrob(grobs = plot_list, ncol = ncols)
  plot <- labled_plots_grid(plot, title, labels_cols, labels_rows, 9, 7)
  grid.arrange(plot)
}

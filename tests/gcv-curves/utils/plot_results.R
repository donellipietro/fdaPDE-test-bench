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
  
  library(scales)
  library(patchwork)
  
  gcv_scores <- loaded_results$gcv_scores
  mse <- loaded_results$mse
  
  n_comp <- ncol(gcv_scores[[1]])
  
  global_gcv_max <- 3 * do.call(max, lapply(gcv_scores, max))
  global_gcv_min <- do.call(min, lapply(gcv_scores, min))
  global_mse_max <- do.call(max, lapply(mse, max))
  global_mse_min <- do.call(min, lapply(mse, min))
  global_y_max <- max(global_gcv_max, global_mse_max)
  global_y_min <- min(global_gcv_min, global_mse_min)
  
  plot_list <- list()
  
  metric_labels <- c(setNames(paste0("fPC", 1:n_comp), paste0("fPC", 1:n_comp)),
                     mse = expression(paste("MSE(",lambda,")",sep="")),
                     sum_gcv = expression(paste("GCV(",lambda,")",sep="")))
  
  for (model_idx in seq_along(model_names)) {
    model_name <- model_names[model_idx]
    base_color <- test_options$model_colors[model_idx]
    
    # Define color shades for fPCs (light → dark)
    fpc_colors <- colorRampPalette(c("grey90", base_color))(n_comp + 2)[-1]
    
    # Define color mapping
    curve_colors <- c(
      setNames(fpc_colors[1:n_comp], paste0("fPC", 1:n_comp)),
      mse = "black",
      sum_gcv = base_color
    )
    
    # Define line types
    line_types <- c(
      setNames(rep(c("dashed", "dotdash", "longdash", "twodash", "dotted"), 
                   length.out = n_comp), paste0("fPC", 1:n_comp)),
      mse = "solid",
      sum_gcv = "dotted"
    )
    
    # Define point shapes (different marker for each line)
    point_shapes <- c(
      setNames(rep(c(21, 22, 23, 24, 25, 4, 8), length.out = n_comp), paste0("fPC", 1:n_comp)),
      mse = 19,         # solid circle
      sum_gcv = 17      # solid triangle
    )
    
    current_gcv_matrix <- gcv_scores[[model_name]]
    
    df_plot <- as.data.frame(current_gcv_matrix)
    colnames(df_plot) <- paste0("fPC", 1:n_comp)
    df_plot$lambda <- test_options$regularization$lambda_grid
    df_plot$mse <- mse[[model_name]]
    df_plot$sum_gcv <- rowSums(current_gcv_matrix)
    
    df_long <- df_plot %>%
      pivot_longer(cols = c(starts_with("fPC"), "mse", "sum_gcv"),
                   names_to = "Metric",
                   values_to = "GCV_Score")
    
    # Find minima for each line
    min_gcv_points <- df_long %>%
      group_by(Metric) %>%
      filter(GCV_Score == min(GCV_Score))
    
    plot_list[[model_name]] <- ggplot(df_long, aes(x = lambda, y = GCV_Score,
                                                   color = Metric, linetype = Metric)) +
      geom_line(linewidth = 1) +
      geom_point(data = min_gcv_points,
                 aes(x = lambda, y = GCV_Score, shape = Metric),
                 size = 3, stroke = 1.5, fill = "white") +
      scale_x_log10(labels = label_scientific()) +
      scale_y_log10(limits = c(global_y_min, global_y_max),
                    labels = label_scientific()) +
      scale_color_manual(values = curve_colors) +
      scale_linetype_manual(values = line_types, labels = metric_labels) +
      scale_shape_manual(values = point_shapes) +
      labs(
        title = test_options$model_labels[model_idx],
        x = expression(lambda),
        y = NULL,
        color = NULL,
        linetype = NULL,
        shape = NULL
      ) +
      guides(color = "none", shape="none") +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, size = 16),
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14),
        axis.text = element_text(size = 12),
        legend.text = element_text(size = 10),
        legend.key.width = unit(2.5, "cm"),
        legend.spacing.x = unit(0.8, "cm"),
        legend.position = "top"
      )
  }

  print(plot_list[[1]])
  
  # Combine plots
  final_plot <- Reduce(`+`, plot_list) +
  plot_layout(guides = "collect", nrow = 1) +
  plot_annotation(
    theme = theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      legend.position = "bottom"
    )
  )
  print(final_plot)
}

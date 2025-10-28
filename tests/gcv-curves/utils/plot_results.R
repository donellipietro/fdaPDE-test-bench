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
  
  # Combine plots
  final_plot <- Reduce(`+`, plot_list) +
    plot_layout(guides = "collect", nrow = 1) +
    plot_annotation(
      title = paste("NSR =", NSR),
      theme = theme(plot.title = element_text(hjust = 0.5, face = "bold"))
    ) &
    theme(legend.position = "bottom")
  
  print(final_plot)
}



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

## Function: plot_qualitative_results
# - Args:
#   * quantitative_results: list containing quantitative summaries (for selecting representative samples)
#   * qualitative_results: list containing qualitative outputs for each model, including:
#       - $loadings, $loadings_locs, $loadings_HR
#       - $loadings_true, $loadings_true_locs, $loadings_true_HR
#       - $domain, $grid, $locations, $nodes, and $boundary
# - Desc:
#   Produces qualitative visual comparisons of true and reconstructed loadings across
#   models and principal components. For each method, three representative replicates
#   are selected based on RMSE quantiles (min, median, max). Each component’s fields
#   are plotted at nodes, evaluation locations, and high-resolution grids, both with
#   and without isolines. Results are arranged in labeled grids for clarity.
plot_qualitative_results <- function(quantitative_results, qualitative_results) {
  ## Debugging helpers
  # quantitative_results <- loaded_qnt_results
  # qualitative_results  <- loaded_qlt_results

  ## Get fitted quantities
  scores <- qualitative_results$scores
  loadings <- qualitative_results$loadings
  loadings_locs <- qualitative_results$loadings_locs
  loadings_HR <- qualitative_results$loadings_HR

  ## Get true loadings
  loadings_true <- qualitative_results$loadings_true
  loadings_true_locs <- qualitative_results$loadings_true_locs
  loadings_true_HR <- qualitative_results$loadings_true_HR
  
  ## Get infos
  domain <- qualitative_results$domain
  n_comp <- ncol(loadings_true)
  boundary <- domain$boundary

  ## Models info
  model_names <- quantitative_results$model_names
  model_labels <- qualitative_results$model_labels

  ## Labels for plot grids
  labels_cols <- c("True", "Quantile 0", "Quantile 0.5", "Quantile 1")
  labels_rows <- paste0("f", 1:n_comp)

  ## Room for plots
  plots <- list()
  plots_locs <- list()
  plots_HR_clean <- list() # high-resolution without isolines
  plots_HR <- list() # high-resolution with isolines

  ## Generate figures for each model
  for (m in seq_along(model_names)) { # m <- 1

    ## Model details
    name_model <- model_names[m]
    label_model <- model_labels[m]

    ## Room for plots
    plot_list <- list()
    plot_list_locs <- list()
    plot_list_HR_clean <- list()
    plot_list_HR <- list()

    ## Select representative replicates (min, median, max RMSE)
    indexes <- tapply(
      quantitative_results$rmse$loadings_locs[[name_model]],
      quantitative_results$rmse$loadings_locs$Group,
      function(x) {
        sapply(quantile(x, c(0, 0.5, 1), na.rm = TRUE), function(q) which.min(abs(x - q)))
      }
    )

    ## Compute limits
    limits_HR <- apply(do.call(rbind, unlist(loadings_HR, recursive = FALSE)), 2, range)

    for (i in seq_len(n_comp)) {
      limits <- range(c(loadings_true_HR[, i], limits_HR[, i]))
      breaks <- seq(limits[1], limits[2], length = 10)

      ## True components
      plot_list[[4 * (i - 1) + 1]] <- plot.field_points(
        qualitative_results$nodes, loadings_true[, i],
        boundary = boundary, size = 1.5, LEGEND = FALSE
      ) + std_plot_settings_fields()

      plot_list_locs[[4 * (i - 1) + 1]] <- plot.field_points(
        qualitative_results$locations, loadings_true_locs[, i],
        boundary = boundary, size = 1.5, LEGEND = FALSE
      ) + std_plot_settings_fields()

      plot_list_HR_clean[[4 * (i - 1) + 1]] <- plot.field_tile(
        qualitative_results$grid, loadings_true_HR[, i],
        boundary = boundary, LEGEND = FALSE
      ) + std_plot_settings_fields()

      plot_list_HR[[4 * (i - 1) + 1]] <- plot.field_tile(
        qualitative_results$grid, loadings_true_HR[, i],
        boundary = boundary, limits = limits, breaks = breaks, LEGEND = FALSE
      ) + std_plot_settings_fields()

      ## Reconstructed components for quantile-based replicates
      for (j in 1:3) {
        plot_list[[4 * (i - 1) + j + 1]] <- plot.field_points(
          qualitative_results$nodes,
          loadings[[name_model]][[indexes[[i]][j]]][, i],
          boundary = boundary, size = 1.5
        ) + std_plot_settings_fields()

        plot_list_locs[[4 * (i - 1) + j + 1]] <- plot.field_points(
          qualitative_results$locations,
          loadings_locs[[name_model]][[indexes[[i]][j]]][, i],
          boundary = boundary, size = 1.5
        ) + std_plot_settings_fields()

        plot_list_HR_clean[[4 * (i - 1) + j + 1]] <- plot.field_tile(
          qualitative_results$grid,
          loadings_HR[[name_model]][[indexes[[i]][j]]][, i],
          boundary = boundary
        ) + std_plot_settings_fields()

        plot_list_HR[[4 * (i - 1) + j + 1]] <- plot.field_tile(
          qualitative_results$grid,
          loadings_HR[[name_model]][[indexes[[i]][j]]][, i],
          boundary = boundary, limits = limits, breaks = breaks
        ) + std_plot_settings_fields()
      }
    }

    ## Arrange labeled grids for each display mode
    plots[[m]] <- labled_plots_grid(arrangeGrob(grobs = plot_list, nrow = n_comp), label_model, labels_cols, labels_rows)
    plots_locs[[m]] <- labled_plots_grid(arrangeGrob(grobs = plot_list_locs, nrow = n_comp), label_model, labels_cols, labels_rows)
    plots_HR_clean[[m]] <- labled_plots_grid(arrangeGrob(grobs = plot_list_HR_clean, nrow = n_comp), label_model, labels_cols, labels_rows)
    plots_HR[[m]] <- labled_plots_grid(arrangeGrob(grobs = plot_list_HR, nrow = n_comp), label_model, labels_cols, labels_rows)
  }

  ## Display plots sequentially
  for (m in seq_along(model_names)) grid.arrange(plots_locs[[m]])
  for (m in seq_along(model_names)) grid.arrange(plots[[m]])
  for (m in seq_along(model_names)) grid.arrange(plots_HR_clean[[m]])
  for (m in seq_along(model_names)) grid.arrange(plots_HR[[m]])
}

## gcv scores ----
plot_quantitative_analysis <- function(loaded_results, test_options, colors){
  gcv_scores <- loaded_results$gcv_scores
  mse <- loaded_results$mse
  
  model_names <- names(gcv_scores)
  n_comp <- ncol(gcv_scores[[1]])
  NSR <- test_options$noise$NSR
  
  # Plot GCV curves on log-log scale
  plot_list <- list()
  
  global_gcv_max <- 3*do.call(max,lapply(gcv_scores,max))
  global_gcv_min <- do.call(min,lapply(gcv_scores,min))
  
  global_mse_max <- do.call(max,lapply(mse,max))
  global_mse_min <- do.call(min,lapply(mse,min))
  
  global_y_max <- max(global_gcv_max, global_mse_max)
  global_y_min <- min(global_gcv_min, global_mse_min)
  
  curve_colors <- c(colors,"mse"="blue3","sum_gcv"="darkgreen")
  legend_order <- c(paste("fPC", 1:n_comp, sep=""), "mse", "sum_gcv")
  for(model_name in model_names){
    
    # Extract the GCV scores matrix for the current model
    current_gcv_matrix <- gcv_scores[[model_name]]
    
    # Convert the matrix to a data frame for ggplot2
    df_plot <- as.data.frame(current_gcv_matrix)
    colnames(df_plot) <- paste("fPC",1:n_comp,sep="")
    df_plot$lambda <- test_options$regularization$lambda_grid
    df_plot$mse <- mse[[model_name]]
    df_plot$sum_gcv <- rowSums(current_gcv_matrix)
    
    # Reshape the data to a long format
    df_long <- pivot_longer(df_plot,
                            cols = c(starts_with("fPC"), "mse", "sum_gcv"), 
                            names_to = "Metric",
                            values_to = "GCV_Score")
    
    # Find the minimum GCV score for each principal component
    min_gcv_points <- df_long %>%
      group_by(Metric) %>%
      filter(GCV_Score == min(GCV_Score))
    
    # Create the plot
    plot_list[[model_name]] <- ggplot(df_long, aes(x = lambda, y = GCV_Score, color = Metric)) +
      geom_line(linewidth = 1) +
      geom_point(data = min_gcv_points, aes(x = lambda, y = GCV_Score),
                 shape = 21, size = 3, fill = "white", stroke = 1.5) +
      scale_x_log10(labels = scales::label_scientific()) +
      scale_y_log10(limits = c(global_y_min, global_y_max), 
                    labels = scales::label_scientific()) + # Use scientific notation for y-axis
      labs(
        title = paste(tools::toTitleCase(model_name)),
        x = expression(lambda),
        y = NULL
      ) +
      scale_color_manual(values = curve_colors) + # Use defined colors for PCs
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, size = 16),
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14),
        axis.text = element_text(size = 12),
        legend.text = element_text(size = 10),
        legend.position = "top"
      ) 
  }
  library(patchwork)
  final_plot <- plot_list[[1]]
  for (k in 2:length(plot_list)) {
    final_plot <- final_plot + plot_list[[k]]
  }
  final_plot <- final_plot +
    plot_layout(guides = "collect", nrow = 1) +
    plot_annotation(
      title = paste("NSR = ", NSR, sep=""),
      theme = theme(plot.title = element_text(hjust = 0.5, face = "bold")) # Apply theme directly to plot.title
    ) &
    theme(legend.position = 'bottom')
  print(final_plot)
}



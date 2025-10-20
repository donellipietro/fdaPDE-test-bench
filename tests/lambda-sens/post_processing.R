# % %%%%%%%%%%%%%% %
# % % Test: fPCA % %
# % %%%%%%%%%%%%%% %

## TODO:
#' - correct the time complexity analysis
#' - define test_suite somewhere else
#' - correct the case for multiple aggregation vectors (e.g. n_nodes, NSR)
#' - understand difference between aggregation and group
#' - put the 

rm(list = ls())
graphics.off()

## global variables ----
test_suite <- "lambda-sens"
TEST_SUITE <- "lambda-sens"

## prerequisite ----
source(paste("tests/", test_suite, "/utils/generate_options.R", sep = ""))
source(paste("tests/", test_suite, "/templates/load_results.R", sep = ""))

## libraries ----
## data visualization
invisible(suppressMessages(
  sapply(c(
    "fdaPDE","femR", #discretisation
    "pracma", #algebraic utils
    "MASS","tidyr","dplyr", #data manipulation
    "ggplot2","viridis","stringr","RColorBrewer","grid","gridExtra", #visualisation
    "jsonlite", #json
    "sf","sp","raster" #sampling
  ), require, character.only = TRUE)))

## sources ----
source("src/utils/directories.R")
source("src/utils/results_management.R")
source("src/utils/plots.R")


## paths ----
path_options <- paste("queue/", sep = "")
path_results <- paste("results/", test_suite, "/", sep = "")
path_images <- paste("images/", test_suite, "/", sep = "")

path_list <- list()
path_list$path_results <- path_results


file_log <- "log.txt"

colors <- c(
  "sequential" = "magenta4",
  "subspace" = "palegreen",
  "direct" = "lightpink"
)

## load data ----

## check arguments passed by terminal
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  args[1] <- "test1"
}

## main test name
name_main_test <- args[1]
cat(paste("\nTest selected:", name_main_test, "\n"))
test_results_path <- paste(path_list$path_results, name_main_test, "/", sep = "")
path_images <- paste(path_images, name_main_test, "/", sep = "")
mkdir(path_images)

## generate options
generate_options(name_main_test, path_options)

## list of available tests
file_test_vect <- sort(list.files(path_options))
file_json <- paste(path_options, file_test_vect[1], sep = "")
test_options <- fromJSON(file_json)

## room for solutions
names_columns <- c("Group","NSR","lambda","n_nodes","n_locs","n_stat_units",  test_options$model_names)
empty_df <- data.frame(matrix(NaN, nrow = 0, ncol = length(names_columns)))
colnames(empty_df) <- names_columns

times <- empty_df
rmses <- list()
irmses <- list()
angles <- list()

for (file_test in file_test_vect) {
  ## load specs
  file_json <- paste(path_options, file_test, sep = "")
  test_options <- fromJSON(file_json)
  
  path_list$path_results <- paste(test_results_path, test_options$name_test, "/", sep = "")
  cat(paste("\nTest ", test_options$name_test, ":\n", sep = ""))

  quantitative_results <- load_quantitative_results(test_options, path_list)
  # times
  times <- add_results(
    times,
    c(
      list(n_nodes = test_options$dimensions$n_nodes, 
           n_locs = test_options$dimensions$n_locs, 
           n_stat_units = test_options$dimensions$n_stat_units, 
           NSR = test_options$noise$NSR,
           lambda = test_options$regularization$lambda),
      quantitative_results$times
    ),
    names_columns,
    groups_names = quantitative_results$times$Group
  )
  
  # rmses
  for (name in c("reconstruction_locs", "loadings_locs", "scores","centering_locs")) {
    rmses[[name]] <- add_results(
      rmses[[name]],
      c(
        list(n_nodes = test_options$dimensions$n_nodes, 
             n_locs = test_options$dimensions$n_locs, 
             n_stat_units = test_options$dimensions$n_stat_units, 
             NSR = test_options$noise$NSR,
             lambda = test_options$regularization$lambda),
        quantitative_results$rmses[[name]]
      ),
      names_columns,
      groups_names = quantitative_results$rmses[[name]]$Group
    )
  }
  ## remove option file
  file.remove(file_json)
}

## analysis ----
## names
name_aggregation_option_vect <- c("NSR","lambda")
name_group_vect <- c("NSR",expression(lambda))

### time complexity ----
# 
# ## open a pdf where to save the plots
# pdf(paste(path_images, "time_complexity.pdf", sep = ""), width = 15, height = 15)
# 
# ## data and titles
# data_plot <- times
# values_name <- "Time [seconds]"
# title_vect <- paste(
#   "Execution times w.r.t the",
#   c(
#     "signal-to-noise ratio (NSR)"
#   )
# )
# limits <- NULL
# ## options
# options_grid <- list()
# for (name_ao in name_aggregation_option_vect) {
#   options_grid[[name_ao]] <- unique(data_plot[, name_ao])
# }
# 
# for (i in 1:length(name_aggregation_option_vect)) {
#   boxplot_list <- list()
#   plot_list <- list()
#   plot_loglog_list <- list()
#   plot_loglog_normalized_list <- list()
#   
#   name_aggregation_option <- name_aggregation_option_vect[i]
#   group_name <- name_group_vect[i]
#   title <- title_vect[i]
#   
#   options_grid_selected <- options_grid
#   options_grid_selected[[name_aggregation_option]] <- NULL
#   names_options_selected <- names(options_grid_selected)
#   labels_options_selected <- name_group_vect[-i]
#   
#   # Handle 1D case
#   if (length(options_grid_selected) == 0) {
#     combinations_options <- data.frame(dummy = 1)
#     labels_rows <- ""
#     labels_cols <- ""
#   } else {
#     mg <- do.call(expand.grid, options_grid_selected)
#     combinations_options <- do.call(data.frame, lapply(mg, as.vector))
#     colnames(combinations_options) <- names_options_selected
#     
#     labels_rows <- if (length(labels_options_selected) >= 1) paste(labels_options_selected[1], "=", options_grid_selected[[1]]) else ""
#     labels_cols <- if (length(labels_options_selected) >= 2) paste(labels_options_selected[2], "=", options_grid_selected[[2]]) else ""
#   }
#   
#   for (j in 1:nrow(combinations_options)) {
#     ## data preparation
#     if (length(names_options_selected) == 0) {
#       # 1D case: use all data
#       data_plot_trimmed <- data_plot[, c(name_aggregation_option, names_models)]
#     } else {
#       # ND case: filter by combination
#       condition <- rep(TRUE, nrow(data_plot))
#       for (k in seq_along(names_options_selected)) {
#         condition <- condition & (data_plot[[names_options_selected[k]]] == combinations_options[j, k])
#       }
#       data_plot_trimmed <- data_plot[condition, c(name_aggregation_option, names_models)]
#     }
#     
#     colnames(data_plot_trimmed)[1] <- "Group"
#     
#     # Skip if data is empty
#     if (nrow(data_plot_trimmed) == 0) next
#     
#     # Remove models with all-NaN results
#     valid_models <- names_models[!apply(data_plot_trimmed[, names_models], 2, function(x) all(is.nan(x)))]
#     if (length(valid_models) == 0) next
#     
#     # Aggregate
#     data_plot_aggregated <- aggregate(. ~ Group, data = data_plot_trimmed[, c("Group", valid_models)], FUN = median)
#     
#     ## plots
#     boxplot_list[[j]] <- plot.grouped_boxplots(
#       data_plot_trimmed[, c("Group", valid_models)],
#       values_name = NULL,
#       group_name = group_name,
#       subgroup_name = "Approaches",
#       subgroup_labels = lables_models[match(valid_models, names_models)],
#       subgroup_colors = colors[match(valid_models, names_models)],
#       limits = limits,
#       LEGEND = FALSE
#     ) + standard_plot_settings()
#     
#     plot_list[[j]] <- plot.multiple_lines(
#       data_plot_aggregated[, c("Group", valid_models)],
#       values_name = NULL,
#       x_name = group_name,
#       x_breaks = TRUE,
#       subgroup_name = "Approaches",
#       subgroup_labels = lables_models[match(valid_models, names_models)],
#       subgroup_colors = colors[match(valid_models, names_models)],
#       LEGEND = FALSE,
#       limits = limits,
#       NORMALIZED = FALSE,
#       LOGX = TRUE
#     ) + standard_plot_settings()
#     
#     plot_loglog_list[[j]] <- plot.multiple_lines(
#       data_plot_aggregated[, c("Group", valid_models)],
#       values_name = NULL,
#       x_name = group_name,
#       x_breaks = TRUE,
#       subgroup_name = "Approaches",
#       subgroup_labels = lables_models[match(valid_models, names_models)],
#       subgroup_colors = colors[match(valid_models, names_models)],
#       LEGEND = FALSE,
#       limits = range,
#       NORMALIZED = FALSE,
#       LOGLOG = TRUE
#     ) + standard_plot_settings()
#     
#     plot_loglog_normalized_list[[j]] <- plot.multiple_lines(
#       data_plot_aggregated[, c("Group", valid_models)],
#       values_name = NULL,
#       x_name = group_name,
#       x_breaks = TRUE,
#       subgroup_name = "Approaches",
#       subgroup_labels = lables_models[match(valid_models, names_models)],
#       subgroup_colors = colors[match(valid_models, names_models)],
#       LEGEND = FALSE,
#       limits = c(1, limits[2]),
#       NORMALIZED = TRUE,
#       LOGLOG = TRUE
#     ) + standard_plot_settings()
#   }
#   
#   # Handle layout safely if 1D: use 1 column
#   ncols <- if (length(labels_cols) == 0) 1 else length(labels_cols)
#   
#   boxplot <- arrangeGrob(grobs = boxplot_list, ncol = ncols)
#   boxplot <- labled_plots_grid(boxplot, title, labels_cols, labels_rows, 9, 7)
#   grid.arrange(boxplot)
#   
#   plot <- arrangeGrob(grobs = plot_list, ncol = ncols)
#   plot <- labled_plots_grid(plot, title, labels_cols, labels_rows, 9, 7)
#   grid.arrange(plot)
#   
#   plot_loglog <- arrangeGrob(grobs = plot_loglog_list, ncol = ncols)
#   plot_loglog <- labled_plots_grid(plot_loglog, title, labels_cols, labels_rows, 9, 7)
#   grid.arrange(plot_loglog)
#   
#   plot_loglog_normalized <- arrangeGrob(grobs = plot_loglog_normalized_list, ncol = ncols)
#   plot_loglog_normalized <- labled_plots_grid(plot_loglog_normalized, title, labels_cols, labels_rows, 9, 7)
#   grid.arrange(plot_loglog_normalized)
# }
# dev.off()




### overall quantitative results ----
source(paste("tests/", test_suite, "/templates/plot_overall.R", sep = ""))

## open a pdf where to save the plots
pdf(paste(path_images, "overall_quantitative_results.pdf", sep = ""), width = 15, height = 9)

## reconstruction RMSE at locations
plots <- plot_overall(
  name_aggregation_option_vect = name_aggregation_option_vect,
  name_group_vect = name_group_vect,
  data_plot = rmses[["reconstruction_locs"]],
  title_vect = paste(
    "Reconstruction RMSE at locations w.r.t the",
    c("signal-to-noise ratio (NSR)",
      "n_stat_units", "n_locs", "n_nodes")
  ), 
  colors = colors,
  limits = NULL
)

## loadings
name_vect <- c("1", "2", "3")
plots <- list()
for (k in 1:3) {
  plots[[k]] <- plot_overall(
    name_aggregation_option_vect = c("lambda"),
    name_group_vect = c(expression(lambda)),
    data_plot = rmses[["loadings_locs"]][rmses[["loadings_locs"]]$Group == k & rmses[["loadings_locs"]]$NSR == 1, ],
    title_vect = NULL,
    colors = colors,
    limits = NULL,
    show_lineplot=F
  )
}

## scores
for (k in 1:3) {
  plots <- plot_overall(
    name_aggregation_option_vect = name_aggregation_option_vect,
    name_group_vect = name_group_vect,
    data_plot = rmses[["scores"]][rmses[["scores"]]$Group == k, ],
    title_vect = paste(
      "Scores RMSE component", name_vect[k], "w.r.t the",
      c(
        "signal-to-noise ratio (NSR)",
        "n_stat_units", "n_locs", "n_nodes"
      )
    ),
    colors = colors,
    limits = NULL
  )
}

## loadings locs
source(paste("tests/", test_suite, "/templates/plot_fpcs_err.R", sep = ""))
plot_fpcs_err(
  test_options = test_options, 
  data_plot = rmses[["loadings_locs"]], 
  colors = colors,
  group_name = "NSR")

dev.off()
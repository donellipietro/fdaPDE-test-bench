# % %%%%%%%%%%%%%% %
# % % Test: fPCA % %
# % %%%%%%%%%%%%%% %

rm(list = ls())
graphics.off()


## global variables ----
test_suite <- "subspace-it"
TEST_SUITE <- "subspace-it"


## prerequisite ----
source(paste("tests/", test_suite, "/utils/generate_options.R", sep = ""))


## libraries ----

## json
suppressMessages(library(jsonlite))

## algebraic utils
suppressMessages(library(pracma))

## data visualization
suppressMessages(library(tidyr))
suppressMessages(library(dplyr))
suppressMessages(library(ggplot2))
suppressMessages(library(viridis))
suppressMessages(library(stringr))
suppressMessages(library(RColorBrewer))
suppressMessages(library(grid))
suppressMessages(library(gridExtra))

## sources ----
source("src/utils/directories.R")
source("src/utils/results_management.R")
source("src/utils/plots.R")


## paths ----
path_options <- paste("queue/", sep = "")
path_results <- paste("results/", test_suite, "/", sep = "")
path_images <- paste("images/", test_suite, "/", sep = "")
file_log <- "log.txt"


## options ----


## names and labels
names_models <- c("sequential", 
                  "subspace", 
                  "subspace_experimental",
                  "direct"
)
lables_models <- c("sequential", 
                   "subspace", 
                   "subspace_experimental",
                   "direct"
)

## colors used in the plots
#colors <- brewer.pal(length(lables_models), "Set3")

colors <- c(
  "sequential" = "#2297E6",
  "subspace" = "#F5C710",
  "subspace_experimental" = "lightgreen",
  "direct" = "#DF536B"
)

## load data ----

## check arguments passed by terminal
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  args[1] <- "test3"
}

## main test name
name_main_test <- args[1]
cat(paste("\nTest selected:", name_main_test, "\n"))
path_results <- paste(path_results, name_main_test, "/", sep = "")
path_images <- paste(path_images, name_main_test, "/", sep = "")
mkdir(path_images)

## generate options
generate_options(name_main_test, path_options)

## list of available tests
file_test_vect <- sort(list.files(path_options))

## room for solutions
names_columns <- c("Group","NSR", names_models)
empty_df <- data.frame(matrix(NaN, nrow = 0, ncol = length(names_columns)))
colnames(empty_df) <- names_columns
times <- empty_df
lambdas <- list()
rmses <- list()
irmses <- list()
angles <- list()


for (file_test in file_test_vect) {
  ## load specs
  file_json <- paste(path_options, file_test, sep = "")
  parsed_json <- fromJSON(file_json)
  name_test <- parsed_json$test$name_test
  n_nodes <- parsed_json$dimensions$n_nodes
  n_locs <- parsed_json$dimensions$n_locs
  n_stat_units <- parsed_json$dimensions$n_stat_units
  n_reps <- parsed_json$dimensions$n_reps
  n_comp <- parsed_json$dimensions$n_comp
  NSR <- parsed_json$noise$NSR

  cat(paste("\nTest ", name_test, ":\n", sep = ""))

  ## load batches
  for (i in 1:n_reps) {
    ## laod batch and log if not present
    sink(file_log, append = TRUE)
    tryCatch(
      {
        path_batch <- paste(path_results, name_test, "/", "batch_", i, "/", sep = "")
        load(paste(path_batch, "batch_", i, "_results_evaluation.RData", sep = ""))
      },
      error = function(e) {
        cat(paste("Error in test ", name_test, " - batch ", i, ": ", conditionMessage(e), "\n", sep = ""))
      }
    )
    sink()

    ## times
    times <- add_results(
      times,
      c(
        list(n_nodes = n_nodes, n_locs = n_locs, n_stat_units = n_stat_units, NSR = NSR),
        extract_new_results(results_evaluation, names_models, "execution_time")
      ),
      names_columns
    )
    ## lambas
    lambdas <- add_results(
      lambdas,
      c(
        list(n_nodes = n_nodes, n_locs = n_locs, n_stat_units = n_stat_units, NSR = NSR),
        extract_new_results(results_evaluation, names_models, "lambdas")
      ),
      names_columns
    )

    ## rmse
    for (name in c("reconstruction_locs", "loadings_locs", "scores","proj_scores","centering_locs")) {
      rmses[[name]] <- add_results(
        rmses[[name]],
        c(
          list(n_nodes = n_nodes, n_locs = n_locs, n_stat_units = n_stat_units, NSR = NSR),
          extract_new_results(results_evaluation, names_models, c("rmse", name))
        ),
        names_columns
      )
    }

    ## irmse
    for (name in c("reconstruction", "loadings")) {
      irmses[[name]] <- add_results(
        irmses[[name]],
        c(
          list(n_nodes = n_nodes, n_locs = n_locs, n_stat_units = n_stat_units, NSR = NSR),
          extract_new_results(results_evaluation, names_models, c("irmse", name))
        ),
        names_columns
      )
    }

    ## angles
    for (name in c("orthogonality_m", "orthogonality_f")) {
      angles[[name]] <- add_results(
        angles[[name]],
        c(
          list(n_nodes = n_nodes, n_locs = n_locs, n_stat_units = n_stat_units, NSR = NSR),
          extract_new_results(results_evaluation, names_models, c("angles", name))
        ),
        names_columns
      )
    }

    cat(paste("- Batch", i, "loaded\n"))
  }

  ## remove option file
  file.remove(file_json)
}


## analysis ----

## names
name_aggregation_option_vect <- c("NSR")
name_group_vect <- c("NSR")

### time complexity ----

## open a pdf where to save the plots
pdf(paste(path_images, "time_complexity.pdf", sep = ""), width = 15, height = 15)

## data and titles
data_plot <- times
values_name <- "Time [seconds]"
title_vect <- paste(
  "Execution times w.r.t the",
  c(
    "signal-to-noise ratio (NSR)"
  )
)
limits <- NULL
## options
options_grid <- list()
for (name_ao in name_aggregation_option_vect) {
  options_grid[[name_ao]] <- unique(data_plot[, name_ao])
}

for (i in 1:length(name_aggregation_option_vect)) {
  boxplot_list <- list()
  plot_list <- list()
  plot_loglog_list <- list()
  plot_loglog_normalized_list <- list()
  
  name_aggregation_option <- name_aggregation_option_vect[i]
  group_name <- name_group_vect[i]
  title <- title_vect[i]
  
  options_grid_selected <- options_grid
  options_grid_selected[[name_aggregation_option]] <- NULL
  names_options_selected <- names(options_grid_selected)
  labels_options_selected <- name_group_vect[-i]
  
  # Handle 1D case
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
  
  for (j in 1:nrow(combinations_options)) {
    ## data preparation
    if (length(names_options_selected) == 0) {
      # 1D case: use all data
      data_plot_trimmed <- data_plot[, c(name_aggregation_option, names_models)]
    } else {
      # ND case: filter by combination
      condition <- rep(TRUE, nrow(data_plot))
      for (k in seq_along(names_options_selected)) {
        condition <- condition & (data_plot[[names_options_selected[k]]] == combinations_options[j, k])
      }
      data_plot_trimmed <- data_plot[condition, c(name_aggregation_option, names_models)]
    }
    
    colnames(data_plot_trimmed)[1] <- "Group"
    
    # Skip if data is empty
    if (nrow(data_plot_trimmed) == 0) next
    
    # Remove models with all-NaN results
    valid_models <- names_models[!apply(data_plot_trimmed[, names_models], 2, function(x) all(is.nan(x)))]
    if (length(valid_models) == 0) next
    
    # Aggregate
    data_plot_aggregated <- aggregate(. ~ Group, data = data_plot_trimmed[, c("Group", valid_models)], FUN = median)
    
    ## plots
    boxplot_list[[j]] <- plot.grouped_boxplots(
      data_plot_trimmed[, c("Group", valid_models)],
      values_name = NULL,
      group_name = group_name,
      subgroup_name = "Approaches",
      subgroup_labels = lables_models[match(valid_models, names_models)],
      subgroup_colors = colors[match(valid_models, names_models)],
      limits = limits,
      LEGEND = FALSE
    ) + standard_plot_settings()
    
    plot_list[[j]] <- plot.multiple_lines(
      data_plot_aggregated[, c("Group", valid_models)],
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
    
    plot_loglog_list[[j]] <- plot.multiple_lines(
      data_plot_aggregated[, c("Group", valid_models)],
      values_name = NULL,
      x_name = group_name,
      x_breaks = TRUE,
      subgroup_name = "Approaches",
      subgroup_labels = lables_models[match(valid_models, names_models)],
      subgroup_colors = colors[match(valid_models, names_models)],
      LEGEND = FALSE,
      limits = range,
      NORMALIZED = FALSE,
      LOGLOG = TRUE
    ) + standard_plot_settings()
    
    plot_loglog_normalized_list[[j]] <- plot.multiple_lines(
      data_plot_aggregated[, c("Group", valid_models)],
      values_name = NULL,
      x_name = group_name,
      x_breaks = TRUE,
      subgroup_name = "Approaches",
      subgroup_labels = lables_models[match(valid_models, names_models)],
      subgroup_colors = colors[match(valid_models, names_models)],
      LEGEND = FALSE,
      limits = c(1, limits[2]),
      NORMALIZED = TRUE,
      LOGLOG = TRUE
    ) + standard_plot_settings()
  }
  
  # Handle layout safely if 1D: use 1 column
  ncols <- if (length(labels_cols) == 0) 1 else length(labels_cols)
  
  boxplot <- arrangeGrob(grobs = boxplot_list, ncol = ncols)
  boxplot <- labled_plots_grid(boxplot, title, labels_cols, labels_rows, 9, 7)
  grid.arrange(boxplot)
  
  plot <- arrangeGrob(grobs = plot_list, ncol = ncols)
  plot <- labled_plots_grid(plot, title, labels_cols, labels_rows, 9, 7)
  grid.arrange(plot)
  
  plot_loglog <- arrangeGrob(grobs = plot_loglog_list, ncol = ncols)
  plot_loglog <- labled_plots_grid(plot_loglog, title, labels_cols, labels_rows, 9, 7)
  grid.arrange(plot_loglog)
  
  plot_loglog_normalized <- arrangeGrob(grobs = plot_loglog_normalized_list, ncol = ncols)
  plot_loglog_normalized <- labled_plots_grid(plot_loglog_normalized, title, labels_cols, labels_rows, 9, 7)
  grid.arrange(plot_loglog_normalized)
}
dev.off()


### overall quantitative results ----

## open a pdf where to save the plots
pdf(paste(path_images, "overall_quantitative_results.pdf", sep = ""), width = 15, height = 9)

## reconstruction RMSE at locations
data_plot <- rmses[["reconstruction_locs"]]
title_vect <- paste(
  "Reconstruction RMSE at locations w.r.t the",
  c(
    "signal-to-noise ratio (NSR)"
  )
)
limits <- NULL
source(paste("tests/", test_suite, "/templates/plot_overall.R", sep = ""))
# 
# ## reconstruction IRMSE
# data_plot <- irmses[["reconstruction"]]
# title_vect <- paste(
#   "Reconstruction IRMSE w.r.t the",
#   c(
#     "number of nodes (K)",
#     "number of statistical units (N)",
#     "number of locations (S)"
#   )
# )
# limits <- NULL
# source(paste("tests/", test_suite, "/templates/plot_overall.R", sep = ""))

## centering
data_plot <- rmses[["centering_locs"]]
title_vect <- paste(
  "Centering RMSE at locations w.r.t the",
  c(
    "number of nodes (K)",
    "number of statistical units (N)",
    "number of locations (S)",
    "signal-to-noise ratio (NSR)"
  )
)
limits <- NULL
source(paste("tests/", test_suite, "/templates/plot_overall.R", sep = ""))


## lambdas
name_vect <- c("1", "2", "3")
for (k in 1:3) {
  data_plot <- lambdas[lambdas$Group == k, ]
  title_vect <- paste(
    "Smoothing parameter for fPC", name_vect[k], "w.r.t the",
    c(
      "signal-to-noise ratio (NSR)"
    )
  )
  limits <- NULL
  source(paste("tests/", test_suite, "/templates/plot_overall.R", sep = ""))
}

## loadings
name_vect <- c("1", "2", "3")
for (k in 1:3) {
  data_plot <- rmses[["loadings_locs"]][rmses[["loadings_locs"]]$Group == k, ]
  title_vect <- paste(
    "Loadings at locations RMSE component", name_vect[k], "w.r.t the",
    c(
      "signal-to-noise ratio (NSR)"
    )
  )
  limits <- NULL
  source(paste("tests/", test_suite, "/templates/plot_overall.R", sep = ""))
}
# for (k in 1:3) {
#   data_plot <- irmses[["loadings"]][irmses[["loadings"]]$Group == k, ]
#   title_vect <- paste(
#     "Loadings IRMSE component", name_vect[k], "w.r.t the",
#     c(
#       "number of nodes (K)",
#       "number of statistical units (N)",
#       "number of locations (S)"
#     )
#   )
#   limits <- NULL
#   source(paste("tests/", test_suite, "/templates/plot_overall.R", sep = ""))
# }



for (k in 1:3) {
  data_plot <- rmses[["scores"]][rmses[["scores"]]$Group == k, ]
  title_vect <- paste(
    "Scores RMSE component", name_vect[k], "w.r.t the",
    c(
      "signal-to-noise ratio (NSR)"
    )
  )
  limits <- NULL
  source(paste("tests/", test_suite, "/templates/plot_overall.R", sep = ""))
}


data_plot <- rmses[["loadings_locs"]]
source(paste("tests/", test_suite, "/templates/plot_fpcs_err.R", sep = ""))



# ## orthogonality check
# name_vect <- c("1-2", "1-3", "2-3")
# for (k in 1:3) {
#   data_plot <- angles[["orthogonality_m"]][angles[["orthogonality_m"]]$Group == k, ]
#   title_vect <- paste(
#     "Orthogonality check (l2) pair", name_vect[k], "w.r.t the",
#     c(
#       "number of nodes (K)",
#       "number of statistical units (N)",
#       "number of locations (S)",
#       "signal-to-noise ratio (NSR)"
#     )
#   )
#   limits <- c(80, 100)
#   source(paste("tests/", test_suite, "/templates/plot_overall.R", sep = ""))
# }
# for (k in 1:3) {
#   data_plot <- angles[["orthogonality_f"]][angles[["orthogonality_f"]]$Group == k, ]
#   title_vect <- paste(
#     "Orthogonality check (L2) pair", name_vect[k], "w.r.t the",
#     c(
#       "number of nodes (K)",
#       "number of statistical units (N)",
#       "number of locations (S)"
#     )
#   )
#   limits <- c(80, 100)
#   source(paste("tests/", test_suite, "/templates/plot_overall.R", sep = ""))
# }


dev.off()


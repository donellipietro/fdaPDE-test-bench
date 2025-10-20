## TODO:
#' - 

rm(list = ls())
graphics.off()

source("src/utils/plots.R")

## global variables ----
test_suite <- "fpca-2D"
TEST_SUITE <- "fpca-2D"

## prerequisite ----
source(paste("tests/", test_suite, "/utils/generate_options.R", sep = ""))
source(paste("tests/", test_suite, "/templates/load_results.R", sep = ""))
source(paste("tests/", test_suite, "/templates/plot_overall.R", sep = ""))

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



## load data ----

## check arguments passed by terminal
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  args[1] <- "test2"
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
test_options$model_names <- c("sequential","subspace","subspace_experimental")


## room for solutions
names_columns <- c("Group","NSR","n_nodes","n_locs","n_stat_units",  test_options$model_names)
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
  test_options$model_names <- c("sequential","subspace","subspace_experimental")
  
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
  for (name in c("reconstruction_locs", "loadings_locs", "scores","scores_orth","centering_locs")) {
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
name_aggregation_option_vect <- c("NSR")
name_group_vect <- c("NSR")


colors <- c(
  "seq" = "coral3",
  "subspace" = "aquamarine4",
  "sub-exp" = "darkorchid3",
  "direct" = "blue4"
)

fill_values <- c(
  "seq" = "darksalmon",
  "subspace" = "aquamarine3",
  "sub-exp" = "mediumorchid",
  "direct" = "cornflowerblue"
)

ymin <- 0
ymax <- 1.5

## loadings
name_vect <- c("1", "2", "3")
plots <- list()
for (k in 1:3) {
  plots[[k]] <- plot_overall(
    name_aggregation_option_vect = name_aggregation_option_vect,
    name_group_vect = name_group_vect,
    data_plot = rmses[["loadings_locs"]][rmses[["loadings_locs"]]$Group == k, ],
    title_vect = NULL,
    colors = colors,
    limits = NULL
  )
}

## reconstruction
plots <- plot_overall(
  name_aggregation_option_vect = name_aggregation_option_vect,
  name_group_vect = name_group_vect,
  data_plot = rmses[["reconstruction_locs"]],
  title_vect = NULL,
  colors = colors,
  limits = NULL
)

library(patchwork)
model_names <- c("seq","sub",expression(paste("sub-",lambda[i],sep="")),"direct")


pdf("reconstruction_rand_err.pdf", height = 5,width = 10)
p <- plots$NSR$boxplot_list[[1]] + ylab("Reconstruction")
p <- p + 
  scale_fill_manual(name = NULL, values = fill_values, labels = model_names) +
  scale_color_manual(name = NULL, values = colors, labels = model_names)
p
dev.off()

plots <- plot_overall(
  name_aggregation_option_vect = name_aggregation_option_vect,
  name_group_vect = name_group_vect,
  data_plot = rmses[["scores_orth"]],
  title_vect = NULL,
  colors = colors,
  limits = NULL
)

pdf("scores_orth_rand_err.pdf", height = 5,width = 10)
p <- plots$NSR$boxplot_list[[1]] + ylab("Deviation from the scores orthogonality")
p <- p + 
  scale_fill_manual(name = NULL, values = fill_values, labels = model_names) +
  scale_color_manual(name = NULL, values = colors, labels = model_names) 
p
dev.off()


## loadings
name_vect <- c("1", "2", "3")
plots <- list()
for (k in 1:3) {
  plots[[k]] <- plot_overall(
    name_aggregation_option_vect = name_aggregation_option_vect,
    name_group_vect = name_group_vect,
    data_plot = rmses[["loadings_locs"]][rmses[["loadings_locs"]]$Group == k, ],
    title_vect = NULL,
    colors = colors,
    limits = NULL  
    )
}

library(patchwork)
p1 <- plots[[1]]$NSR$boxplot_list[[1]] + ylim(ymin, ymax) + ylab("fPC1")
p2 <- plots[[2]]$NSR$boxplot_list[[1]] + ylim(ymin, ymax) + ylab("fPC2")
p3 <- plots[[3]]$NSR$boxplot_list[[1]] + ylim(ymin, ymax) + ylab("fPC3")

pdf("loadings_rand_err.pdf", height = 5,width = 10)
p1 <- p1 + 
  scale_fill_manual(name = NULL, values = fill_values, labels = model_names) +
  scale_color_manual(name = NULL, values = colors, labels = model_names) 
p2 <- p2 + 
  scale_fill_manual(name = NULL, values = fill_values, labels = model_names) +
  scale_color_manual(name = NULL, values = colors, labels = model_names) 
p3 <- p3 + 
  scale_fill_manual(name = NULL, values = fill_values, labels = model_names) +
  scale_color_manual(name = NULL, values = colors, labels = model_names)

# Combine with shared legend
combined <- p1 / p2 / p3 + plot_layout(guides = "collect") &
  theme(legend.position = "top", legend.text  = element_text(size = 12))
combined
dev.off()


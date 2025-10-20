## TODO:
#' - correct the time complexity analysis
#' - define test_suite somewhere else
#' - correct the case for multiple aggregation vectors (e.g. n_nodes, NSR)
#' - understand difference between aggregation and group
#' - put the 

rm(list = ls())
graphics.off()

source("src/utils/plots.R")

## global variables ----
test_suite <- "lambda-sens"
TEST_SUITE <- "lambda-sens"

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


test_options$model_names <- c("sequential","subspace")

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
  test_options$model_names <- c("sequential","subspace")
  
  
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


colors <- c(
  "sequential" = "coral3",
  "subspace" = "aquamarine4",
  "direct" = "blue4"
)

fill_values <- c(
  "sequential" = "darksalmon",
  "subspace" = "aquamarine3",
  "direct" = "cornflowerblue"
)

ymin <- 0
ymax <- 1.5


## loadings
name_vect <- c("1", "2", "3")
plots <- list()

for (k in 1:3) {
  plots[[k]] <- plot_overall(
    name_aggregation_option_vect = c("lambda"),
    name_group_vect = c(expression(lambda)),
    data_plot = rmses[["loadings_locs"]][rmses[["loadings_locs"]]$Group == k & rmses[["loadings_locs"]]$NSR == 1,],
    title_vect = NULL,
    colors = colors,
    limits = NULL,
    show_lineplot=F
  )
}

library(patchwork)
p1 <- plots[[1]]$lambda$boxplot_list[[1]] + ylim(ymin, ymax) + ylab("fPC1")
p2 <- plots[[2]]$lambda$boxplot_list[[1]] + ylim(ymin, ymax) + ylab("fPC2")
p3 <- plots[[3]]$lambda$boxplot_list[[1]] + ylim(ymin, ymax) + ylab("fPC3")

pdf("lambda-sens-quantitative.pdf", height = 7.5,width = 10)
p1 <- p1 + 
  scale_fill_manual(name = NULL, values = fill_values, labels = c("seq-R1","subspace")) +
  scale_color_manual(name = NULL, values = colors, labels = c("seq-R1","subspace")) 
p2 <- p2 + 
  scale_fill_manual(name = NULL, values = fill_values, labels = c("seq-R1","subspace")) +
  scale_color_manual(name = NULL, values = colors, labels = c("seq-R1","subspace")) 
p3 <- p3 + 
  scale_fill_manual(name = NULL, values = fill_values, labels = c("seq-R1","subspace")) +
  scale_color_manual(name = NULL, values = colors, labels = c("seq-R1","subspace")) 

# Combine with shared legend
combined <- p1 / p2 / p3 + plot_layout(guides = "collect") &
  theme(legend.position = "top", legend.text  = element_text(size = 12))
combined
dev.off()
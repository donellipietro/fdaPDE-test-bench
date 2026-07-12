suppressMessages(library(ggplot2))

source("src/utils/directories.R")
source("tests/smoothing-example/config.R")

args <- commandArgs(trailingOnly = TRUE)
requested <- if (length(args)) args[1] else "all"
families <- if (requested == "all") test_groups$all else requested
cfg <- load_config()
suite_results <- file.path(cfg$PATH_RESULTS, test_suite)
metric_files <- list.files(suite_results, pattern = "^metrics\\.csv$", recursive = TRUE, full.names = TRUE)
if (!length(metric_files)) stop("no smoothing metrics found under ", suite_results)

results <- do.call(rbind, lapply(metric_files, read.csv, stringsAsFactors = FALSE))
results <- results[results$family %in% families, , drop = FALSE]
if (!nrow(results)) stop("no metrics found for requested families")

smoke <- all(results$smoke_test)
spec <- smoothing_experiment_spec(smoke)
expected <- do.call(rbind, lapply(families, function(family) {
  expand.grid(
    family = family,
    level = spec$grids[[family]],
    discretization = c("fem", "spline"),
    stringsAsFactors = FALSE
  )
}))
counts <- aggregate(repetition ~ family + level + discretization, results, function(x) length(unique(x)))
names(counts)[4] <- "completed_repetitions"
completeness <- merge(expected, counts, all.x = TRUE)
completeness$completed_repetitions[is.na(completeness$completed_repetitions)] <- 0L
completeness$expected_repetitions <- spec$repetitions
completeness$complete <- completeness$completed_repetitions == completeness$expected_repetitions

key <- paste(results$family, results$level, results$repetition, results$discretization, sep = "|")
numeric_metrics <- c("wall_seconds", "cpu_seconds", "cpu_usage_percent", "lambda", "gcv", "normalized_rmse")
if (anyDuplicated(key)) stop("duplicate fit metrics detected")
if (any(!is.finite(as.matrix(results[numeric_metrics])))) stop("missing or non-finite telemetry detected")
if (any(!completeness$complete)) stop("incomplete smoothing experiment; inspect completeness.csv")

split_results <- split(results, interaction(results$family, results$level, results$discretization, drop = TRUE))
summary_rows <- lapply(split_results, function(x) {
  data.frame(
    family = x$family[1], level = x$level[1], n_locs = x$n_locs[1],
    n_nodes = x$n_nodes[1], snr = x$snr[1], discretization = x$discretization[1],
    repetitions = nrow(x),
    normalized_rmse_mean = mean(x$normalized_rmse), normalized_rmse_sd = sd(x$normalized_rmse),
    wall_seconds_mean = mean(x$wall_seconds), wall_seconds_sd = sd(x$wall_seconds),
    cpu_seconds_mean = mean(x$cpu_seconds), cpu_seconds_sd = sd(x$cpu_seconds),
    cpu_usage_percent_mean = mean(x$cpu_usage_percent),
    stringsAsFactors = FALSE
  )
})
summary <- do.call(rbind, summary_rows)

aggregate_dir <- file.path(suite_results, "aggregate", requested)
image_dir <- file.path(cfg$PATH_IMAGES, test_suite, requested)
dir.create(aggregate_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(image_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(results, file.path(aggregate_dir, "all_metrics.csv"), row.names = FALSE)
write.csv(summary, file.path(aggregate_dir, "summary.csv"), row.names = FALSE)
write.csv(completeness, file.path(aggregate_dir, "completeness.csv"), row.names = FALSE)

results$x_value <- results$level
plot_metric <- function(metric, label) {
  plot <- ggplot(results, aes(x = x_value, y = .data[[metric]], color = discretization)) +
    stat_summary(fun = mean, geom = "point", size = 2) +
    stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.05) +
    facet_wrap(~family, scales = "free_x") +
    labs(x = "Varied factor", y = label, color = "Discretization") +
    theme_minimal(base_size = 11)
  if (!smoke) plot <- plot + stat_summary(fun = mean, geom = "line")
  ggsave(file.path(image_dir, paste0(metric, ".png")), plot, width = 9, height = 4.5, dpi = 160)
}

plot_metric("normalized_rmse", "Normalized RMSE")
plot_metric("wall_seconds", "Wall time (seconds)")
plot_metric("cpu_seconds", "CPU time (seconds)")
plot_metric("cpu_usage_percent", "CPU usage (%)")

cat("Validated", nrow(results), "paired-fit rows across", length(families), "families.\n")
cat("Summary:", file.path(aggregate_dir, "summary.csv"), "\n")

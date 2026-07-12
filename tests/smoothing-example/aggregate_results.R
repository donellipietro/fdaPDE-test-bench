rm(list = ls())
graphics.off()

invisible(suppressMessages(sapply(
  c("jsonlite", "ggplot2", "tidyr", "dplyr", "grid", "gridExtra"),
  require,
  character.only = TRUE
)))

source("src/utils/cat.R")
source("src/utils/directories.R")
source("src/utils/options.R")
source("src/utils/load_results_utils.R")
source("src/utils/plotting_utils.R")
source("tests/smoothing-example/config.R")
source("tests/smoothing-example/utils/generate_options.R")
source("tests/smoothing-example/utils/generate_data.R")

args <- commandArgs(trailingOnly = TRUE)
requested <- if (length(args)) args[1] else name_main_test_default
families <- if (requested == "all") test_groups$all else requested
smoke <- tolower(Sys.getenv("SMOKE_TEST", "0")) %in% c("1", "true", "yes", "y")
spec <- smoothing_experiment_spec(smoke)
cfg <- load_config()
all_rows <- list()

plots_catalog <- list(
  boxplots = TRUE,
  lines = TRUE,
  logx = FALSE,
  loglog = FALSE,
  normalized = FALSE
)

for (family in families) {
  path_list <- create_paths(test_suite)
  path_list$queue <- config_path(path_list$queue, family)
  path_list$logs <- config_path(path_list$logs, family)
  mkdir(c(path_list$queue, path_list$logs))
  generate_options(test_suite, family, path_list$queue)
  loaded <- load_all_quantitiative_results(path_list, family)

  varying_option <- loaded$varying_options[1]
  base <- loaded$rmse$normalized[, c("Group", varying_option), drop = FALSE]
  level <- base[[varying_option]]
  repetition <- ave(seq_along(level), level, FUN = seq_along)

  for (model_name in loaded$model_names) {
    dimensions <- spec$defaults
    dimensions[[varying_option]] <- level
    locations <- lapply(dimensions$n_locs, function(n) seq(0, 1, length.out = n))
    signal_variance <- vapply(
      locations,
      function(x) mean((truth_function(x) - mean(truth_function(x)))^2),
      numeric(1)
    )

    all_rows[[paste(family, model_name)]] <- data.frame(
      family = family,
      level = level,
      repetition = repetition,
      seed = spec$seed_base + repetition,
      smoke_test = smoke,
      n_locs = dimensions$n_locs,
      n_nodes = dimensions$n_nodes,
      snr = dimensions$snr,
      signal_variance = signal_variance,
      noise_sigma = sqrt(signal_variance / dimensions$snr),
      discretization = model_name,
      source_ref = if (model_name == "fem") cfg$FDAPDE_CPP_FEM_REF else cfg$FDAPDE_CPP_SPLINE_REF,
      wall_seconds = loaded$execution_time[[model_name]],
      peak_ram_mib = loaded$peak_ram_mib[[model_name]],
      cpu_seconds = loaded$cpu_seconds[[model_name]],
      cpu_usage_percent = loaded$cpu_usage_percent[[model_name]],
      lambda = loaded$lambdas[[model_name]],
      gcv = loaded$gcv[[model_name]],
      normalized_rmse = loaded$rmse$normalized[[model_name]],
      stringsAsFactors = FALSE
    )
  }

  image_dir <- file.path(cfg$PATH_IMAGES, test_suite, family)
  dir.create(image_dir, recursive = TRUE, showWarnings = FALSE)
  plot_specs <- list(
    normalized_rmse = list(loaded$rmse$normalized, "Normalized RMSE", "Normalized RMSE"),
    peak_ram_mib = list(loaded$peak_ram_mib, "Peak RAM", "Peak RSS [MiB]"),
    wall_seconds = list(loaded$execution_time, "Wall time", "Wall time [seconds]"),
    cpu_seconds = list(loaded$cpu_seconds, "CPU time", "CPU time [seconds]")
  )
  for (plot_name in names(plot_specs)) {
    plot_spec <- plot_specs[[plot_name]]
    values <- unlist(plot_spec[[1]][loaded$model_names], use.names = FALSE)
    pdf(file.path(image_dir, paste0(plot_name, ".pdf")), width = 10, height = 7)
    plot.aggregated_data(
      loaded,
      plot_spec[[1]],
      plot_spec[[2]],
      plot_spec[[3]],
      order = 1L,
      limits = c(0, max(values, na.rm = TRUE)),
      plots_catalog = plots_catalog
    )
    dev.off()
  }

  aggregate_dir <- file.path(cfg$PATH_RESULTS, test_suite, "aggregate", requested)
  dir.create(aggregate_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(loaded, file.path(aggregate_dir, paste0("loaded_", family, ".rds")))
}

results <- do.call(rbind, all_rows)
row.names(results) <- NULL
numeric_metrics <- c(
  "wall_seconds", "peak_ram_mib", "cpu_seconds", "cpu_usage_percent",
  "lambda", "gcv", "normalized_rmse"
)
if (any(!is.finite(as.matrix(results[numeric_metrics])))) stop("non-finite smoothing telemetry")

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
if (any(!completeness$complete)) stop("incomplete smoothing experiment")

split_results <- split(results, interaction(results$family, results$level, results$discretization, drop = TRUE))
summary <- do.call(rbind, lapply(split_results, function(x) {
  data.frame(
    family = x$family[1], level = x$level[1], n_locs = x$n_locs[1],
    n_nodes = x$n_nodes[1], snr = x$snr[1], discretization = x$discretization[1],
    repetitions = nrow(x),
    normalized_rmse_mean = mean(x$normalized_rmse), normalized_rmse_sd = sd(x$normalized_rmse),
    peak_ram_mib_mean = mean(x$peak_ram_mib), peak_ram_mib_sd = sd(x$peak_ram_mib),
    wall_seconds_mean = mean(x$wall_seconds), cpu_seconds_mean = mean(x$cpu_seconds),
    stringsAsFactors = FALSE
  )
}))

aggregate_dir <- file.path(cfg$PATH_RESULTS, test_suite, "aggregate", requested)
write.csv(results, file.path(aggregate_dir, "all_metrics.csv"), row.names = FALSE)
write.csv(summary, file.path(aggregate_dir, "summary.csv"), row.names = FALSE)
write.csv(completeness, file.path(aggregate_dir, "completeness.csv"), row.names = FALSE)
cat("Validated", nrow(results), "fit rows across", nrow(completeness), "complete cells.\n")

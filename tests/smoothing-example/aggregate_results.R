# = ========================================================================== =
# - Test: SRPDE smoothing example - aggregate results
# - Desc: Loads standard batch evaluations, validates completeness and solver
#         telemetry, writes summaries, and produces shared comparison plots.
# - Args:
#   [1] name_main_test: one family or the grouped "all" target
# = ========================================================================== =

rm(list = ls())
graphics.off()

## Load libraries ----
invisible(suppressMessages(sapply(
  c("jsonlite", "ggplot2", "tidyr", "dplyr", "grid", "gridExtra"),
  require,
  character.only = TRUE
)))

## Load general and test-specific functions ----
source("src/utils/cat.R")
source("src/utils/directories.R")
source("src/utils/options.R")
source("src/utils/load_results_utils.R")
source("src/utils/plotting_utils.R")
source("tests/smoothing-example/config.R")
source("tests/smoothing-example/utils/generate_options.R")

## Select the requested test families ----
args <- commandArgs(trailingOnly = TRUE)
requested <- if (length(args)) args[1] else name_main_test_default
families <- if (requested == "all") test_groups$all else requested
if (any(!families %in% test_groups$all)) stop("unknown smoothing experiment family")

cfg <- load_config()
aggregate_dir <- file.path(cfg$PATH_RESULTS, test_suite, "aggregate", requested)
dir.create(aggregate_dir, recursive = TRUE, showWarnings = FALSE)

all_rows <- list()
expected_rows <- list()

## Shared plot selection: one boxplot page and one line page per metric
plots_catalog <- list(
  boxplots = TRUE,
  lines = TRUE,
  logx = FALSE,
  loglog = FALSE,
  normalized = FALSE
)

## Load, validate, and plot each one-factor family ----
for (family in families) {
  ## Regenerate the option queue using the same configuration as the fit
  path_list <- create_paths(test_suite)
  path_list$queue <- config_path(path_list$queue, family)
  path_list$logs <- config_path(path_list$logs, family)
  mkdir(c(path_list$queue, path_list$logs))
  generate_options(test_suite, family, path_list$queue)

  ## Read option metadata before the shared loader consumes the queue
  option_files <- sort(list.files(path_list$queue, pattern = "\\.json$", full.names = TRUE))
  family_options <- lapply(option_files, fromJSON, simplifyVector = TRUE)
  varying_option <- family_options[[1]]$test_options$varying_options
  option_metadata <- do.call(rbind, lapply(family_options, function(options) {
    data.frame(
      level = resolve_option_value(varying_option, options),
      n_locs = options$dimensions$n_locs,
      n_nodes = options$dimensions$n_nodes,
      SNR = options$noise$SNR,
      n_reps = options$test_options$n_reps,
      stringsAsFactors = FALSE
    )
  }))

  ## Load all standard batch evaluation files for this family
  loaded <- load_all_quantitiative_results(path_list, family)
  if (!identical(loaded$varying_options, varying_option)) {
    stop(glue::glue("generated and loaded varying options do not match for {family}"))
  }

  ## Recover dimensions directly from the generated option JSON
  base <- loaded$rmse$normalized[, c("Group", varying_option), drop = FALSE]
  level <- base[[varying_option]]
  metadata_index <- match(as.character(level), as.character(option_metadata$level))
  if (anyNA(metadata_index)) stop("could not match loaded results to generated options")
  dimensions <- option_metadata[metadata_index, , drop = FALSE]
  repetition <- ave(seq_along(level), level, FUN = seq_along)

  ## Flatten the shared loaded structure into one row per model fit
  for (model_name in loaded$model_names) {
    all_rows[[glue::glue("{family} {model_name}")]] <- data.frame(
      family = family,
      level = level,
      repetition = repetition,
      seed = loaded$seed[[model_name]],
      smoke_test = SMOKE_TEST,
      n_locs = dimensions$n_locs,
      n_nodes = dimensions$n_nodes,
      snr = dimensions$SNR,
      coefficient_sin_2pi = loaded$coefficients$sin_2pi[[model_name]],
      coefficient_sin_4pi = loaded$coefficients$sin_4pi[[model_name]],
      coefficient_sin_8pi = loaded$coefficients$sin_8pi[[model_name]],
      signal_variance = loaded$signal_variance[[model_name]],
      noise_sigma = loaded$noise_sigma[[model_name]],
      discretization = model_name,
      source_ref = cfg$FDAPDE_CPP_BRANCH,
      n_basis = loaded$n_basis[[model_name]],
      linear_system_dimension = loaded$linear_system_dimension[[model_name]],
      wall_seconds = loaded$execution_time[[model_name]],
      peak_ram_mib = loaded$peak_ram_mib[[model_name]],
      cpu_seconds = loaded$cpu_seconds[[model_name]],
      cpu_usage_percent = loaded$cpu_usage_percent[[model_name]],
      setup_seconds = loaded$setup_seconds[[model_name]],
      gcv_seconds = loaded$gcv_seconds[[model_name]],
      final_fit_seconds = loaded$final_fit_seconds[[model_name]],
      solver_seconds = loaded$solver_seconds[[model_name]],
      prediction_seconds = loaded$prediction_seconds[[model_name]],
      lambda = loaded$lambdas[[model_name]],
      gcv = loaded$gcv[[model_name]],
      normalized_rmse = loaded$rmse$normalized[[model_name]],
      stringsAsFactors = FALSE
    )
  }

  ## Expected cell sizes also come from the generated option JSON
  expected_rows[[family]] <- do.call(rbind, lapply(seq_len(nrow(option_metadata)), function(i) {
    data.frame(
      family = family,
      level = option_metadata$level[i],
      discretization = loaded$model_names,
      expected_repetitions = option_metadata$n_reps[i],
      stringsAsFactors = FALSE
    )
  }))

  ## Create one standalone legend from the same model metadata as the plots
  image_dir <- file.path(cfg$PATH_IMAGES, test_suite, family)
  dir.create(image_dir, recursive = TRUE, showWarnings = FALSE)
  pdf(file.path(image_dir, "legend.pdf"), width = 6, height = 1.5, bg = "white")
  par(mar = rep(0, 4))
  plot.new()
  legend(
    "center",
    legend = loaded$model_labels,
    col = loaded$model_colors,
    lty = 1,
    lwd = 2,
    pch = 15,
    pt.cex = 1.5,
    horiz = TRUE,
    bty = "n"
  )
  dev.off()

  ## Group related pages into three outputs while retaining the shared plotter
  plot_outputs <- list(
    normalized_rmse = list(
      list(loaded$rmse$normalized, "Normalized RMSE", "Normalized RMSE")
    ),
    peak_ram_mib = list(
      list(loaded$peak_ram_mib, "Peak RAM", "Peak RSS [MiB]")
    ),
    timings = list(
      list(loaded$execution_time, "Wall time", "Wall time [seconds]"),
      list(loaded$setup_seconds, "Setup time", "Setup time [seconds]"),
      list(loaded$gcv_seconds, "GCV time", "GCV time [seconds]"),
      list(loaded$final_fit_seconds, "Final-fit time", "Final-fit time [seconds]"),
      list(loaded$solver_seconds, "Solver time", "GCV + final fit [seconds]"),
      list(loaded$prediction_seconds, "Prediction time", "Prediction time [seconds]"),
      list(loaded$cpu_seconds, "CPU time", "CPU time [seconds]")
    )
  )
  for (output_name in names(plot_outputs)) {
    plot_specs <- plot_outputs[[output_name]]
    pdf(file.path(image_dir, glue::glue("{output_name}.pdf")), width = 10, height = 7)
    for (i in seq_along(plot_specs)) {
      if (i > 1L) grid::grid.newpage()
      plot_spec <- plot_specs[[i]]
      values <- unlist(plot_spec[[1]][loaded$model_names], use.names = FALSE)
      plot.aggregated_data(
        loaded,
        plot_spec[[1]],
        plot_spec[[2]],
        plot_spec[[3]],
        order = 1L,
        limits = c(0, max(values, na.rm = TRUE)),
        plots_catalog = plots_catalog
      )
    }
    dev.off()
  }

  saveRDS(loaded, file.path(aggregate_dir, glue::glue("loaded_{family}.rds")))
}

## Validate flattened telemetry ----
results <- do.call(rbind, all_rows)
row.names(results) <- NULL
numeric_metrics <- c(
  "coefficient_sin_2pi", "coefficient_sin_4pi", "coefficient_sin_8pi",
  "signal_variance", "noise_sigma", "n_basis", "linear_system_dimension",
  "wall_seconds", "peak_ram_mib",
  "cpu_seconds", "cpu_usage_percent", "setup_seconds", "gcv_seconds",
  "final_fit_seconds", "solver_seconds", "prediction_seconds", "lambda", "gcv", "normalized_rmse"
)
if (any(!is.finite(as.matrix(results[numeric_metrics])))) stop("non-finite smoothing telemetry")

## Confirm that reported solver dimensions match each implementation
if (any(results$linear_system_dimension[results$discretization == "SRPDE-FEM"] !=
        2 * results$n_basis[results$discretization == "SRPDE-FEM"])) {
  stop("FEM driver did not report the expected coupled system dimension")
}
if (any(results$linear_system_dimension[results$discretization == "SRPDE-SPLINES"] !=
        results$n_basis[results$discretization == "SRPDE-SPLINES"])) {
  stop("spline driver did not report the expected direct system dimension")
}

phase_sum <- rowSums(results[c(
  "setup_seconds", "gcv_seconds", "final_fit_seconds", "prediction_seconds"
)])
if (any(abs(results$wall_seconds - phase_sum) > 1e-9)) stop("phase timings do not sum to wall time")

## Confirm that both models used the same sampled truth and noise per repetition
paired_fields <- c(
  "seed", "coefficient_sin_2pi", "coefficient_sin_4pi",
  "coefficient_sin_8pi", "signal_variance", "noise_sigma"
)
paired_results <- split(results, interaction(results$family, results$level, results$repetition, drop = TRUE))
paired <- vapply(paired_results, function(x) {
  nrow(x) == 2L && length(unique(x$discretization)) == 2L &&
    all(vapply(x[paired_fields], function(values) length(unique(values)) == 1L, logical(1)))
}, logical(1))
if (any(!paired)) stop("models did not receive identical sampled data")

## Validate the expected repetition count in every cell ----
expected <- do.call(rbind, expected_rows)
counts <- aggregate(repetition ~ family + level + discretization, results, function(x) length(unique(x)))
names(counts)[4] <- "completed_repetitions"
completeness <- merge(expected, counts, all.x = TRUE)
completeness$completed_repetitions[is.na(completeness$completed_repetitions)] <- 0L
completeness$complete <- completeness$completed_repetitions == completeness$expected_repetitions
if (any(!completeness$complete)) stop("incomplete smoothing experiment")

## Write readable per-cell summaries ----
split_results <- split(results, interaction(results$family, results$level, results$discretization, drop = TRUE))
summary <- do.call(rbind, lapply(split_results, function(x) {
  data.frame(
    family = x$family[1], level = x$level[1], n_locs = x$n_locs[1],
    n_nodes = x$n_nodes[1], snr = x$snr[1], discretization = x$discretization[1],
    repetitions = nrow(x), n_basis = x$n_basis[1],
    linear_system_dimension = x$linear_system_dimension[1],
    coefficient_sin_2pi_mean = mean(x$coefficient_sin_2pi),
    coefficient_sin_2pi_sd = sd(x$coefficient_sin_2pi),
    coefficient_sin_4pi_mean = mean(x$coefficient_sin_4pi),
    coefficient_sin_4pi_sd = sd(x$coefficient_sin_4pi),
    coefficient_sin_8pi_mean = mean(x$coefficient_sin_8pi),
    coefficient_sin_8pi_sd = sd(x$coefficient_sin_8pi),
    normalized_rmse_mean = mean(x$normalized_rmse), normalized_rmse_sd = sd(x$normalized_rmse),
    peak_ram_mib_mean = mean(x$peak_ram_mib), peak_ram_mib_sd = sd(x$peak_ram_mib),
    wall_seconds_mean = mean(x$wall_seconds), setup_seconds_mean = mean(x$setup_seconds),
    gcv_seconds_mean = mean(x$gcv_seconds), final_fit_seconds_mean = mean(x$final_fit_seconds),
    solver_seconds_mean = mean(x$solver_seconds), prediction_seconds_mean = mean(x$prediction_seconds),
    cpu_seconds_mean = mean(x$cpu_seconds),
    stringsAsFactors = FALSE
  )
}))

write.csv(results, file.path(aggregate_dir, "all_metrics.csv"), row.names = FALSE)
write.csv(summary, file.path(aggregate_dir, "summary.csv"), row.names = FALSE)
write.csv(completeness, file.path(aggregate_dir, "completeness.csv"), row.names = FALSE)
cat(glue::glue(
  "Validated {nrow(results)} fit rows across {nrow(completeness)} complete cells.\n",
  .trim = FALSE
))

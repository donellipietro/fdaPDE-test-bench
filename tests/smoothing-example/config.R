TEST_SUITE <- "SRPDE smoothing example"
test_suite <- "smoothing-example"
test_groups <- list(all = c("vary_n_locs", "vary_n_nodes", "vary_snr"))
name_main_test_default <- "all"
FORCE_FIT <- FALSE
FORCE_EVALUATE <- FALSE
IGNORE_CPP_OUTPUT <- TRUE
RUN <- list(tests = TRUE, analysis = TRUE, quantitative_analysis = TRUE)
order <- 1L

smoothing_experiment_spec <- function(smoke = FALSE) {
  list(
    repetitions = if (smoke) 2L else 30L,
    defaults = list(n_locs = 120L, n_nodes = 81L, snr = 10),
    grids = list(
      vary_n_locs = if (smoke) 40L else c(40L, 80L, 160L),
      vary_n_nodes = if (smoke) 21L else c(21L, 41L, 81L),
      vary_snr = if (smoke) 2 else c(2, 5, 10, 20)
    ),
    evaluation_points = 1001L,
    lambda_exponents = seq(-6, 0, length.out = 9L),
    gcv_probes = 20L,
    seed_base = 141200L
  )
}

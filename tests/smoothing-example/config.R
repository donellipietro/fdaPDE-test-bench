## Global variables ----

## Test suite full name and acronym
# - TEST_SUITE is for printing only
# - test_suite is used to create directories (no spaces, please)
TEST_SUITE <- "SRPDE smoothing example"
test_suite <- "smoothing-example"

## Tests included in the grouped "all" target
test_groups <- list(all = c("vary_n_locs", "vary_n_nodes", "vary_snr"))

## Force fit/evaluation even if saved results are available
FORCE_FIT <- FALSE
FORCE_EVALUATE <- FALSE

## Execution flow modifiers
RUN <- list()
RUN$tests <- TRUE
RUN$analysis <- TRUE
RUN$quantitative_analysis <- TRUE
SMOKE_TEST <- FALSE
SMOKE_TEST <- isTRUE(SMOKE_TEST) ||
  tolower(Sys.getenv("SMOKE_TEST", "false")) %in% c("1", "true", "yes", "y")

## C++ output
IGNORE_CPP_OUTPUT <- TRUE

## Defaults
name_main_test_default <- "all"
order <- 1L # Boxplot grouping | Rows | Cols


## Global variables ----

## Test suite full name and acronym
# - TEST_SUITE is for printing only
# - test_suite will be used to create directories (no spaces, please)
TEST_SUITE <- "Template base"
test_suite <- "template_base"

## Force fit/evaluation even if a fit is already available
FORCE_FIT <- FALSE
FORCE_EVALUATE <- FALSE

## Execution flow modifiers
RUN <- list()
RUN$tests <- TRUE
SMOKE_TEST <- FALSE
SMOKE_TEST <- isTRUE(SMOKE_TEST) ||
  tolower(Sys.getenv("SMOKE_TEST", "false")) %in% c("1", "true", "yes", "y")

## C++ output
IGNORE_CPP_OUTPUT = TRUE

## Defaults
name_main_test_default <- "test1"
order <- NULL # Boxplot grouping | Rows | Cols 

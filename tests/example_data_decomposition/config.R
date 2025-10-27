
## Global variables ----

## Test suite full name and acronym
# - TEST_SUITE is for printing only
# - test_suite will be used to create directories (no spaces, please)
TEST_SUITE <- "My brand new data decomposition method"
test_suite <- "example_data_decomposition"

## Force fit/evaluation even if a fit is already available
FORCE_FIT <- F
FORCE_EVALUATE <- F

## Execution flow modifiers
RUN <- list()
RUN$tests <- TRUE
RUN$analysis <- TRUE
RUN$quantitative_analysis <- TRUE
RUN$qualitative_analysis <- TRUE

## C++ output
IGNORE_CPP_OUTPUT = TRUE
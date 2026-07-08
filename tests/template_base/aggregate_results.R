# = ========================================================================== =
# - Test: Template Base - Aggregate results
# - Desc: Placeholder aggregation entry point called by the generic runners.
# = ========================================================================== =

args <- commandArgs(trailingOnly = TRUE)
name_main_test <- if (length(args) >= 1) args[1] else "test1"

cat("No aggregation implemented for template_base/", name_main_test, ".\n", sep = "")

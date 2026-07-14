# = ========================================================================== =
# - Test: Template Base - Inspect results
# - Desc: Placeholder inspection entry point.
# = ========================================================================== =

args <- commandArgs(trailingOnly = TRUE)
name_main_test <- if (length(args) >= 1) args[1] else "test1"
file_options <- if (length(args) >= 2) args[2] else ""
option_suffix <- if (nzchar(file_options)) glue::glue(" ({file_options})") else ""

cat(glue::glue(
  "No inspection implemented for template_base/{name_main_test}{option_suffix}.\n",
  .trim = FALSE
))

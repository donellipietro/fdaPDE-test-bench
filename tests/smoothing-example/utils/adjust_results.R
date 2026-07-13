# = ========================================================================== =
# - Script: adjust_results.R
# - Desc: Provides the standard post-fit adjustment hook for model outputs.
# = ========================================================================== =

## Function: adjust_results
# - Desc:
#   No alignment or rescaling is needed for scalar smoothing predictions.
adjust_results <- function(model, data) {
  model
}

# = ========================================================================== =
# - Script: generate_data.R
# - Desc: Generates reproducible noisy observations from a fixed 1D truth.
# = ========================================================================== =

## Function: truth_function
# - Args:
#   * x: points in [0, 1]
# - Desc:
#   Fixed mixture of three sine components used by every experiment.
truth_function <- function(x) {
  sin(2 * pi * x) + 0.5 * sin(4 * pi * x) + 0.25 * sin(8 * pi * x)
}

## Function: generate_smoothing_data
# - Args:
#   * test_options: one expanded JSON option object
#   * seed: repetition-specific random seed
# - Desc:
#   Uses SNR = Var(f(x_i)) / sigma^2, hence sigma = sqrt(Var(f(x_i)) / SNR).
#   FEM and spline receive the same generated object within each repetition.
generate_smoothing_data <- function(test_options, seed) {
  ## Observation locations and truth
  n_locs <- test_options$dimensions$n_locs
  locations <- seq(0, 1, length.out = n_locs)
  truth_observed <- truth_function(locations)

  ## Gaussian noise calibrated to the requested signal-to-noise ratio
  signal_variance <- mean((truth_observed - mean(truth_observed))^2)
  noise_sigma <- sqrt(signal_variance / test_options$noise$SNR)
  set.seed(seed)
  response <- truth_observed + rnorm(n_locs, sd = noise_sigma)

  ## Common dense grid used to compare both discretizations
  evaluation <- seq(
    0,
    1,
    length.out = test_options$dimensions$n_evaluation_points
  )

  list(
    locations = matrix(locations, ncol = 1L),
    response = matrix(response, ncol = 1L),
    evaluation = matrix(evaluation, ncol = 1L),
    truth_evaluation = truth_function(evaluation),
    signal_variance = signal_variance,
    noise_sigma = noise_sigma,
    seed = seed
  )
}

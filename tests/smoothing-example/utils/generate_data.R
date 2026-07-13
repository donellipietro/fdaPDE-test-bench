# = ========================================================================== =
# - Script: generate_data.R
# - Desc: Generates reproducible noisy observations from a sampled 1D truth.
# = ========================================================================== =

## Function: truth_function
# - Args:
#   * x: points in [0, 1]
#   * coefficients: sampled weights for the three sine components
# - Desc:
#   Mixture of three fixed-frequency sine components.
truth_function <- function(x, coefficients) {
  coefficients[1] * sin(2 * pi * x) +
    coefficients[2] * sin(4 * pi * x) +
    coefficients[3] * sin(8 * pi * x)
}

## Function: generate_smoothing_data
# - Args:
#   * test_options: one expanded JSON option object
#   * seed: repetition-specific random seed
# - Desc:
#   Samples one coefficient vector and one noise vector per repetition.
#   Uses SNR = Var(f(x_i)) / sigma^2, hence sigma = sqrt(Var(f(x_i)) / SNR).
#   SRPDE-FEM and SRPDE-SPLINES receive the same object within each repetition.
generate_smoothing_data <- function(test_options, seed) {
  ## Sample the repetition-specific truth around the reference coefficients
  set.seed(seed)
  coefficients <- rnorm(
    length(test_options$data$coefficient_mean),
    mean = test_options$data$coefficient_mean,
    sd = test_options$data$coefficient_sd
  )

  ## Observation locations and sampled truth
  n_locs <- test_options$dimensions$n_locs
  locations <- seq(0, 1, length.out = n_locs)
  truth_observed <- truth_function(locations, coefficients)

  ## Gaussian noise calibrated to the requested signal-to-noise ratio
  signal_variance <- mean((truth_observed - mean(truth_observed))^2)
  noise_sigma <- sqrt(signal_variance / test_options$noise$SNR)
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
    truth_evaluation = truth_function(evaluation, coefficients),
    coefficients = coefficients,
    signal_variance = signal_variance,
    noise_sigma = noise_sigma,
    seed = seed
  )
}

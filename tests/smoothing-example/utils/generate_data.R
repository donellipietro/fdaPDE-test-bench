truth_function <- function(x) {
  sin(2 * pi * x) + 0.5 * sin(4 * pi * x) + 0.25 * sin(8 * pi * x)
}

generate_smoothing_data <- function(test_options, seed) {
  n_locs <- test_options$dimensions$n_locs
  locations <- seq(0, 1, length.out = n_locs)
  truth_observed <- truth_function(locations)
  signal_variance <- mean((truth_observed - mean(truth_observed))^2)
  noise_sigma <- sqrt(signal_variance / test_options$dimensions$snr)

  set.seed(seed)
  response <- truth_observed + rnorm(n_locs, sd = noise_sigma)
  evaluation <- seq(0, 1, length.out = test_options$dimensions$evaluation_points)

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

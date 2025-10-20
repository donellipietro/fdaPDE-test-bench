source("src/data-generation/2D_functions.R")

## data generator ----
generate_2D_fpca_data <- function(domain, 
                             test_options,
                             loadings_true_generator = NULL, 
                             mean_generator = NULL,
                             seed = 0,
                             VERBOSE = FALSE) {
  if (is.null(loadings_true_generator)) {
    loadings_true_generator <- cube_eigenfunction
  }
  if (is.null(mean_generator)) {
    mean_generator <- log_mean_generator
  }
  ## dimensions
  n_stat_units <- test_options$dimensions$n_stat_units
  n_comp <- test_options$dimensions$n_comp
  
  nodes <- domain$fdapde_mesh$nodes
  n_nodes <- nrow(nodes)
  ## locations -----
  locs <- generate_locations(domain, n_locs = test_options$dimensions$n_locs, 
                                  locs_eq_nodes=test_options$data$locs_eq_nodes)
  n_locs <- nrow(locs)
  
  ## nodes
  
  
  ## femR objects to compute functional norm
  Vh <- FunctionSpace(domain$femr_mesh, fe_order=1)
  u <- Function(Vh)
  Lu <- -laplace(u) ## poisson problem
  pde <- Pde(Lu, function(points) { return(0*points[,1])})
  ## fPCs----
  loadings_true <- matrix(0, nrow = n_nodes, ncol = n_comp)
  loadings_true_locs <- matrix(0, nrow = n_locs, ncol = n_comp)
  for (i in 1:n_comp) {
    loadings_true[, i] <- loadings_true_generator(nodes, i)
    norm <- norm_L2(loadings_true[, i], pde$mass())
    loadings_true[, i] <- loadings_true[, i] / norm
    loadings_true_locs[, i] <- loadings_true_generator(locs, i) / norm
  }
  ## scores sampling----
  data_range <- max(loadings_true) - min(loadings_true)
  
  sd_s <- 1/1:n_comp
  sd_s <- sd_s/sum(sd_s)
  sigma_s <- sd_s * data_range

  set.seed(seed)
  ## scores
  scores_true <- matrix(nrow=n_stat_units, ncol=n_comp)
  for(i in 1:n_comp){
    scores_true[,i] <- rnorm(n = n_stat_units, sd = sigma_s[i])
  }
  scores_true <- scale(scores_true, scale = F)
  ## generating X----
  X_c_true <- scores_true %*% t(loadings_true)
  X_c_true_locs <- scores_true %*% t(loadings_true_locs)
  
  ## generating the mean function
  X_mean_true <- mean_generator(nodes)
  X_mean_true_locs <- mean_generator(locs)
  
  ## adding the mean
  X_true <- X_c_true + rep(1, n_stat_units) %*% t(X_mean_true)
  X_true_locs <- X_c_true_locs + rep(1, n_stat_units) %*% t(X_mean_true_locs)
  
  ## noise----
  ## computing the noise sd from the variance of the signal and the NSR
  NSR <- test_options$noise$NSR
  sigma_noise_x <- sqrt(NSR * sum(sigma_s^2))
  NSR_X <- NSR
  ## compute the noisy data matrix
  EE <- rnorm(n = n_stat_units*n_locs, sd = sigma_noise_x)
  EE <- matrix(EE, nrow=n_stat_units)
  EE <- scale(EE, scale = F) # center the matrix
  ## specific noise on the first component
  if(!is.null(test_options$noise$fPC1_specific_noise) && test_options$noise$fPC1_specific_noise){
    #multiply the rows the noise matrix by the corresponding element in the first score vector
    EE <- outer(scores_true[,1],rnorm(n_locs,mean = 0, sd = sigma_noise_x))
    EE <- scale(EE, scale = F)
    # EE <- zeros(n_stat_units,n_locs)
    # for(i in 1:n_comp){
    #   tmp <- outer(scores_true[,i],rnorm(n_locs,mean = 0, sd = sigma_noise_x))
    #   tmp <- scale(tmp, scale = F)
    #   EE <- EE + tmp
    # }
  }
  ## heteroschedastic noise
  if(!is.null(test_options$noise$heteroschedastic) && test_options$noise$heteroschedastic){
    generate_specific_noise <- function(scores, n_locs, error_sd_specific) {
      # Heteroskedastic iid noise, varies per subject and time point
      t(
        mvrnorm(n_locs, mu = rep(0, nrow(scores)),
                Sigma = error_sd_specific^2 * diag(scores[,1]^2),
                empirical = TRUE)
      )
    }
    EE <- generate_specific_noise(scores_true,n_locs, sigma_noise_x)
    EE <- scale(EE, scale = F)
  }
  ## final matrix ----
  X_locs <- X_true_locs + EE
  
  return(list(
    ## dimensions
    dimensions = list(
      n_stat_units = n_stat_units,
      n_comp = n_comp,
      n_nodes = n_nodes,
      n_locs = n_locs
    ),
    locations = locs,
    ## data
    X = X_locs,
    ## expected results: reconstruction
    X_mean_true = X_mean_true,
    X_mean_true_locs = X_mean_true_locs,
    X_c_true = X_c_true,
    X_c_true_locs = X_c_true_locs,
    X_true = X_true,
    X_true_locs = X_true_locs,
    ## expected results: decomposition
    loadings_true = loadings_true,
    loadings_true_locs = loadings_true_locs,
    scores_true = scores_true,
    ## computed
    sd_s = sd_s,
    sigma_s = sigma_s,
    sigma_noise_x = sigma_noise_x,
    NSR_X = NSR_X
  ))
}



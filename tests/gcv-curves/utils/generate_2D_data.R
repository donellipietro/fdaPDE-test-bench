## loadings_true generator
cube_eigenfunction <- function(locs, i) {
  n <- c(1 * pi, 1 * pi, 4 * pi)[i]
  m <- c(1 * pi, 3 * pi, 2 * pi)[i]
  return(cos(n * locs[, 1]) * cos(m * locs[, 2]))
}
c_shape_domain_loadings <- function(locs, i) {
  if (i == 1L) {
    f <- exp(-0.5 * ((locs[, 1] - 2.5)^2 + (locs[, 2] + 0.5)^2)) * (locs[, 1] > 0) * (locs[, 2] < 0)
  } else if (i == 2L) {
    f <- exp(-((locs[, 1] - 1.5)^2 + (locs[, 2])^2)) * (locs[, 1] > 0) * (locs[, 2] > 0)
  } else if (i == 3L) {
    f <- exp(-8 * ((locs[, 1] + 0.5)^2 + 1 / 2 * (locs[, 2])^2)) * (locs[, 1] < 0)
  }
  return(f)
}
## eigenfunctions of the laplacian operator with neumann bdd conditions
translated_laplacian_eigenfunction <- function(locs, i, x_t=0, y_t=0) {
  n <- c(1 * pi, 2 * pi, 3 * pi)[i]
  m <- c(1 * pi, 2 * pi, 3 * pi)[i]
  return(cos(n * (locs[,1]-x_t)) * cos(m * (locs[, 2]-y_t)))
}
## mean generator
log_mean_generator <- function(locs) {
  ## I want a function between -1 and 1
  return((2 * log((locs[, 1] + locs[, 2]) + 1) / log(3) - 1))
}

sin_mean_generator <- function(locs) {
  ## I want a function between -1 and 1
  return(sin(4 * pi * locs[, 1]) * sin(4 * pi * locs[, 2]) * exp(-8*((locs[, 1]-0.5)^2 + (locs[, 2]-0.5)^2)))
}

generate_2D_data <- function(domain, locs = NULL,
                             loadings_true_generator = NULL, mean_generator = NULL,
                             n_stat_units = 50,
                             n_comp = 3,
                             NSR = 0.5,
                             specific_noise = FALSE,
                             seed = 0,
                             VERBOSE = FALSE) {
  ## set defaults
  if (is.null(locs)) {
    locs <- domain$nodes()
  }
  if (is.null(loadings_true_generator)) {
    loadings_true_generator <- cube_eigenfunction
  }
  if (is.null(mean_generator)) {
    mean_generator <- log_mean_generator
  }
  
  ## nodes
  nodes <- domain$nodes()

  ## dimensions
  n_nodes <- nrow(nodes)
  n_locs <- nrow(locs)
  
  ## building femR objects

  ## pde
  Vh <- FunctionSpace(domain, fe_order=1)
  u <- Function(Vh)
  Lu <- -laplace(u) ## poisson problem
  f <- function(points) { return(0*points[,1])}
  pde <- Pde(Lu, f)

  ## generating the loadings functions
  loadings_true <- matrix(0, nrow = n_nodes, ncol = n_comp)
  loadings_true_locs <- matrix(0, nrow = n_locs, ncol = n_comp)
  for (i in 1:n_comp) {
    loadings_true[, i] <- loadings_true_generator(nodes, i)
    norm <- norm_L2(loadings_true[, i], pde$mass())
    loadings_true[, i] <- loadings_true[, i] / norm
    loadings_true_locs[, i] <- loadings_true_generator(locs, i) / norm
  }

  ## computing the scores sd. (sigma)
  ## sd = sqrt(Var[score*loading]) = sqrt(Var[score] * semi_range(loading)^2) = sqrt(Var[score]) * semi_range(loading)
  ## sigma = sqrt(Var[score])
  ## => sigma = sd / semi_range(loading)
  data_range <- max(loadings_true) - min(loadings_true)
  
  sd_s <- seq(0.4,0.2,length=n_comp)
  #semi_range_loadings_true <- 0.5 * (apply(loadings_true, 2, max) - apply(loadings_true, 2, min))
  sigma_s <- sd_s * data_range

	## computing the noise sd. (sigma_noise)
	## NSR_last_comp = Var[noise]/Var[3rd comp.]
	## Var[3rd comp.] = Var[score_3 * loadings_3] = sd_s_3^2
	## => Var[noise] = NSR_last_comp * Var[3rd comp.] = NSR_last_comp * sd_s_3^2
  sigma_noise_x <- sqrt(NSR * sum(sigma_s^2))
  NSR_X <- NSR

  ## sampling
  set.seed(seed)
  #Sampled <- mvrnorm(n_stat_units, mu = rep(0, n_comp + n_locs), diag(c(sigma_s^2, rep(sigma_noise_x^2, n_locs))))
  
  ## scores
  scores_true <- matrix(nrow=n_stat_units, ncol=n_comp)
  for(i in 1:n_comp){
    scores_true[,i] <- rnorm(n = n_stat_units, sd = sigma_s[i] * data_range)
  }
  scores_true <- scale(scores_true, scale = F)
  #compute the noisy data matrix
  EE <- rnorm(n = n_stat_units*n_locs, sd = sigma_noise_x*data_range)
  EE <- matrix(EE, nrow=n_stat_units)
  EE <- scale(EE, scale = F)

  #EE <- scale(as.matrix(Sampled[, (n_comp + 1):(n_comp + n_locs)], ncol = n_locs), scale=FALSE)
  
  if(specific_noise){
    #multiply the rows the noise matrix by the corresponding element in the first score vector
    EE <- outer(scores_true[,1],rnorm(n_locs,mean = 0, sd = sigma_noise_x))
    EE <- scale(EE, scale = F)
    #EE <- sweep(EE,1,scores_true[,1],"*")
  }
  ## generating X:
  X_c_true <- scores_true %*% t(loadings_true)
  X_c_true_locs <- scores_true %*% t(loadings_true_locs)

  ## generating the mean function
  X_mean_true <- mean_generator(nodes)
  X_mean_true_locs <- mean_generator(locs)

  ## adding the mean
  X_true <- X_c_true + rep(1, n_stat_units) %*% t(X_mean_true)
  X_true_locs <- X_c_true_locs + rep(1, n_stat_units) %*% t(X_mean_true_locs)

  ## adding the noise and the mean:
  X_locs <- X_true_locs + EE

  return(list(
    ## dimensions
    dimensions = list(
      n_stat_units = n_stat_units,
      n_comp = n_comp,
      n_nodes = n_nodes,
      n_locs = n_locs
    ),
    ## data
    X = X_locs,
    ## function space
    functional_space = Vh, #-> to map the nodes to arbitrary locations
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
    NSR = NSR_X
  ))
}

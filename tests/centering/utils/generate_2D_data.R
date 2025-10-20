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
translate_laplacian_eigenfunction <- function(locs,a=1,b=1,x_t=0,y_t=0) {
  return(cos(a * pi * (locs[,1]-x_t)) * cos(b * pi * (locs[, 2]-y_t)))
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

# data generators----
## utilities to generate partially observed data----
library(RANN)

# optimized distance function
dep_space.NA_fast <- function(data_matrix, 
                              p = 0.5,
                              mesh_nodes = NULL, 
                              locations = NULL, 
                              RDD_groups = NULL) {

  vectorized_data <- as.vector(data_matrix)
  size <- length(vectorized_data)
  
  nobs <- ceiling(RDD_groups * p)
  pts <- locations
  
  # Use precomputed seeds if possible
  seeds <- mesh_nodes[sample(nrow(mesh_nodes), RDD_groups), , drop = FALSE]
  obs_marker <- rep(0, RDD_groups)
  obs_marker[sample(RDD_groups, nobs)] <- 1
  
  # Fast nearest neighbor search using RANN
  nn_results <- nn2(seeds, pts, k = 1)  # Finds nearest seed for each location
  nearest_idxs <- nn_results$nn.idx  # Index of the nearest seed
  
  # Vectorized NA assignment
  vectorized_data[obs_marker[nearest_idxs] == 0] <- NA
  
  data_matrix <- matrix(data = vectorized_data, nrow = 1, ncol = size)
  data_matrix
}

## data generator----
generate_2D_data <- function(domain, locs = NULL,
                            mean_generator = NULL,
                            n_stat_units = 50,
                            NSR = 0.5,
                            only_mean = F,
                            fully_obs = F,
                            seed = 0,
                            VERBOSE = FALSE) {
  ## set defaults
  if (is.null(locs)) {
    locs <- domain$nodes
  }
  if (is.null(mean_generator)) {
    mean_generator <- function(locs) { translate_laplacian_eigenfunction(locs,1,1,0.2,0.2)}
  }
  
  ## nodes
  nodes <- domain$nodes()

  ## dimensions
  n_nodes <- nrow(nodes)
  n_locs <- nrow(locs)
  
  ## generating X:
  X_mean_true <- mean_generator(nodes)
  X_mean_true_locs <- mean_generator(locs)
  
  ## adding the mean
  X_true <- rep(1, n_stat_units) %*% t(X_mean_true)
  X_true_locs <- rep(1, n_stat_units) %*% t(X_mean_true_locs)
  
  ## computing the noise sd. (sigma_noise)
  ## NSR = Var[noise]/Var[mean_field]
  ## Var[mean_field] = ...
  ## => Var[noise] = NSR * Var[mean_field] = ...
  # sigma_noise_x <- sqrt(NSR * mean(X_mean_true_locs^2))

  ## sampling
  set.seed(seed)
  # Sampled <- mvrnorm(n_stat_units, mu = rep(0, n_locs), diag(rep(sigma_noise_x^2, n_locs)))
  # EE <- scale(as.matrix(Sampled, ncol = n_locs), scale=FALSE)
  # 
  # ## adding the noise and the mean:
  # X_locs <- X_true_locs + EE
  
  ## now let's try to add another zero-mean matrix but with a different structure
  rank <- 3
  pcs <- matrix(nrow=nrow(locs), ncol=rank)
  pcs[,1] <- translate_laplacian_eigenfunction(locs,a=1,b=2,x_t=0.2,y_t=0.2)
  pcs[,2] <- translate_laplacian_eigenfunction(locs,a=2,b=3,x_t=0.2,y_t=0.2)
  pcs[,3] <- translate_laplacian_eigenfunction(locs,a=4,b=4,x_t=0.2,y_t=0.2)
  data_range <- max(pcs) - min(pcs)
  ## computing the scores sd. (sigma)
  ## sd = sqrt(Var[score*loading]) = sqrt(Var[score] * semi_range(loading)^2) = sqrt(Var[score]) * semi_range(loading)
  ## sigma = sqrt(Var[score])
  ## => sigma = sd / semi_range(loading)
  sd_s <- 4*exp(seq(0, log(0.25), length = rank))
  semi_range_loadings_true <- 0.5 * (apply(pcs, 2, max) - apply(pcs, 2, min))
  scores_sd <- sd_s / semi_range_loadings_true
  
  sigma_noise_x <- sqrt(NSR * min(sd_s^2))
  NSR_X <- NSR *  min(sd_s^2) / sum(sd_s^2)
  
  ## Simultaneously sampling scores and errors
  sampled_values <- mvrnorm(n_stat_units, mu = rep(0, rank + n_locs), diag(c(scores_sd^2, rep(sigma_noise_x^2, n_locs))))
  scores <- scale(as.matrix(sampled_values[, 1:rank], ncol = rank), scale=FALSE)
  EE <- scale(as.matrix(sampled_values[, (rank + 1):(rank + n_locs)], ncol = n_locs), scale=FALSE)
  
  ## Assembling the data matrix
  if(!only_mean){
    X_locs <- X_true_locs + scores %*% t(pcs) + EE
  }else{
    X_locs <- X_true_locs + EE 
  }
  
  # removed data 
  if(!fully_obs){
    X_locs_partial <- 
      t(apply(X_locs, 1,
              dep_space.NA_fast,
              p=0.5,
              mesh_nodes=nodes,
              locations=locs,
              RDD_groups=12))
  }
  X_locs_partial <- 
    t(apply(X_locs, 1,
          dep_space.NA_fast,
          p=0.5,
          mesh_nodes=nodes,
          locations=locs,
          RDD_groups=12))
	
  if (VERBOSE) {
    cat("\n\n# Computing the noise sd. (sigma_noise)")
    cat("\nNSR = Var[noise]/Var[mean_field]")
    cat("\nVar[mean_field] = ...")
    cat("\n=> Var[noise] = NSR * Var[mean_field] = ...")
    cat("\n=> sigma_noise = sqrt(Var[noise]) = ...")
    cat("\n")
    cat(paste("\n- Desired Noise to Signal Ratio:", NSR))
    cat(paste("\n- Effective noise sd:", sigma_noise_x))
    cat("\n")
  }

  return(list(
    ## dimensions
    dimensions = list(
      n_stat_units = n_stat_units,
      n_nodes = n_nodes,
      n_locs = n_locs),
    ## data
    X = X_locs,
    X_partial = X_locs_partial,
    ## expected results: reconstruction
    X_mean_true = X_mean_true,
    X_mean_true_locs = X_mean_true_locs,
    ## computed
    sigma_noise_x = sigma_noise_x
  ))
}




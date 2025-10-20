# Orthogonal functions ----
## eigenfunctions of the laplacian operator with neumann bdd conditions
## cosine -> neumann bdd conditions
## orthogonal on the unit interval [0,1]
laplacian_eigenfunction_1D <- function(locs, i, x_t=0, param_grid=NULL) {
  if(is.null(param_grid)){
    n <- i
  }else{
    n <- param_grid[i]
  }
  return(sqrt(2)*cos(n*pi*(locs-x_t)))
}

# Mean functions
## log mean
log_mean_generator_1D <- function(locs) {
  ## I want a function between -1 and 1
  return((2 * log((locs) + 1) / log(3) - 1))
}
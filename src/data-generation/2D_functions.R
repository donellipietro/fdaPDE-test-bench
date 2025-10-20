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
## orthogonal on the unit square
translated_laplacian_eigenfunction <- function(locs, i, x_t=0, y_t=0,ab_grid=NULL) {
  if(is.null(ab_grid)){
    n <- pi*i
    m <- pi*i
  }else{
    n <- pi*ab_grid[i,1]
    m <- pi*ab_grid[i,2] 
  }
  return(cos(n * (locs[,1]-x_t)) * cos(m * (locs[, 2]-y_t)))
}

## anisothropic diffusion operator
anis_diff_op_2D <- function(alpha, gamma){
  R <- matrix(
    c(cos(alpha),-sin(alpha),
      sin(alpha),cos(alpha)),
    nrow=2, ncol=2
  )
  Sigma <- matrix(
    c(1/sqrt(gamma),0,
      0,sqrt(gamma)),
    nrow=2, ncol=2
  )
  #define K
  K <- R %*% Sigma %*% t(R)
  
  return(
    function(f){ 
      return(femR::div(K*femR::grad(f)))
    }
  )
}

## eigenfunctions of a generic linear operator
#' - pde params: e.g. angle and intensity for the anisotropic diffusion
#' - the linear operator defined using femR
#' - femR mesh: we need it to define the FE space on top of it
#' - locations where to evaluate the fPCs
#' - index of the fPC
#' - forcing term of the pde
eigenfunctions.Lop <- function(locs,fpc_indexes,femr_mesh,L,f){
  #define the pde associated to the linear op, L
  Vh <- FunctionSpace(femr_mesh, fe_order=1)
  u <- Function(Vh)
  pde <- Pde(L(u),f)
  #functional norm 
  L2norm <- function(g){ return(sqrt(as.numeric(t(g) %*% pde$mass() %*% g)))} 
  #compute the eigenfunctions of the linear operator
  evd <- eigen(pde$stiff(), symmetric = T, only.values = F)
  #normalize and evaluate at locations
  f_fem <- evd$vectors[,fpc_indexes]
  f_locs <- apply(f_fem ,MARGIN = 2, function(f){
    as.matrix(Vh$basis()$eval(as.matrix(locs)) %*% f/L2norm(f))
  })
  return(f_locs)
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
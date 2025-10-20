source("src/data-generation/2D_functions.R")

sapply(list.files("src/utils", pattern = "\\.R$", full.names = TRUE), source)

invisible(suppressMessages(
  sapply(c(
    "fdaPDE","femR", #discretisation
    "pracma", #algebraic utils
    "MASS","tidyr","dplyr", #data manipulation
    "ggplot2","viridis","stringr","RColorBrewer","grid","gridExtra", #visualisation
    "jsonlite", #json
    "sf","sp","raster" #sampling
  ), require, character.only = TRUE)))

## load domain
generated_domain <- generate_domain("unit_square", 
                                    1000)

## femR objects to compute functional norm
Vh <- FunctionSpace(generated_domain$femr_mesh, fe_order=1)
u <- Function(Vh)
Lu <- -laplace(u) ## poisson problem
pde <- Pde(Lu, function(points) { return(0*points[,1])})

funct_prod <- function(f1,f2){
  t(f1) %*% pde$mass() %*% f2
}

## loadings generator
loadings_true_generator <- function(locs,i) { 
  translated_laplacian_eigenfunction(locs,i,x_t=0.2,y_t=0.0)
}
load1 <- loadings_true_generator(generated_domain$femr_mesh$nodes(),1) 
load1 <- load1/as.numeric(sqrt(funct_prod(load1,load1)))
load2 <- loadings_true_generator(generated_domain$femr_mesh$nodes(),2) 
load2 <- load2/as.numeric(sqrt(funct_prod(load2,load2)))
load3 <- loadings_true_generator(generated_domain$femr_mesh$nodes(),3) 
load3 <- load3/as.numeric(sqrt(funct_prod(load3,load3)))

t(cbind(load1,load2,load3)) %*% pde$mass() %*% cbind(load1,load2,load3)
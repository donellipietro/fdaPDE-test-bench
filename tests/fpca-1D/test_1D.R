# % %%%%%%%%%%%%%% %
# % % Test: fPCA % %
# % %%%%%%%%%%%%%% %

#' TODO:
#' -

rm(list = ls())
graphics.off()

# sources ----
invisible(suppressMessages(
  sapply(c(
    "fdaPDE","femR", #discretisation
    "pracma", #algebraic utils
    "MASS","tidyr","dplyr", #data manipulation
    "ggplot2","viridis","stringr","RColorBrewer","grid","gridExtra", #visualisation
    "jsonlite", #json
    "sf","sp","raster" #sampling
  ), require, character.only = TRUE)))

## general functions
sapply(list.files("src/utils", pattern = "\\.R$", full.names = TRUE), source)
source("src/data-generation/generate_1D_fpca_data.R")


## load domain
generated_domain <- generate_domain("unit_interval",101)

## loadings generator
loadings_true_generator <- function(locs,i) { 
  laplacian_eigenfunction_1D(locs,i,x_t=0)
}

locs <- generate_locations(generated_domain, 100)[,1]


plot(generated_domain$domain_boundary)
points(generate_locations(generated_domain, 100), col="green")

x_t <- 0.1
f <- function(x) sqrt(2)*cos(1*pi*(x-x_t))
g <- function(x) sqrt(2)*cos(2*pi*(x-x_t))

integrate(function(x) f(x) * g(x),
          lower = 0, upper = 1)


## data
test_options <- list(
  dimensions = list(
    n_knots = 100,
    n_locs = 400,
    n_stat_units = 100,
    n_comp = 3,
    n_reps = 10,
    n_nodes_HR_grid = 1000
  ),
  data = list(
    mean = F,
    locs_eq_nodes = F
  ),
  noise = list(
    NSR = 10,
    seed = 1412,
    fPC1_specific_noise = F
  )
)


generated_data <- generate_1D_fpca_data(
  domain = generated_domain,
  test_options = test_options,
  loadings_true_generator = loadings_true_generator,
  mean_generator = function(locs) { return(locs*0) },
  seed = 1412
)

cpp_scripts_path <- "cpp-scripts/"
fpca_1D_path <- "cpp-scripts/fpca-1D/"
data_path <- "cpp-scripts/data"
mesh_path <- "cpp-scripts/mesh"

## write data for cpp-scripts----
## data matrix, locations
write.csv(format(generated_data$X,digits=16), 
          file = paste(data_path,"/y.csv",sep=""))
write.csv(format(generated_data$locations,digits=16), 
          file = paste(data_path,"/locs.csv",sep=""))
## mesh
write.csv(format(generated_domain$knots, digits = 16), paste(mesh_path,"/knots.csv", sep = ""))

cpp_params_json <- fromJSON(paste(fpca_1D_path, "params.json", sep = ""))
cpp_params_json$RunParams$lambda_grid <- I(1e0)#10^seq(0,0,by=1)
cpp_params_json$RunParams$fpca_solver <- "sequential"
write_json(path = paste(fpca_1D_path, "params.json", sep = ""), 
           cpp_params_json, auto_unbox=T, pretty=T, digits=10
)

system("cd cpp-scripts/fpca-1D; ./fpca_1D")
loadings_locs_hat_seq <- read.csv("cpp-scripts/fpca-1D/test-results/loadings_locs.csv")
scores_seq <- as.matrix(read.csv("cpp-scripts/fpca-1D/test-results/scores.csv"))
scores_norms <- apply(scores_seq,2,function(x){ sqrt(sum(x^2))})
scores_seq <- sweep(scores_seq,2,scores_norms,FUN="/")


cpp_params_json$RunParams$fpca_solver <- "subspace"
write_json(path = paste(fpca_1D_path, "params.json", sep = ""), 
           cpp_params_json, auto_unbox=T, pretty=T, digits=10
)
system("cd cpp-scripts/fpca-1D; ./fpca_1D")
loadings_locs_hat_sub <- read.csv("cpp-scripts/fpca-1D/test-results/loadings_locs.csv")
scores_sub <- as.matrix(read.csv("cpp-scripts/fpca-1D/test-results/scores.csv"))
scores_norms <- apply(scores_sub,2,function(x){ sqrt(sum(x^2))})
scores_sub <- sweep(scores_sub,2,scores_norms,FUN="/")


par(mfrow = c(2,1), mar=c(1,1,1,1))
image(t(scores_seq)%*%scores_seq)
image(t(scores_sub) %*% scores_sub)

par(mfrow = c(3,1), mar=c(1,1,1,1))
plot(generated_data$locations, generated_data$loadings_true_locs[,1])
lines(generated_data$locations, loadings_locs_hat_seq$V0, col="red")
lines(generated_data$locations, loadings_locs_hat_sub$V0, col="green")

plot(generated_data$locations, generated_data$loadings_true_locs[,2])
lines(generated_data$locations, loadings_locs_hat_seq$V1, col="red", lwd=2)
lines(generated_data$locations, loadings_locs_hat_sub$V1, col="green")

plot(generated_data$locations, generated_data$loadings_true_locs[,3])
lines(generated_data$locations, loadings_locs_hat_seq$V2, col ="red")
lines(generated_data$locations, loadings_locs_hat_sub$V2, col="green")





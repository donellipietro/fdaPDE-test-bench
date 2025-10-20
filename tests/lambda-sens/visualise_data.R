# % %%%%%%%%%%%%%% %
# % % Test: fPCA % %
# % %%%%%%%%%%%%%% %

rm(list = ls())
graphics.off()

## global variables ----
test_suite <- "lambda-sensibility"
TEST_SUITE <- "lambda-sensibility"

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


## test specific functions
source(paste("tests/", test_suite, "/utils/models_evaluation.R", sep = ""))
source(paste("tests/", test_suite, "/utils/generate_options.R", sep = ""))
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

## test ----
cat.section_title("Test")

## load domain
name_mesh <- "unit_square"
n_nodes <- 625

generated_domain <- generate_domain(name_mesh, n_nodes)
domain <- generated_domain$domain
domain_boundary <- generated_domain$domain_boundary
mesh <- generated_domain$mesh

## locations
n_locs <- 1000
locs_eq_nodes <- F
locations <- generate_locations(generated_domain, n_locs = n_locs, locs_eq_nodes=locs_eq_nodes)

## grid
n_nodes_HR_grid <- 1000
grid <- spsample(domain_boundary, n_nodes_HR_grid, "regular")@coords

## loadings generator
loadings_true_generator <- function(locs,i) { 
  translated_laplacian_eigenfunction(locs,i,x_t=0,y_t=0.2)
}


## data generation----
n_stat_units <- 50
n_comp <- 3
NSR <- 1
mean <- F

generated_data <- generate_2D_data(
  domain = domain,
  locs = locations,
  n_stat_units = n_stat_units,
  n_comp = n_comp,
  seed = 0,
  NSR = NSR,
  loadings_true_generator = loadings_true_generator,
  mean_generator = ifelse(F, log_mean_generator, function(locs) { return(locs[,1]*0) }),
  fpc_specific_noise = F
)

plot_list <- 
  lapply(sample(1:n_stat_units,size = 9), 
       function(unit_idx){
         plot.field_points(locations, generated_data$X[unit_idx,], 
                           size = 2, boundary = domain_boundary) +
           standard_plot_settings_fields()
       })
plots <- arrangeGrob(grobs = plot_list, nrow = 3)
grid.arrange(plots)



## visualisation----
## pde: needed to normalise the fPCs
Vh <- FunctionSpace(domain, fe_order=1)
u <- Function(Vh)
Lu <- -laplace(u) ## poisson problem
f <- function(points) { return(0*points[,1])}
pde <- Pde(Lu, f)


## loadings generator
source("src/data-generation/generate_2D_fpca_data.R")

ab_grid <- matrix(c(1,1,
                    2,2,
                    3,1),
                  ncol = 2, byrow = T)

loadings_true_generator <- function(locs,i) { 
  translated_laplacian_eigenfunction(locs,i,x_t=0,y_t=0, ab_grid = ab_grid)
}

## generating & normalising the fPCs
n_comp <- nrow(ab_grid)


loadings_true <- matrix(0, nrow = nrow(domain$nodes()), ncol = n_comp)
loadings_true_locs <- matrix(0, nrow = nrow(locations), ncol = n_comp)
loadings_true_HR <- matrix(0, nrow = nrow(grid), ncol = n_comp)
for (m in 1:n_comp) {
  loadings_true[, m] <- loadings_true_generator(domain$nodes(), m)
  norm <- norm_L2(loadings_true[, m], pde$mass())
  loadings_true[, m] <- loadings_true[, m] / norm
  loadings_true_locs[, m] <- loadings_true_generator(locations, m) / norm
  loadings_true_HR[,m] <- loadings_true_generator(grid, m) / norm
}

plot_list <- 
  lapply(1:n_comp, 
         function(unit_idx){
           plot.field_tile(grid, loadings_true_HR[,unit_idx], boundary = domain_boundary) +
             standard_plot_settings_fields()
         })
plots <- arrangeGrob(grobs = plot_list, nrow = 3)
grid.arrange(plots)


## remove options file
file.remove(paste(path_queue, file_options, sep = ""))

cat("\n\n")

if(!RSTUDIO){
  sink()
}

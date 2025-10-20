## general functions
source("src/utils/cat.R")
source("src/utils/directories.R")
source("src/utils/meshes.R")
source("src/utils/domain_and_locations.R")
source("src/utils/wrappers.R")
source("src/utils/errors.R")
source("src/utils/results_management.R")
source("src/utils/plots.R")

invisible(suppressMessages(
  sapply(c(
    "fdaPDE","femR", #discretisation
    "pracma", #algebraic utils
    "MASS","tidyr","dplyr", #data manipulation
    "ggplot2","viridis","stringr","RColorBrewer","grid","gridExtra", #visualisation
    "jsonlite", #json
    "sf","sp","raster" #sampling
  ), require, character.only = TRUE)))

## test specific functions
path_images <- paste("images/", test_suite, "/", sep = "")

## Options ----
n_nodes <- 1000
n_locs <- 625
n_stat_units <- 50
n_comp <- 3

## Mesh & test functions ----
generated_domain <- generate_domain("unit_square", n_nodes)
domain <- generated_domain$femr_mesh
domain_boundary <- generated_domain$domain_boundary
mesh <- generated_domain$fdapde_mesh

## locations
locations <- generate_locations(generated_domain, n_locs = n_locs, locs_eq_nodes=(n_locs==n_nodes))

## grid
n_nodes_HR_grid <- 1000
HR_grid <- spsample(domain_boundary, n_nodes_HR_grid, "regular")@coords

## loadings generator
loadings_true_generator <- function(locs,i) { 
  translated_laplacian_eigenfunction(locs,i,x_t=0.2,y_t=0.0)
}

test_options <- list(
  dimensions = list(
    n_stat_units = n_stat_units,
    n_locs = n_locs,
    n_nodes = n_nodes,
    n_comp = 3
  ),
  data = list(locs_eq_nodes=F),
  noise = list(
    NSR = 10
  )
)

## Generate data ----
source("src/data-generation/generate_2D_fpca_data.R")

generated_data <- generate_2D_fpca_data(
  domain = generated_domain,
  test_options = test_options,
  loadings_true_generator = loadings_true_generator,
  mean_generator = ifelse(F, log_mean_generator, function(locs) { return(locs[,1]*0) }),
  seed = 1412
)

generated_data$scores_true[1,]

plot.field_points(generated_data$locations,generated_data$X[which.max(generated_data$scores_true[,1]),], size=2)



## Visualization ----
loads_HR <- evaluate_field(HR_grid,generated_data$loadings_true, mesh)

plot_list <- 
  lapply(1:n_comp,
         function(fpc_idx){
           plot.field_tile(
             HR_grid,
             loads_HR[,fpc_idx],
             limits = range(loads_HR),
             ISOLINES = T) + 
             standard_plot_settings_fields()
         })

library(patchwork)
final_plot <- plot_list[[1]]
for (k in 2:length(plot_list)) {
  final_plot <- final_plot + plot_list[[k]]
}
final_plot <- final_plot + plot_layout(guides = "collect", nrow = 1) 


pdf(file = paste(path_images, "test_functions.pdf", sep = ""),width = 14, height = 7)
final_plot
dev.off()


# for(fpc_idx in 1:n_comp){
#   ggsave(filename = paste(path_images,"fpc",fpc_idx,".png",sep=""),
#          plot = plot_list[[fpc_idx]])
# }

## general functions
source("src/utils/cat.R")
source("src/utils/directories.R")
source("src/utils/meshes.R")
source("src/utils/domain_and_locations.R")
source("src/utils/wrappers.R")
source("src/utils/errors.R")
source("src/utils/results_management.R")
source("src/utils/plots.R")

test_suite <- "lambda-sensibility"
TEST_SUITE <- "lambda-sensibility"

## test specific functions
source(paste("tests/", test_suite, "/utils/generate_2D_data.R", sep = ""))
source(paste("tests/", test_suite, "/utils/models_evaluation.R", sep = ""))

path_images <- paste("images/", test_suite, "/", sep = "")

## Options ----
n_nodes <- 400
n_locs <- 625
n_stat_units <- 50
n_comp <- 3

## Mesh & test functions ----
generated_domain <- generate_domain("unit_square", n_nodes)
domain <- generated_domain$domain
domain_boundary <- generated_domain$domain_boundary
mesh <- generated_domain$mesh

## locations
locations <- generate_locations(generated_domain, n_locs = n_locs, locs_eq_nodes=(n_locs==n_nodes))

## grid
n_nodes_HR_grid <- 1000
HR_grid <- spsample(domain_boundary, n_nodes_HR_grid, "regular")@coords

## loadings generator
loadings_true_generator <- function(locs,i) { 
  translated_laplacian_eigenfunction(locs,i,x_t=0.2,y_t=0.2)
}

## Generate data ----
generated_data <- generate_2D_data(
  domain = domain,
  locs = locations,
  n_stat_units = n_stat_units,
  n_comp = n_comp,
  seed = 0,
  NSR = 0.1,
  loadings_true_generator = loadings_true_generator,
  mean_generator = log_mean_generator
)

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


#png(file = paste(path_images, "test_functions.png", sep = ""),width = 14, height = 7)
final_plot
#dev.off()


# for(fpc_idx in 1:n_comp){
#   ggsave(filename = paste(path_images,"fpc",fpc_idx,".png",sep=""),
#          plot = plot_list[[fpc_idx]])
# }

## general functions
source("src/utils/cat.R")
source("src/utils/directories.R")
source("src/utils/meshes.R")
source("src/utils/domain_and_locations.R")
source("src/utils/wrappers.R")
source("src/utils/errors.R")
source("src/utils/results_management.R")
source("src/utils/plots.R")

test_suite <- "centering"
TEST_SUITE <- "centering"

## test specific functions
source(paste("tests/", test_suite, "/utils/generate_2D_data.R", sep = ""))
source(paste("tests/", test_suite, "/utils/models_evaluation.R", sep = ""))

path_images <- paste("images/", test_suite, "/", sep = "")

# mesh & locations

generated_domain <- generate_domain("unit_square", 900)
domain <- generated_domain$domain
domain_boundary <- generated_domain$domain_boundary
mesh <- generated_domain$mesh

## locations
locations <- generate_locations(generated_domain, F, n_locs=900)
HR_grid <- spsample(domain_boundary, n_nodes_HR_grid, "regular")@coords

## Visualization ----
center_HR <- evaluate_field(HR_grid,model_FRPDE_miss$results$X_mean, mesh)
center_HR <- evaluate_field(HR_grid,model_FRPDE_old$results$X_mean, mesh)
center_HR <- evaluate_field(HR_grid,model_DINEOF_colMeans$results$X_mean, mesh)


 plot.field_tile(
   HR_grid,
   center_HR,
   limits = range(center_HR),
   ISOLINES = T) + 
   standard_plot_settings_fields()
 
 plot.field_tile(
   locations,
   center_HR,
   limits = range(model_DINEOF_colMeans$results$X_mean_locs),
   ISOLINES = T) + 
   standard_plot_settings_fields()

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

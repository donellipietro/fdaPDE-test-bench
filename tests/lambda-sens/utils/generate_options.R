generate_options <- function(name_main_test, path_queue) {
  ## create the directory if it does not exist
  mkdir(c(path_queue))
  
  ## name test suite
  test_suite <- "lambda-sens"
  
  ## defaults
  model_names <- c("sequential", 
                   "subspace", 
                   "direct")
  model_labels <- c("sequential", 
                   "subspace", 
                   "direct")
  
  seed <- 1412
  
  ## generate the options json files
  switch(name_main_test,
         test1 = {
           # Test 1: Varying lambda & NSR
           ## options grid
           lambda_vect <- 10^seq(-5,0,by=1)  # Varying lambda
           NSR_vect <- c(1)#0.1,0.5,1,5,10)
           n_nodes_vect <- c(900)
           n_locs_vect <- c(1600)
           n_stat_units_vect <- c(100)
           
           ## fixed options
           name_mesh <- "unit_square"
           name_mesh_short <- "us"
           n_comp <- 3
           ## assembly jsons
           for (n_nodes in n_nodes_vect){
           for (n_locs in n_locs_vect){  
           for (n_stat_units in n_stat_units_vect){
           for (NSR in NSR_vect) {
           for (lambda in lambda_vect) {
               name_test <- paste(
                 test_suite, name_main_test, name_mesh_short,
                 sprintf("%0*d", 4, n_nodes),
                 sprintf("%0*d", 4, n_locs),
                 sprintf("%0*d", 4, n_stat_units),
                 sprintf("lambda%.3f", lambda),
                 sprintf("NSR%.3f", NSR), 
                 n_comp,
                 sep = "_"
               )
               json_list <- list(
                 name_test = name_test,
                 model_names = model_names,
                 model_labels = model_labels,
                 mesh = list(
                   name_mesh = name_mesh
                 ),
                 dimensions = list(
                   n_nodes = n_nodes,
                   n_locs = n_locs,
                   n_stat_units = n_stat_units,
                   n_comp = n_comp,
                   n_reps = 30,
                   n_nodes_HR_grid = 1000
                 ),
                 data = list(
                   mean = F,
                   locs_eq_nodes = F
                 ),
                 noise = list(
                   NSR = NSR,
                   fpc_specific_noise = F,
                   seed = 1412
                 ),
                 regularization = list(
                   lambda = lambda
                 )
               )
               write_json(json_list, path = paste(path_queue, name_test, ".json", sep = ""))
             }
           }}}}
         },
         {
           stop(paste("The test", name_main_test, "does not exist"))
         }
  )
}


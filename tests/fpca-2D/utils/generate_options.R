generate_options <- function(name_main_test, path_queue) {
  ## create the directory if it does not exist
  mkdir(c(path_queue))
  
  ## name test suite
  test_suite <- "fpca-2D"
  
  ## defaults
  model_names <- c("sequential", 
                   "subspace", 
                   "subspace_experimental",
                   "direct")
  model_labels <- c("seq", 
                   "subspace", 
                   "sub-exp",
                   "direct")
  
  lambda_grid <- 10^seq(-6, 1, by = 1)
  seed <- 1412
  
  ## generate the options json files
  switch(name_main_test,
         test1 = {
           # Test 1: everything fixed
           n_nodes_vect <- c(1600,2500,3600)
           n_locs_vect <- c(1600,2500,3600)
           
           ## fixed options
           model_names <- c("sequential", 
                            "subspace", 
                            "direct")
           model_labels <- c("seq", 
                             "subspace", 
                             "direct")
           
           
           name_mesh <- "unit_square"
           name_mesh_short <- "us"
           
           n_stat_units <- 100
           n_nodes_HR_grid <- 1000
           
           locs_eq_nodes <- FALSE
           n_comp <- 5
           n_reps <- 10
           mean <- T
           NSR <- 1 # NSR = Var[noise]/Var[X]
           fPC1_specific_noise <- F
           
           ## assembly jsons
           for (n_nodes in n_nodes_vect) {
           for (n_locs in n_locs_vect) {
             name_test <- paste(
               test_suite, name_main_test, name_mesh_short,
               sprintf("%0*d", 4, n_nodes),
               sprintf("%0*d", 4, n_locs),
               sprintf("%0*d", 4, n_stat_units),
               NSR, n_comp,
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
                 n_reps = n_reps,
                 n_nodes_HR_grid = n_nodes_HR_grid
               ),
               data = list(
                 mean = mean,
                 locs_eq_nodes = locs_eq_nodes
               ),
               noise = list(
                 NSR = NSR,
                 seed = seed,
                 fPC1_specific_noise = fPC1_specific_noise
               ),
               regularization = list(
                 lambda_grid = lambda_grid,
                 n_comp = n_comp
               )
             )
             write_json(json_list, path = paste(path_queue, name_test, ".json", sep = ""))
           } #n_locs
           } #n_nodes
         },
         test2 = {
           # Test 2: Varying NSR
           ## options grid
           NSR_vect <- c(0.1,1)  # Varying NSR
           
           ## fixed options
           name_mesh <- "unit_square"
           name_mesh_short <- "us"
           
           n_nodes <- 900
           n_locs <- 1600
           n_stat_units <- 100
           n_comp <- 5
           
           ## assembly jsons
           for (NSR in NSR_vect) {
             name_test <- paste(
               test_suite, name_main_test, name_mesh_short,
               sprintf("%0*d", 4, n_nodes),
               sprintf("%0*d", 4, n_locs),
               sprintf("%0*d", 4, n_stat_units),
               NSR, n_comp,
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
                 n_nodes = 900,
                 n_locs = 1600,
                 n_stat_units = 100,
                 n_comp = n_comp,
                 n_reps = 10,
                 n_nodes_HR_grid = 1000
               ),
               data = list(
                 mean = T,
                 locs_eq_nodes = F
               ),
               noise = list(
                 heteroschedastic = F,
                 NSR = NSR,
                 seed = seed,
                 fPC1_specific_noise = F
               ),
               regularization = list(
                 lambda_grid = lambda_grid,
                 n_comp = n_comp
               )
             )
             write_json(json_list, path = paste(path_queue, name_test, ".json", sep = ""))
           }
         },
         test3 = {
           # Test 3: Varying NSR & noise specific on fPC1
           ## options grid
           n_nodes_vect <- c(900)
           n_locs_vect <- c(1600)
           n_stat_units_vect <- c(100)
           NSR_vect <- c(0.1,1,3)  # Varying NSR
           
           ## fixed options
           name_mesh_short <- "us"
           n_comp <- 3
           ## assembly jsons
           for (n_nodes in n_nodes_vect){
           for (n_locs in n_locs_vect){  
           for (n_stat_units in n_stat_units_vect){
           for (NSR in NSR_vect) {
             name_test <- paste(
               test_suite, name_main_test, name_mesh_short,
               sprintf("%0*d", 4, n_nodes),
               sprintf("%0*d", 4, n_locs),
               sprintf("%0*d", 4, n_stat_units),
               NSR, n_comp,
               sep = "_"
             )
             json_list <- list(
               name_test = name_test,
               model_names = model_names,
               model_labels = model_labels,
               mesh = list(
                 name_mesh = "unit_square"
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
                 mean = T,
                 locs_eq_nodes = F
               ),
               noise = list(
                 NSR = NSR,
                 seed = 1412,
                 fPC1_specific_noise = T
               ),
               regularization = list(
                 lambda_grid = lambda_grid,
                 n_comp = n_comp
               )
             )
             write_json(json_list, path = paste(path_queue, name_test, ".json", sep = ""))
           }}}}
         },
         {
           stop(paste("The test", name_main_test, "does not exist"))
         }
  )
}


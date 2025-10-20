generate_options <- function(name_main_test, path_queue) {
  ## create the directory if it does not exist
  mkdir(c(path_queue))
  
  ## name test suite
  test_suite <- "fpca-1D"
  
  ## defaults
  model_names <- c("sequential", 
                   "subspace", 
                   #"subspace_experimental",
                   "direct")
  model_labels <- c("seq", 
                    "subspace", 
                    #"sub-exp",
                    "direct")
  
  seed <- 1412
  
  ## generate the options json files
  switch(name_main_test,
         test1 = {
           # Test 1: everything fixed
           ## fixed options
           name_mesh <- "unit_interval"
           name_mesh_short <- "ui"
           
           n_nodes <- 400
           n_locs <- 625
           n_stat_units <- 50
           n_nodes_HR_grid <- 1000
           
           locs_eq_nodes <- FALSE
           n_comp <- 3
           n_reps <- 10
           mean <- T
           NSR <- 1 # NSR = Var[noise]/Var[X]
           fPC1_specific_noise <- T
           
           ## assembly jsons           
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
             )
           )
           write_json(json_list, path = paste(path_queue, name_test, ".json", sep = ""))
         },
         {
           stop(paste("The test", name_main_test, "does not exist"))
         }
  )
}


generate_options <- function(name_main_test, path_queue) {
  ## create the directory if it does not exist
  mkdir(c(path_queue))
  
  ## name test suite
  test_suite <- "subspace-it"
  
  ## generate the options json files
  switch(name_main_test,
         test1 = {
           # Test 1: everything fixed
           
           ## fixed options
           name_mesh <- "unit_square"
           name_mesh_short <- "us"
           
           n_nodes <- 20^2
           n_locs <- 600
           n_stat_units <- 50
           
           locs_eq_nodes <- FALSE
           n_comp <- 3
           n_reps <- 3
           mean <- T
           NSR <- 0.1 # NSR = Var[noise]/Var[X]
           fPC1_specific_noise <- F
           
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
             test = list(
               name_test = name_test
             ),
             mesh = list(
               name_mesh = name_mesh
             ),
             dimensions = list(
               n_nodes = n_nodes,
               n_locs = n_locs,
               n_stat_units = n_stat_units,
               n_comp = n_comp,
               n_reps = n_reps
             ),
             data = list(
               mean = mean,
               locs_eq_nodes = locs_eq_nodes
             ),
             noise = list(
               NSR = NSR,
               fPC1_specific_noise = fPC1_specific_noise
             )
           )
           write_json(json_list, path = paste(path_queue, name_test, ".json", sep = ""))
         },
         test2 = {
           # Test 2: Varying NSR
           ## options grid
           NSR_vect <- c(0.1, 0.2, 0.5, 1.0)  # Varying NSR
           
           ## fixed options
           name_mesh <- "unit_square"
           name_mesh_short <- "us"
           
           n_nodes <- 625
           n_locs <- 900
           n_stat_units <- 50
           
           locs_eq_nodes <- FALSE
           n_comp <- 3
           n_reps <- 10
           mean <- TRUE
           # wether the noise is applied specifically on the first fPC or not
           fPC1_specific_noise <- F
           
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
               test = list(
                 name_test = name_test
               ),
               mesh = list(
                 name_mesh = name_mesh
               ),
               dimensions = list(
                 n_nodes = n_nodes,
                 n_locs = n_locs,
                 n_stat_units = n_stat_units,
                 n_comp = n_comp,
                 n_reps = n_reps
               ),
               data = list(
                 mean = mean,
                 locs_eq_nodes = locs_eq_nodes
               ),
               noise = list(
                 NSR = NSR,
                 fPC1_specific_noise = fPC1_specific_noise
                 
               )
             )
             write_json(json_list, path = paste(path_queue, name_test, ".json", sep = ""))
           }
         },
         test3 = {
           # Test 3: Varying NSR & noise specific on fPC1
           ## options grid
           n_nodes <- 400
           n_locs <- 625
           n_stat_units <- 50
           NSR_vect <- c(0.1,0.2,0.5,1)  # Varying NSR
           
           ## fixed options
           name_mesh <- "unit_square"
           name_mesh_short <- "us"
           
           locs_eq_nodes <- FALSE
           n_comp <- 3
           n_reps <- 15
           mean <- TRUE
           # wether the noise is applied specifically on the first fPC or not
           fPC1_specific_noise <- T
           
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
               test = list(
                 name_test = name_test
               ),
               mesh = list(
                 name_mesh = name_mesh
               ),
               dimensions = list(
                 n_nodes = n_nodes,
                 n_locs = n_locs,
                 n_stat_units = n_stat_units,
                 n_comp = n_comp,
                 n_reps = n_reps
               ),
               data = list(
                 mean = mean,
                 locs_eq_nodes = locs_eq_nodes
               ),
               noise = list(
                 NSR = NSR,
                 fPC1_specific_noise = fPC1_specific_noise
               )
             )
             write_json(json_list, path = paste(path_queue, name_test, ".json", sep = ""))
           }
         },
         {
           stop(paste("The test", name_main_test, "does not exist"))
         }
  )
}


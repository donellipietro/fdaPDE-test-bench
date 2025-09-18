generate_options <- function(name_main_test, path_queue) {
  ## create the directory if it does not exist
  mkdir(c(path_queue))
  
  ## name test suite
  test_suite <- "lambda-sensibility"
  
  ## generate the options json files
  switch(name_main_test,
         test1 = {
           # Test 1: Varying lambda & NSR
           ## options grid
           lambda_vect <- 10^seq(-8,2,by=1)  # Varying lambda
           NSR_vect <- c(0.1,0.5,1,5,10)
           
           ## fixed options
           name_mesh <- "unit_square"
           name_mesh_short <- "us"
           
           n_nodes <- 600
           n_locs <- 900
           n_stat_units <- 50
           
           locs_eq_nodes <- FALSE
           n_comp <- 3
           n_reps <- 30
           mean <- F
           fpc_specific_noise <- F
           
           
           ## assembly jsons
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
                     fpc_specific_noise = fpc_specific_noise
                   ),
                   regularization = list(
                     lambda = lambda
                   )
                 )
                 write_json(json_list, path = paste(path_queue, name_test, ".json", sep = ""))
               }
           }
               
         },
         {
           stop(paste("The test", name_main_test, "does not exist"))
         }
  )
}


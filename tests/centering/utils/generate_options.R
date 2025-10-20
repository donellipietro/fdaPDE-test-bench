generate_options <- function(name_main_test, path_queue) {
  ## create the directory if it does not exist
  mkdir(c(path_queue))
  
  ## name test suite
  test_suite <- "centering"
  
  ## generate the options json files
  switch(name_main_test,
         
         # ---------- Test 1 ----------
         test1 = {
           n_nodes_vect <- c(30^2)
           n_locs_vect <- c(30^2) 
           n_stat_units_vect <- c(50,100,200)
           
           only_mean <- F
           
           name_mesh <- "unit_square"
           name_mesh_short <- "us"
           locs_eq_nodes <- FALSE
           n_reps <- 3
           NSR <- 0.3
           
           for (n_nodes in n_nodes_vect) {
             for (n_locs in n_locs_vect) {
               for (n_stat_units in n_stat_units_vect) {
                 name_test <- paste(
                   test_suite, name_main_test, name_mesh_short,
                   sprintf("%0*d", 4, n_nodes),
                   sprintf("%0*d", 4, n_locs),
                   sprintf("%0*d", 4, n_stat_units),
                   NSR,
                   sep = "_"
                 )
                 json_list <- list(
                   test = list(name_test = name_test),
                   mesh = list(name_mesh = name_mesh),
                   dimensions = list(
                     n_nodes = n_nodes,
                     n_locs = n_locs,
                     n_stat_units = n_stat_units,
                     n_reps = n_reps
                   ),
                   data = list(locs_eq_nodes = locs_eq_nodes),
                   noise = list(NSR = NSR)
                 )
                 write_json(json_list, path = file.path(path_queue, paste0(name_test, ".json")))
               }
             }
           }
         },
         
         # ---------- Test 2 ----------
         test2 = {
           ## Fixed values
           n_nodes <- 30^2
           n_locs <- c(800,30^2)
           n_stat_units <- 50
           n_reps <- 3
           name_mesh <- "unit_square"
           name_mesh_short <- "us"
           locs_eq_nodes <- FALSE
           NSR_vect <- c(0,0.1,0.2,0.5,1)
           
           only_mean <- F
           
           for (n_locs_val in n_locs) {
             for (NSR in NSR_vect) {
               name_test <- paste(
                 test_suite, name_main_test, name_mesh_short,
                 sprintf("%04d", n_nodes),
                 sprintf("%04d", n_locs_val),
                 sprintf("%04d", n_stat_units),
                 format(NSR, nsmall = 1),
                 sep = "_"
               )
               json_list <- list(
                 test = list(name_test = name_test),
                 mesh = list(name_mesh = name_mesh),
                 dimensions = list(
                   n_nodes = n_nodes,
                   n_locs = n_locs_val,
                   n_stat_units = n_stat_units,
                   n_reps = n_reps
                 ),
                 data = list(locs_eq_nodes = locs_eq_nodes, only_mean = only_mean),
                 noise = list(NSR = NSR)
                 )
               write_json(json_list, path = file.path(path_queue, paste0(name_test, ".json")))
             }
           }
         },
         
         # ---------- Test 3 ----------
         test3 = {
           ## Fixed values
           n_nodes <- 30^2
           n_locs <- c(800,30^2)
           n_stat_units <- 50
           n_reps <- 3
           name_mesh <- "unit_square"
           name_mesh_short <- "us"
           locs_eq_nodes <- FALSE
           NSR_vect <- c(0,0.1,0.2,0.5,1)
           
           only_mean <- T
           
           for (n_locs_val in n_locs) {
             for (NSR in NSR_vect) {
               name_test <- paste(
                 test_suite, name_main_test, name_mesh_short,
                 sprintf("%04d", n_nodes),
                 sprintf("%04d", n_locs_val),
                 sprintf("%04d", n_stat_units),
                 format(NSR, nsmall = 1),
                 sep = "_"
               )
               json_list <- list(
                 test = list(name_test = name_test),
                 mesh = list(name_mesh = name_mesh),
                 dimensions = list(
                   n_nodes = n_nodes,
                   n_locs = n_locs_val,
                   n_stat_units = n_stat_units,
                   n_reps = n_reps
                 ),
                 data = list(locs_eq_nodes = locs_eq_nodes, only_mean = only_mean),
                 noise = list(NSR = NSR)
               )
               write_json(json_list, path = file.path(path_queue, paste0(name_test, ".json")))
             }
           }
         },
         
         # ---------- Default ----------
         {
           stop(paste("The test", name_main_test, "does not exist"))
         }
  )
}

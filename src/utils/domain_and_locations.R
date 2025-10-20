generate_domain <- function(name_mesh = "unit_square", n_nodes = 1600) {
  switch(name_mesh,
    unit_interval = {
      ## boundary
      domain_boundary <- extent(0, 1, 0, 0)
      domain_boundary <- as(domain_boundary, "SpatialLines")
      ## knots
      knots <- unit_interval(n_nodes)
      
      return(list(
        domain_boundary = domain_boundary,
        knots = knots
      ))
    },
    unit_square = {
      ## domain
      femr_mesh <- femR::Mesh(unit_square(n_nodes))
      ## boundary
      domain_boundary <- extent(0, 1, 0, 1)
      domain_boundary <- as(domain_boundary, "SpatialPolygons")
      ## mesh fdaPDE1
      fdapde_mesh <- fdaPDE::create.mesh.2D(femr_mesh$nodes())
      
      return(list(
        femr_mesh = femr_mesh,
        domain_boundary = domain_boundary,
        fdapde_mesh = fdapde_mesh
      ))
    },
    {
      stop("The selected domain is not available.")
    }
  )
}

generate_locations <- function(generated_domain = generate_domain(), 
                               n_locs = n_locs,
                               locs_eq_nodes = FALSE) {
  if (locs_eq_nodes) {
    locations <- generated_domain$fdapde_mesh$nodes
    cat("\nLocations set to be equal to the nodes of the mesh!\n")
  } else {
    set.seed(-1)
    points <- spsample(generated_domain$domain_boundary, n_locs, type = "stratified")
    locations <- points@coords
    cat("\nCustom locations initialized!\n")
  }
  return(locations)
}

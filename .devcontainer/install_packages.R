# install_packages.R
packages <- c(
  "tidyverse",
  "data.table",
  "ggplot2",
  "Rcpp",
  "RcppEigen",
  "devtools"
)

install.packages(setdiff(packages, rownames(installed.packages())), repos = "https://cloud.r-project.org")

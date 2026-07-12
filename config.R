# = ========================================================================== =
# - Script: config.R
# - Desc: Editable runtime profiles for this repository.
# = ========================================================================== =

source("src/utils/config.R")


# Profiles ----

TESTBENCH_CONFIG_PROFILES <- list(
  macbook = local({
    PATH_REPO <- normalizePath(".", mustWork = FALSE)
    PATH_OUTPUT <- Sys.getenv("TESTBENCH_OUTPUT", unset = PATH_REPO)
    PATH_TMP <- file.path(PATH_OUTPUT, "tmp")
    PATH_FDAPDE_CPP <- Sys.getenv("PATH_FDAPDE_CPP", unset = "")
    PATH_FDAPDE_CLONES <- file.path(PATH_REPO, ".fdapde-cpp")

    list(
      PATH_REPO = PATH_REPO,

      PATH_RESULTS = file.path(PATH_OUTPUT, "results"),
      PATH_IMAGES = file.path(PATH_OUTPUT, "images"),
      PATH_TEST_DATA = file.path(PATH_OUTPUT, "data/tests"),
      PATH_TMP = PATH_TMP,
      PATH_QUEUE = file.path(PATH_TMP, "queue"),
      PATH_LOGS = file.path(PATH_REPO, "logs"),
      PATH_TMP_DATA = file.path(PATH_TMP, "data"),
      PATH_TMP_RESULTS = file.path(PATH_TMP, "results"),
      PATH_BUILD = file.path(PATH_OUTPUT, "build"),

      CC = Sys.getenv("CC", unset = "gcc"),
      CXX = Sys.getenv("CXX", unset = "g++"),
      PATH_FDAPDE_CPP = PATH_FDAPDE_CPP,
      PATH_FDAPDE_CORE = if (nzchar(PATH_FDAPDE_CPP)) {
        file.path(PATH_FDAPDE_CPP, "fdaPDE/core")
      } else {
        ""
      },
      PATH_EIGEN_INCLUDE = Sys.getenv("PATH_EIGEN_INCLUDE", unset = ""),
      FDAPDE_CPP_REPOSITORY = Sys.getenv("FDAPDE_CPP_REPOSITORY", unset = ""),
      FDAPDE_CPP_FEM_REF = Sys.getenv("FDAPDE_CPP_FEM_REF", unset = "stable"),
      FDAPDE_CPP_SPLINE_REF = Sys.getenv("FDAPDE_CPP_SPLINE_REF", unset = "develop-Splines"),
      PATH_FDAPDE_CLONES = PATH_FDAPDE_CLONES,
      PATH_FDAPDE_CPP_FEM = file.path(PATH_FDAPDE_CLONES, "fem"),
      PATH_FDAPDE_CPP_SPLINE = file.path(PATH_FDAPDE_CLONES, "spline"),

      SINGULARITY_IMAGE = "",
      SINGULARITY_BIND_PATHS = PATH_REPO,
      TEST_EXECUTION_STRATEGY = "parallel",
      COMPILE_STRATEGY = "local",
      MULTITHREAD_CPUS = Sys.getenv("MULTITHREAD_CPUS", unset = "12"),
      MULTITHREAD_MEM = Sys.getenv("MULTITHREAD_MEM", unset = "32GB"),
      MULTITHREAD_TIME = Sys.getenv("MULTITHREAD_TIME", unset = "12:00:00"),
      R_CRAN_REPO = "https://cloud.r-project.org",
      R_LIBS_USER = Sys.getenv("R_LIBS_USER", unset = ""),
      R_LIBS_SITE = Sys.getenv("R_LIBS_SITE", unset = "")
    )
  }),
  `hpc-slurm` = local({
    PATH_REPO <- normalizePath(".", mustWork = FALSE)
    PATH_OUTPUT <- Sys.getenv("TESTBENCH_OUTPUT", unset = PATH_REPO)
    PATH_TMP <- file.path(PATH_OUTPUT, "tmp")
    PATH_FDAPDE_CPP <- Sys.getenv("PATH_FDAPDE_CPP", unset = "")
    PATH_FDAPDE_CLONES <- file.path(PATH_REPO, ".fdapde-cpp")
    SINGULARITY_BIND_PATHS <- unique(c(PATH_REPO, PATH_OUTPUT, PATH_FDAPDE_CPP, PATH_FDAPDE_CLONES))
    SINGULARITY_BIND_PATHS <- SINGULARITY_BIND_PATHS[nzchar(SINGULARITY_BIND_PATHS)]

    list(
      PATH_REPO = PATH_REPO,

      PATH_RESULTS = file.path(PATH_OUTPUT, "results"),
      PATH_IMAGES = file.path(PATH_OUTPUT, "images"),
      PATH_TEST_DATA = file.path(PATH_OUTPUT, "data/tests"),
      PATH_TMP = PATH_TMP,
      PATH_QUEUE = file.path(PATH_TMP, "queue"),
      PATH_LOGS = file.path(PATH_REPO, "logs"),
      PATH_TMP_DATA = file.path(PATH_TMP, "data"),
      PATH_TMP_RESULTS = file.path(PATH_TMP, "results"),
      PATH_BUILD = file.path(PATH_OUTPUT, "build"),

      CC = Sys.getenv("CC", unset = "gcc"),
      CXX = Sys.getenv("CXX", unset = "g++"),
      PATH_FDAPDE_CPP = PATH_FDAPDE_CPP,
      PATH_FDAPDE_CORE = if (nzchar(PATH_FDAPDE_CPP)) {
        file.path(PATH_FDAPDE_CPP, "fdaPDE/core")
      } else {
        ""
      },
      PATH_EIGEN_INCLUDE = Sys.getenv("PATH_EIGEN_INCLUDE", unset = ""),
      FDAPDE_CPP_REPOSITORY = Sys.getenv("FDAPDE_CPP_REPOSITORY", unset = ""),
      FDAPDE_CPP_FEM_REF = Sys.getenv("FDAPDE_CPP_FEM_REF", unset = "stable"),
      FDAPDE_CPP_SPLINE_REF = Sys.getenv("FDAPDE_CPP_SPLINE_REF", unset = "develop-Splines"),
      PATH_FDAPDE_CLONES = PATH_FDAPDE_CLONES,
      PATH_FDAPDE_CPP_FEM = file.path(PATH_FDAPDE_CLONES, "fem"),
      PATH_FDAPDE_CPP_SPLINE = file.path(PATH_FDAPDE_CLONES, "spline"),

      SINGULARITY_IMAGE = Sys.getenv("SINGULARITY_IMAGE", unset = ""),
      SINGULARITY_BIND_PATHS = paste(SINGULARITY_BIND_PATHS, collapse = ","),
      TEST_EXECUTION_STRATEGY = "slurm",
      COMPILE_STRATEGY = "slurm",
      DEFAULT_CPUS = Sys.getenv("DEFAULT_CPUS", unset = "1"),
      DEFAULT_MEM = Sys.getenv("DEFAULT_MEM", unset = "8GB"),
      DEFAULT_TIME = Sys.getenv("DEFAULT_TIME", unset = "04:00:00"),
      MULTITHREAD_CPUS = Sys.getenv("MULTITHREAD_CPUS", unset = "20"),
      MULTITHREAD_MEM = Sys.getenv("MULTITHREAD_MEM", unset = "32GB"),
      MULTITHREAD_TIME = Sys.getenv("MULTITHREAD_TIME", unset = "12:00:00"),
      R_CRAN_REPO = "https://cloud.r-project.org",
      R_LIBS_USER = Sys.getenv("R_LIBS_USER", unset = ""),
      R_LIBS_SITE = Sys.getenv("R_LIBS_SITE", unset = "")
    )
  })
)


# Command line entry point ----

if (config_is_cli("config.R")) {
  config_main()
}

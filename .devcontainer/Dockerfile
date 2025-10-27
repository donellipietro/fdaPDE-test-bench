# Start from an R base image with dev tools
FROM rocker/r-ver:4.4.1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    g++ \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# --- Install Eigen ---
RUN apt-get update && apt-get install -y libeigen3-dev

# --- Clone the external C++ repo you need ---
# Replace the URL below with your actual repository
RUN git clone https://github.com/username/repo-with-cpp-scripts.git /opt/cpp_repo

# --- Install R packages (base packages for development) ---
RUN R -e "install.packages(c('devtools', 'remotes', 'tidyverse', 'Rcpp', 'RcppEigen', 'data.table', 'ggplot2'), repos='https://cloud.r-project.org')"

# Set working directory
WORKDIR /workspaces/${localWorkspaceFolderBasename}

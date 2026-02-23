# src/packages.R
# Common packages loaded by all scripts in this project.
# Source this file at the top of any script that needs these dependencies.
# Missing packages are installed automatically from CRAN.

required_pkgs <- c("tidyverse", "scales", "patchwork", "glmnet")

missing_pkgs <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  message("Installing missing packages: ", paste(missing_pkgs, collapse = ", "))
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org/")
}

suppressPackageStartupMessages({
  library(tidyverse)   # dplyr, ggplot2, readr, tidyr, stringr, forcats
  library(scales)      # axis and label formatting helpers
  library(patchwork)   # composing multi-panel ggplots
  library(glmnet)      # ridge, lasso, elastic net with CV
})

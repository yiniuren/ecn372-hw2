# src/scale_predictors.R
# Standardize predictors for ridge/LASSO/elastic net (and optionally OLS).
# Use training-set center/scale so the same transform can be applied to test.
# Source this from fit-models.R, final-model.R, and evaluate.R.

#' Compute center and scale from a matrix (e.g. training predictors).
#' Zero-variance columns get scale = 1 to avoid division by zero.
get_scale_params <- function(X) {
  center <- colMeans(X)
  scale  <- apply(X, 2, sd)
  scale[is.na(scale) | scale == 0] <- 1
  list(center = center, scale = scale)
}

#' Apply precomputed center/scale to a matrix (e.g. test predictors).
scale_predictors <- function(X, params) {
  scale(X, center = params$center, scale = params$scale)
}

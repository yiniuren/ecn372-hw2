# scripts/final-model.R
# Train the best model (from fit-models.R comparison) on the full training
# data and save the model object for use by evaluate.R.
#
# Run from project root: Rscript scripts/final-model.R
#
# Input:  data/processed/train_processed.csv
#         output/assessment/model_comparison.csv
# Output: output/final_model.rds

root <- getwd()
if (basename(root) == "scripts" && dir.exists(file.path(root, "..", "data"))) {
  root <- normalizePath(file.path(root, ".."))
} else if (!dir.exists(file.path(root, "data"))) {
  stop("Run this script from the project root.")
}

source(file.path(root, "src", "packages.R"))
source(file.path(root, "src", "scale_predictors.R"))


# ── 1. Determine best model ───────────────────────────────────────────────────

comparison <- read_csv(file.path(root, "output", "assessment", "model_comparison.csv"),
                       show_col_types = FALSE)
best <- comparison %>% slice_min(mse, n = 1)
best_model <- best$model[1]

cat(sprintf("Best model from CV: %s (MSE = %s)\n",
            best$label[1], format(round(best$mse[1]), big.mark = ",")))


# ── 2. Load processed training data ───────────────────────────────────────────

df <- read_csv(file.path(root, "data", "processed", "train_processed.csv"),
               show_col_types = FALSE)

y_log <- log1p(df$shares)
X     <- as.matrix(select(df, -shares))
feature_names <- colnames(X)

# Standardize predictors (same as in CV)
scale_params <- get_scale_params(X)
X_s <- scale_predictors(X, scale_params)


# ── 3. Train on full data ─────────────────────────────────────────────────────

if (best_model %in% c("ridge", "lasso")) {
  alpha_val <- switch(best_model, ridge = 0, lasso = 1)

  cv_fit  <- cv.glmnet(X_s, y_log, alpha = alpha_val, nfolds = 10, nlambda = 1000, standardize = FALSE)
  model_obj <- cv_fit
  lambda    <- cv_fit$lambda.min

  n_nonzero <- sum(coef(cv_fit, s = "lambda.min")[-1] != 0)
  cat(sprintf("Trained %s on full data: lambda.min = %.5f, non-zero coefs = %d / %d\n",
              best$label[1], lambda, n_nonzero, length(feature_names)))

} else if (best_model == "ols") {
  model_obj <- lm(y ~ ., data = data.frame(y = y_log, X_s))
  lambda <- NA_real_
  cat(sprintf("Trained OLS on full data: %d coefficients\n",
              length(coef(model_obj))))
}


# ── 4. Save ────────────────────────────────────────────────────────────────────

model_info <- list(
  type          = best_model,
  label         = best$label[1],
  model         = model_obj,
  lambda        = lambda,
  feature_names = feature_names,
  scale_center  = scale_params$center,
  scale_scale   = scale_params$scale
)

out_path <- file.path(root, "output", "final_model.rds")
saveRDS(model_info, out_path)
message("✓ Final model saved → ", out_path)

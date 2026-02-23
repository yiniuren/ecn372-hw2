# scripts/evaluate.R
# Load the trained model, preprocess test data, predict, and print MSE.
# This is the script invoked by `make evaluate`.
#
# Run from project root: Rscript scripts/evaluate.R
#
# Inputs:  data/raw/test.csv
#          output/final_model.rds
# Output:  prints "MSE: <value>" to stdout (nothing else)

root <- getwd()
if (basename(root) == "scripts" && dir.exists(file.path(root, "..", "data"))) {
  root <- normalizePath(file.path(root, ".."))
} else if (!dir.exists(file.path(root, "data"))) {
  stop("Run this script from the project root.")
}

suppressMessages({
  source(file.path(root, "src", "packages.R"))
  source(file.path(root, "src", "preprocess_fn.R"))
})


# ── 1. Train model if not already saved ────────────────────────────────────────

model_path <- file.path(root, "output", "final_model.rds")

if (!file.exists(model_path)) {
  message("Model not found — training from train.csv ...")
  source(file.path(root, "scripts", "preprocess.R"))
  source(file.path(root, "scripts", "fit-models.R"))
  source(file.path(root, "scripts", "final-model.R"))
}


# ── 2. Load model ─────────────────────────────────────────────────────────────

model_info <- readRDS(model_path)


# ── 3. Preprocess test data ───────────────────────────────────────────────────

test_raw <- read_csv(file.path(root, "data", "raw", "test.csv"),
                     show_col_types = FALSE)

test_df <- preprocess(test_raw)

y_true  <- test_df$shares
X_test  <- as.matrix(select(test_df, all_of(model_info$feature_names)))

# Standardize test predictors using training center/scale
X_test_s <- scale(X_test, center = model_info$scale_center, scale = model_info$scale_scale)


# ── 4. Predict (on log scale) ──────────────────────────────────────────────────

if (model_info$type %in% c("ridge", "lasso")) {
  preds_log <- as.numeric(
    predict(model_info$model, newx = X_test_s, s = model_info$lambda))

} else if (model_info$type == "ols") {
  preds_log <- predict(model_info$model, newdata = as.data.frame(X_test_s))
}


# ── 5. Compute and print MSE on log(1 + shares) scale ─────────────────────────

y_log <- log1p(y_true)
mse <- mean((y_log - preds_log)^2)
cat(sprintf("MSE: %.2f\n", mse))

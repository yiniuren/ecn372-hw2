# scripts/fit-models.R
# Compare models via nested 10-fold CV on log(1 + shares).
# Metrics (MSE, RMSE, R²) are computed on the log scale.
#
# Run from project root: Rscript scripts/fit-models.R
#
# Inputs:  data/processed/train_processed.csv
# Outputs: output/assessment/model_comparison.csv
#          output/assessment/lasso_coefficients.csv
#          output/figures/model_comparison.png
#          output/figures/lasso_path.png

root <- getwd()
if (basename(root) == "scripts" && dir.exists(file.path(root, "..", "data"))) {
  root <- normalizePath(file.path(root, ".."))
} else if (!dir.exists(file.path(root, "data"))) {
  stop("Run this script from the project root.")
}

source(file.path(root, "src", "packages.R"))
source(file.path(root, "src", "plot_theme.R"))
source(file.path(root, "src", "scale_predictors.R"))

assess_dir <- file.path(root, "output", "assessment")
fig_dir    <- file.path(root, "output", "figures")
dir.create(assess_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir,    recursive = TRUE, showWarnings = FALSE)


# ── 1. Load processed data ────────────────────────────────────────────────────

df <- read_csv(file.path(root, "data", "processed", "train_processed.csv"),
               show_col_types = FALSE)

y_raw <- df$shares
y_log <- log1p(y_raw)
X     <- as.matrix(select(df, -shares))

n <- nrow(X)
p <- ncol(X)
cat(sprintf("Data: %d obs × %d features, target = log1p(shares)\n", n, p))


# ── 2. Create fold IDs (shared across all models) ─────────────────────────────

set.seed(372)
K <- 10
foldid <- sample(rep(1:K, length.out = n))


# ── 3. Nested CV loop ─────────────────────────────────────────────────────────
# Outer loop: K folds for honest MSE estimation.
# Inner loop (for Ridge/LASSO): cv.glmnet selects lambda within each
#   outer training set (10-fold inner CV).

cv_preds <- matrix(NA_real_, nrow = n, ncol = 3,
                   dimnames = list(NULL, c("ols", "ridge", "lasso")))

for (k in 1:K) {
  cat(sprintf("── Outer fold %d / %d ──\n", k, K))
  tr <- foldid != k
  te <- foldid == k

  X_tr <- X[tr, ];  X_te <- X[te, ]
  y_tr <- y_log[tr]

  # Standardize using training fold only (no test leakage)
  scale_params <- get_scale_params(X_tr)
  X_tr_s <- scale_predictors(X_tr, scale_params)
  X_te_s <- scale_predictors(X_te, scale_params)

  # OLS (standardized predictors; same predictions as unstandardized)
  ols_df  <- data.frame(y = y_tr, X_tr_s)
  ols_fit <- lm(y ~ ., data = ols_df)
  cv_preds[te, "ols"] <- predict(ols_fit, newdata = data.frame(X_te_s))

  # Ridge  (alpha = 0) — standardize = FALSE since we pre-standardized; fine lambda grid
  ridge_cv <- cv.glmnet(X_tr_s, y_tr, alpha = 0, nfolds = 10, nlambda = 1000, standardize = FALSE)
  cv_preds[te, "ridge"] <- as.numeric(
    predict(ridge_cv, newx = X_te_s, s = "lambda.min"))

  # LASSO  (alpha = 1); fine lambda grid
  lasso_cv <- cv.glmnet(X_tr_s, y_tr, alpha = 1, nfolds = 10, nlambda = 1000, standardize = FALSE)
  cv_preds[te, "lasso"] <- as.numeric(
    predict(lasso_cv, newx = X_te_s, s = "lambda.min"))
}


# ── 4. Compute log-scale metrics (MSE, RMSE, R²) ─────────────────────────────

model_names <- colnames(cv_preds)
model_labels <- c(ols = "OLS", ridge = "Ridge", lasso = "LASSO")

ss_tot <- sum((y_log - mean(y_log))^2)

results <- tibble(
  model = model_names,
  label = model_labels[model_names],
  mse   = map_dbl(model_names, ~ mean((y_log - cv_preds[, .x])^2)),
  rmse  = map_dbl(model_names, ~ sqrt(mean((y_log - cv_preds[, .x])^2))),
  r2    = map_dbl(model_names, ~ 1 - sum((y_log - cv_preds[, .x])^2) / ss_tot),
  mae   = map_dbl(model_names, ~ mean(abs(y_log - cv_preds[, .x])))
) %>%
  arrange(mse)

cat("\n── Model comparison (10-fold nested CV, log-scale metrics) ──\n")
print(results)

write_csv(results, file.path(assess_dir, "model_comparison.csv"))
message("✓ Model comparison → ", file.path(assess_dir, "model_comparison.csv"))


# ── 5. Model comparison plot (all three metrics) ──────────────────────────────

results_long <- results %>%
  pivot_longer(cols = c(mse, rmse, r2, mae), names_to = "metric", values_to = "value") %>%
  mutate(
    metric = factor(metric, levels = c("mse", "rmse", "r2", "mae"),
                    labels = c("MSE", "RMSE", "R²", "MAE")),
    label  = fct_reorder(label, value, .fun = min)
  )

p_comp <- results_long %>%
  ggplot(aes(x = label, y = value, fill = metric)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(aes(label = round(value, 4)),
            position = position_dodge(width = 0.7),
            vjust = -0.4, size = 2.8) +
  facet_wrap(~ metric, scales = "free_y", nrow = 1) +
  scale_fill_manual(values = c("MSE" = "#4E79A7", "RMSE" = "#F28E2B", "R²" = "#59A14F", "MAE" = "#E15759")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Model comparison: 10-fold nested CV",
       subtitle = "Metrics on log(1 + shares) scale",
       x = NULL, y = NULL) +
  theme_hw() +
  theme(legend.position = "none")

ggsave(file.path(fig_dir, "model_comparison.png"), p_comp,
       width = 18, height = 5, dpi = 150)
message("✓ model_comparison.png saved")


# ── 6. LASSO analysis on full data ────────────────────────────────────────────
# Fit LASSO on all training data to get the coefficient path and
# the selected variables at lambda.min / lambda.1se.

scale_params_full <- get_scale_params(X)
X_s <- scale_predictors(X, scale_params_full)
lasso_full <- cv.glmnet(X_s, y_log, alpha = 1, nfolds = 10, nlambda = 1000, standardize = FALSE)

# Path plot
png(file.path(fig_dir, "lasso_path.png"), width = 900, height = 500, res = 120)
plot(lasso_full$glmnet.fit, xvar = "lambda", label = FALSE)
abline(v = log(lasso_full$lambda.min), lty = 2, col = "blue")
abline(v = log(lasso_full$lambda.1se), lty = 2, col = "red")
legend("topright",
       legend = c("lambda.min", "lambda.1se"),
       col = c("blue", "red"), lty = 2, cex = 0.8)
title("LASSO coefficient path")
dev.off()
message("✓ lasso_path.png saved")

# Extract non-zero coefficients at lambda.min
coef_min  <- coef(lasso_full, s = "lambda.min")
coef_1se  <- coef(lasso_full, s = "lambda.1se")

lasso_coefs <- tibble(
  feature     = rownames(coef_min),
  coef_min    = as.numeric(coef_min),
  coef_1se    = as.numeric(coef_1se)
) %>%
  filter(feature != "(Intercept)") %>%
  arrange(desc(abs(coef_min)))

cat(sprintf("\nLASSO variable selection (full data, lambda.min = %.5f):\n",
            lasso_full$lambda.min))
cat(sprintf("  Features with non-zero coef at lambda.min: %d / %d\n",
            sum(lasso_coefs$coef_min != 0), nrow(lasso_coefs)))
cat(sprintf("  Features with non-zero coef at lambda.1se: %d / %d\n",
            sum(lasso_coefs$coef_1se != 0), nrow(lasso_coefs)))

write_csv(lasso_coefs, file.path(assess_dir, "lasso_coefficients.csv"))
message("✓ lasso_coefficients.csv saved")

# Print the selected features
cat("\nTop LASSO features (by |coef| at lambda.min):\n")
lasso_coefs %>%
  filter(coef_min != 0) %>%
  head(20) %>%
  print()

message(sprintf(
  "\n── fit-models.R complete ──\nBest model: %s (log-scale MSE = %.4f, R² = %.4f)\n",
  results$label[1], results$mse[1], results$r2[1]
))

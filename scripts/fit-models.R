# scripts/fit-models.R
# Compare models via nested 10-fold CV on log(1 + shares).
# MSE is computed on the original (back-transformed) shares scale.
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
# Inner loop (for Ridge/LASSO/ENet): cv.glmnet selects lambda within each
#   outer training set (5-fold inner CV).

cv_preds <- matrix(NA_real_, nrow = n, ncol = 5,
                   dimnames = list(NULL, c("ols", "ridge", "lasso", "enet", "rf")))

for (k in 1:K) {
  cat(sprintf("── Outer fold %d / %d ──\n", k, K))
  tr <- foldid != k
  te <- foldid == k

  X_tr <- X[tr, ];  X_te <- X[te, ]
  y_tr <- y_log[tr]

  # OLS
  ols_df  <- data.frame(y = y_tr, X_tr)
  ols_fit <- lm(y ~ ., data = ols_df)
  cv_preds[te, "ols"] <- predict(ols_fit, newdata = data.frame(X_te))

  # Ridge  (alpha = 0)
  ridge_cv <- cv.glmnet(X_tr, y_tr, alpha = 0, nfolds = 5)
  cv_preds[te, "ridge"] <- as.numeric(
    predict(ridge_cv, newx = X_te, s = "lambda.min"))

  # LASSO  (alpha = 1)
  lasso_cv <- cv.glmnet(X_tr, y_tr, alpha = 1, nfolds = 5)
  cv_preds[te, "lasso"] <- as.numeric(
    predict(lasso_cv, newx = X_te, s = "lambda.min"))

  # Elastic Net (alpha = 0.5)
  enet_cv <- cv.glmnet(X_tr, y_tr, alpha = 0.5, nfolds = 5)
  cv_preds[te, "enet"] <- as.numeric(
    predict(enet_cv, newx = X_te, s = "lambda.min"))

  # Random Forest
  rf_fit <- ranger(y ~ ., data = data.frame(y = y_tr, X_tr),
                   num.trees = 500, seed = 372)
  cv_preds[te, "rf"] <- predict(rf_fit, data = data.frame(X_te))$predictions
}


# ── 4. Compute original-scale MSE ─────────────────────────────────────────────

model_names <- colnames(cv_preds)
model_labels <- c(ols = "OLS", ridge = "Ridge", lasso = "LASSO",
                  enet = "Elastic Net", rf = "Random Forest")

results <- tibble(
  model = model_names,
  label = model_labels[model_names],
  mse   = map_dbl(model_names, ~ mean((y_raw - expm1(cv_preds[, .x]))^2))
) %>%
  arrange(mse)

cat("\n── Model comparison (10-fold nested CV, original-scale MSE) ──\n")
print(results)

write_csv(results, file.path(assess_dir, "model_comparison.csv"))
message("✓ Model comparison → ", file.path(assess_dir, "model_comparison.csv"))


# ── 5. Model comparison bar plot ───────────────────────────────────────────────

p_comp <- results %>%
  mutate(label = fct_reorder(label, mse)) %>%
  ggplot(aes(x = label, y = mse)) +
  geom_col(fill = "#4E79A7", width = 0.6) +
  geom_text(aes(label = format(round(mse), big.mark = ",")),
            vjust = -0.4, size = 3.5) +
  scale_y_continuous(labels = label_comma(), expand = expansion(mult = c(0, 0.12))) +
  labs(title = "Model comparison: 10-fold nested CV",
       subtitle = "MSE on original shares scale (lower is better)",
       x = NULL, y = "MSE") +
  theme_hw()

ggsave(file.path(fig_dir, "model_comparison.png"), p_comp,
       width = 8, height = 5, dpi = 150)
message("✓ model_comparison.png saved")


# ── 6. LASSO analysis on full data ────────────────────────────────────────────
# Fit LASSO on all training data to get the coefficient path and
# the selected variables at lambda.min / lambda.1se.

lasso_full <- cv.glmnet(X, y_log, alpha = 1, nfolds = 10)

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
  "\n── fit-models.R complete ──\nBest model: %s (MSE = %s)\n",
  results$label[1], format(round(results$mse[1]), big.mark = ",")
))

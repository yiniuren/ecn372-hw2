# ECN 372 – Homework 2

Prediction assignment: build a model to predict article popularity (`shares`) on a held-out test set. The grader will run `make evaluate` to obtain the test MSE.

---

## Repository structure

```
ecn372-hw2/
├── README.md
├── AI_USAGE.md
├── Makefile
├── .gitignore
│
├── data/
│   ├── raw/               # train.csv; test.csv added at grading
│   └── processed/         # Preprocessed training data
│
├── src/
│   ├── packages.R          # Auto-install + load project packages
│   ├── plot_theme.R        # Shared ggplot2 theme
│   ├── preprocess_fn.R     # Reusable preprocess() function
│   └── scale_predictors.R  # get_scale_params() and scale_predictors()
│
├── scripts/
│   ├── data-summary.R      # EDA: distributions and summary stats
│   ├── preprocess.R        # Apply preprocessing to train.csv
│   ├── fit-models.R        # Nested 10×10-fold CV model comparison
│   ├── final-model.R       # Train best model on full data
│   └── evaluate.R          # Predict on test set and print MSE
│
└── output/
    ├── assessment/         # model_comparison.csv, lasso_coefficients.csv
    ├── summary/            # summary_statistics.csv
    ├── figures/            # All plots
    └── final_model.rds     # Saved model object
```

---

## Quick start

```bash
# 1. Preprocess raw training data
make preprocess

# 2. Compare models via nested 10×10-fold CV (takes a few minutes)
make compare

# 3. Train the best model on the full training set
make train

# 4. Evaluate on the test set (prints MSE only)
#    (The grader runs this after placing test.csv in data/raw/)
make evaluate
```

R packages (`tidyverse`, `scales`, `patchwork`, `glmnet`) are installed automatically by `src/packages.R` if missing.

---

## Approach

### Target

`shares` is heavily right-skewed (mean ~3,400, median 1,400, max 843,300). All models are fit on **log(1 + shares)**. Metrics (MSE, RMSE, R², MAE) are reported on this log scale.

### Preprocessing (`src/preprocess_fn.R`)

Applied identically to train and test data:

1. **Drop** `url` (identifier), `timedelta` (data-acquisition artifact), `is_weekend` (collinear with weekday dummies), `n_non_stop_words` and `n_unique_tokens` (extreme outlier values, redundant).
2. **Log-transform** right-skewed count and share features: `n_tokens_content`, `num_hrefs`, `num_self_hrefs`, `num_imgs`, `num_videos`, all `kw_*` columns, and the three `self_reference_*` columns. Uses `log1p(pmax(x, 0))` to handle zeros and sentinel values of −1.
3. **Interaction terms** (let LASSO decide which survive): weekend × keyword strength, channel × keyword strength (6 channels), images × entertainment, plus squared terms for `kw_avg_avg` and `n_tokens_content`.

### Standardization (`src/scale_predictors.R`)

After preprocessing, all predictors are **standardized to mean 0, SD 1** before fitting any model. Scale parameters (mean and SD) are computed **from the training data only** and applied to the test data — no leakage. Standardization is required for Ridge and LASSO so the L1/L2 penalty is applied fairly across all predictors.

### Variable selection

**LASSO** is the primary variable-selection tool. `cv.glmnet` with `alpha = 1` performs L1 penalization, shrinking irrelevant coefficients to exactly zero. We report both `lambda.min` (best CV error) and `lambda.1se` (most parsimonious within 1 SE). The LASSO coefficient path and selected features are saved to `output/assessment/`.

### Model comparison

Three models compared via **nested 10×10-fold CV** (outer 10 folds for honest error estimation; inner `cv.glmnet` with 10-fold CV for lambda tuning; 1000 lambda values per fit):

| Model | Description |
|---|---|
| OLS   | Ordinary least squares (no penalization) |
| Ridge | L2 penalty, all features retained (`alpha = 0`) |
| LASSO | L1 penalty, automatic variable selection (`alpha = 1`) |

All metrics (MSE, RMSE, R², MAE) are on the **log(1 + shares)** scale. The comparison plot is saved to `output/figures/model_comparison.png`. The model with the lowest log-scale MSE is selected as the final model, trained on the full training set, and saved to `output/final_model.rds`.

### Evaluation

`make evaluate` runs `scripts/evaluate.R`, which:
1. Loads the saved model (or trains from scratch if missing).
2. Reads `data/raw/test.csv` and applies the same `preprocess()` function and the training-set scale parameters.
3. Predicts on the log scale and prints **only** `MSE: <value>`.

---

## AI usage

See [AI_USAGE.md](AI_USAGE.md) for documentation of all AI tool usage (Cursor).

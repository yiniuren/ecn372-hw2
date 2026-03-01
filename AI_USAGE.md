# AI usage

This file documents how AI tools (e.g. Cursor) were used in this project.

---

## Summary

- **Tool:** Cursor (AI-assisted editing and code generation).
- **Use:** Repo setup, documentation, EDA scripting, and modeling pipeline scaffolding (preprocessing, standardization, nested CV, model comparison). 

---

## Interactions

1. **Project and data overview**  
   Asked the AI to read `requirements.md`, `OnlineNewsPopularity.names`, and inspect `train.csv`. The AI summarized: what the project does (predict `shares`, deliver `make evaluate` with test MSE), what `shares` is (number of article shares), and data insights (skewed target, feature groups, preprocessing suggestions).

2. **Repo structure (first step)**  
   Asked the AI to initialize the repository with no scripts or Makefile:
   - Created directories: `src/`, `scripts/`, `output/` (with `assessment/` and `figures/`), `data/` (with `raw/` and `processed/`).
   - Wrote `README.md` describing the repo structure.
   - Moved `train.csv` from the project root into `data/raw/`.

3. **Gitignore and AI documentation**  
   Asked the AI to: add a `.gitignore` that includes `requirements.md` and `OnlineNewsPopularity*`; create this `AI_USAGE.md`.

4. **Dataset inspection (second step)**  
   Asked the AI to write an EDA script. The AI created:
   - `src/packages.R` — reusable package loading with auto-install.
   - `src/plot_theme.R` — project-wide `ggplot2` theme.
   - `scripts/data-summary.R` — EDA script (summary statistics, target distribution, continuous and binary feature histograms).

5. **Modeling pipeline (third step)**  
   Asked the AI to plan and implement the full modeling pipeline. After discussing variable selection strategy, interaction terms, log-transforming features, standardization, and model comparison approach, the AI created:
   - `src/preprocess_fn.R` — reusable `preprocess()` function: drops non-predictive columns, log-transforms skewed features, adds targeted interaction and squared terms.
   - `src/scale_predictors.R` — `get_scale_params()` and `scale_predictors()`: standardize predictors to mean 0 / SD 1 using training-data statistics only (no test leakage), required for Ridge and LASSO penalties to be applied fairly.
   - `scripts/preprocess.R` — applies `preprocess()` to `train.csv`, saves to `data/processed/`.
   - `scripts/fit-models.R` — nested 10×10-fold CV (outer for honest error estimation, inner for lambda tuning with 1000 lambda values) comparing OLS, Ridge, and LASSO on log(1 + shares); reports MSE, RMSE, R², and MAE on the log scale; saves model comparison table, comparison plot, LASSO path plot, and coefficient summary.
   - `scripts/final-model.R` — reads the CV comparison, trains the winning model on the full training set (with standardization), saves model and scale parameters to `output/final_model.rds`.
   - `scripts/evaluate.R` — loads the model, preprocesses `test.csv`, applies the saved scale parameters, predicts on the log scale, and prints only the test MSE.
   - `Makefile` — targets for `preprocess`, `compare`, `train`, `evaluate`, and `clean`.
   - Updated `README.md` with full approach documentation.

---



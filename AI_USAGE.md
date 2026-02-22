# AI usage

This file documents how AI tools (e.g. Cursor) were used in this project.

---

## Summary

- **Tool:** Cursor (AI-assisted editing and code generation).
- **Use:** Repo setup, documentation, EDA scripting, and modeling pipeline scaffolding. Model selection strategy and final choices are the student's.

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
   Asked the AI to plan and implement the full modeling pipeline. After discussing variable selection strategy, interaction terms, log-transforming features, and model comparison approach, the AI created:
   - `src/preprocess_fn.R` — reusable `preprocess()` function: drops non-predictive columns, log-transforms skewed features, adds targeted interaction and squared terms.
   - `scripts/preprocess.R` — applies `preprocess()` to `train.csv`, saves to `data/processed/`.
   - `scripts/fit-models.R` — nested 10-fold CV comparing OLS, Ridge, LASSO, Elastic Net, and Random Forest on log(1 + shares); saves model comparison table, LASSO path plot, and coefficient summary.
   - `scripts/final-model.R` — reads the CV comparison, trains the winning model on the full training set, saves to `output/final_model.rds`.
   - `scripts/evaluate.R` — loads the model, preprocesses `test.csv`, predicts, back-transforms, and prints only the test MSE.
   - `Makefile` — targets for `preprocess`, `compare`, `train`, `evaluate`, and `clean`.
   - Updated `README.md` with full approach documentation.

---

## Extent

AI was used for scaffolding, code generation, and documentation. The student directed the overall strategy (which models, which features to transform, interaction term choices) and will review, run, and interpret the outputs. Variable selection and final model choice are driven by the data (LASSO + nested CV), not hard-coded by AI.

# Makefile for ECN 372 Homework 2
# Usage:
#   make preprocess   — preprocess raw training data
#   make compare      — run model comparison (nested CV)
#   make train        — preprocess + compare + train final model
#   make evaluate     — predict on test set and print MSE

.PHONY: preprocess compare train evaluate clean

# ── Preprocessing ──────────────────────────────────────────────────────────────

data/processed/train_processed.csv: data/raw/train.csv src/preprocess_fn.R
	Rscript scripts/preprocess.R

preprocess: data/processed/train_processed.csv

# ── Model comparison (optional, for exploration) ──────────────────────────────

output/assessment/model_comparison.csv: data/processed/train_processed.csv
	Rscript scripts/fit-models.R

compare: output/assessment/model_comparison.csv

# ── Train final model ─────────────────────────────────────────────────────────

output/final_model.rds: output/assessment/model_comparison.csv
	Rscript scripts/final-model.R

train: output/final_model.rds

# ── Evaluate on test set ──────────────────────────────────────────────────────
# If final_model.rds doesn't exist, evaluate.R will train from scratch.

evaluate:
	@Rscript scripts/evaluate.R

# ── Clean generated files ─────────────────────────────────────────────────────

clean:
	rm -f data/processed/train_processed.csv
	rm -f output/assessment/model_comparison.csv
	rm -f output/assessment/lasso_coefficients.csv
	rm -f output/final_model.rds

# ECN 372 – Homework 2

Prediction assignment: build a model to predict article popularity (`shares`) on a held-out test set. The grader will run `make evaluate` to obtain the test MSE.

---

## Repository structure

```
ecn372-hw2/
├── README.md              # This file; project overview and structure
├── AI_USAGE.md            # Documentation of AI tool usage (see assignment)
├── .gitignore             # Git ignore rules 
├── requirements.md       # Assignment requirements 
├── OnlineNewsPopularity.names   # Variable descriptions for the dataset
│
├── data/
│   ├── raw/               # Raw data 
│   └── processed/         # Processed/derived datasets 
│
├── src/                   # Source code 
├── scripts/               # Standalone scripts 
│
├── output/
│   ├── assessment/        # Model assessment outputs 
│   ├── summary/           # Summary statistics (e.g. data-summary CSV)
│   └── figures/           # Figures 
│
└── Makefile
```

- **`data/raw/`** — Place `train.csv` here; at grading, `test.csv` will be added here. All paths should assume data lives under `data/raw/`.
- **`data/processed/`** — For any cleaned, transformed, or feature-engineered datasets.
- **`src/`** — Reusable code (training pipeline, prediction, preprocessing) used by the main workflow.
- **`scripts/`** — One-off or exploratory scripts (e.g. EDA, experiments) that are not the main entry point for evaluation.
- **`output/assessment/`** — Saved model assessment results (e.g. cross-validation scores, test metrics).
- **`output/summary/`** — Summary statistics tables (e.g. from data-summary.R).
- **`output/figures/`** — Saved plots and figures.

The **Makefile** (with an `evaluate` target) will be added once the main code is in place.

---


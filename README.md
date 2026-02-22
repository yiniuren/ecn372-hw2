# ECN 372 – Homework 2

Prediction assignment: build a model to predict article popularity (`shares`) on a held-out test set. The grader will run `make evaluate` to obtain the test MSE.

---

## Repository structure

```
ecn372-hw2/
├── README.md              # This file; project overview and structure
├── AI_USAGE.md            # Documentation of AI tool usage (see assignment)
├── .gitignore             # Git ignore rules (includes requirements.md)
├── requirements.md       # Assignment requirements (from course; gitignored)
├── OnlineNewsPopularity.names   # Variable descriptions for the dataset
│
├── data/
│   ├── raw/               # Raw data (train.csv; test.csv added at grading)
│   └── processed/         # Processed/derived datasets (e.g. cleaned, scaled)
│
├── src/                   # Source code (e.g. model training, prediction, utilities)
├── scripts/               # Standalone scripts (e.g. EDA, one-off runs)
│
├── output/
│   ├── assessment/        # Model assessment outputs (e.g. CV results, metrics)
│   └── figures/           # Figures (e.g. EDA plots, validation curves)
│
└── (Makefile to be added later)
```

- **`data/raw/`** — Place `train.csv` here; at grading, `test.csv` will be added here. All paths should assume data lives under `data/raw/`.
- **`data/processed/`** — For any cleaned, transformed, or feature-engineered datasets.
- **`src/`** — Reusable code (training pipeline, prediction, preprocessing) used by the main workflow.
- **`scripts/`** — One-off or exploratory scripts (e.g. EDA, experiments) that are not the main entry point for evaluation.
- **`output/assessment/`** — Saved model assessment results (e.g. cross-validation scores, test metrics).
- **`output/figures/`** — Saved plots and figures.

The **Makefile** (with an `evaluate` target) will be added once the main code is in place.

---

## First step: repo initialization

The repository was set up with the following (no scripts or Makefile yet):

- **Directories created:** `src/`, `scripts/`, `output/assessment/`, `output/figures/`, `data/raw/`, `data/processed/`. Empty directories use `.gitkeep` so Git tracks them.
- **README:** This file, with the repository structure documented above.
- **Data:** `train.csv` was moved from the project root into `data/raw/` so all data lives under `data/raw/` (consistent with grading, which adds `test.csv` there).
- **Deferred:** Makefile and all scripts; to be added after the main code is written.

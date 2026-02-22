# AI usage

This file documents how AI tools (e.g. Cursor) were used in this project.

---

## Summary

- **Tool:** Cursor (AI-assisted editing and code generation).
- **Use:** Repo setup, documentation, and EDA scripting. Model selection and core analysis done by the student.

---

## Interactions

1. **Project and data overview**  
   Asked the AI to read `requirements.md`, `OnlineNewsPopularity.names`, and inspect `train.csv`. The AI summarized: what the project does (predict `shares`, deliver `make evaluate` with test MSE), what `shares` is (number of article shares), and data insights (skewed target, feature groups, preprocessing suggestions).

2. **Repo structure (first step)**  
   Asked the AI to initialize the repository with no scripts or Makefile:
   - Created directories: `src/`, `scripts/`, `output/` (with `assessment/` and `figures/`), `data/` (with `raw/` and `processed/`).
   - Used `.gitkeep` in empty folders so they are tracked by Git.
   - Wrote `README.md` describing the repo structure.
   - Moved `train.csv` from the project root into `data/raw/`.
   - Did **not** create the Makefile (to be added after most code is done).

3. **Gitignore and AI documentation**  
   Asked the AI to: add a `.gitignore` that includes `requirements.md`; create this `AI_USAGE.md`; and document the "first step" (repo initialization) in the README.

4. **Dataset inspection (second step)**  
   Asked the AI to write an EDA script. The AI created:
   - `src/packages.R` — reusable package loading (`tidyverse`, `skimr`, `scales`, `patchwork`, `here`).
   - `src/plot_theme.R` — reusable project-wide `ggplot2` theme (`theme_hw()`).
   - `scripts/data-summary.R` — EDA script that: loads and classifies variables; saves a full `skimr` summary table to `output/assessment/`; plots the target distribution (raw and log-transformed); plots continuous features as batched histogram grids; and plots binary feature bar charts. All figures go to `output/figures/data-summary/`.
   - `.here` marker file at the project root (required by the `here` package).

---

## Extent

AI was used for setup, documentation, and EDA scaffolding. Variable selection, model choice, tuning, and interpretation are done by the student.

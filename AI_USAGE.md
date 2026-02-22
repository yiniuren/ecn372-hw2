# AI usage

This file documents how AI tools (e.g. Cursor) were used in this project.

---

## Summary

- **Tool:** Cursor (AI-assisted editing and code generation).
- **Use:** Repo setup, documentation, and guidance. No model code or analysis written by AI yet.

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
   Asked the AI to: add a `.gitignore` that includes `requirements.md`; create this `AI_USAGE.md`; and document the “first step” (repo initialization) in the README.

---

## Extent

AI was used for setup and documentation only. Model selection, preprocessing, and implementation will be done by the student, with any further AI use documented here.

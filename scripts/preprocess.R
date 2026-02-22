# scripts/preprocess.R
# Apply preprocessing to raw training data and save the result.
#
# Run from project root: Rscript scripts/preprocess.R
#
# Input:  data/raw/train.csv
# Output: data/processed/train_processed.csv

root <- getwd()
if (basename(root) == "scripts" && dir.exists(file.path(root, "..", "data"))) {
  root <- normalizePath(file.path(root, ".."))
} else if (!dir.exists(file.path(root, "data"))) {
  stop("Run this script from the project root.")
}

source(file.path(root, "src", "packages.R"))
source(file.path(root, "src", "preprocess_fn.R"))

out_dir <- file.path(root, "data", "processed")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ── Load & preprocess ─────────────────────────────────────────────────────────

df <- read_csv(file.path(root, "data", "raw", "train.csv"), show_col_types = FALSE)

cat(sprintf("Raw data: %d rows × %d columns\n", nrow(df), ncol(df)))

df_processed <- preprocess(df)

cat(sprintf("Processed data: %d rows × %d columns\n",
            nrow(df_processed), ncol(df_processed)))

write_csv(df_processed, file.path(out_dir, "train_processed.csv"))
message("✓ Saved → ", file.path(out_dir, "train_processed.csv"))

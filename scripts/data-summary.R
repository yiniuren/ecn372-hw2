# scripts/data-summary.R
# Exploratory data summary: distribution plots and summary statistics.
#
# Run from project root: Rscript scripts/data-summary.R
#
# Outputs:
#   output/assessment/summary_statistics.csv   — summary statistics table
#   output/figures/data-summary/
#     target_distribution.png                  — raw vs log(1+shares)
#     continuous_features_batch01.png, ...     — histograms for numeric features
#     binary_features.png                      — bar charts for 0/1 flags

# Project root: directory containing data/ and output/
root <- getwd()
if (basename(root) == "scripts" && dir.exists(file.path(root, "..", "data"))) {
  root <- normalizePath(file.path(root, ".."))
} else if (!dir.exists(file.path(root, "data"))) {
  stop("Run this script from the project root (directory containing data/ and output/).")
}

source(file.path(root, "src", "packages.R"))
source(file.path(root, "src", "plot_theme.R"))


# ── 0. Output paths ────────────────────────────────────────────────────────────

fig_dir    <- file.path(root, "output", "figures", "data-summary")
assess_dir <- file.path(root, "output", "assessment")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)


# ── 1. Load data ───────────────────────────────────────────────────────────────

df <- read_csv(file.path(root, "data", "raw", "train.csv"), show_col_types = FALSE) %>%
  rename_with(str_trim) %>%   # strip any leading/trailing whitespace from names
  select(-url)                 # drop non-predictive identifier

cat(sprintf("Data loaded: %d rows × %d columns\n", nrow(df), ncol(df)))


# ── 2. Summary statistics ──────────────────────────────────────────────────────

summary_tbl <- df %>%
  pivot_longer(everything(), names_to = "variable", values_to = "value") %>%
  group_by(variable) %>%
  summarise(
    n        = n(),
    n_missing = sum(is.na(value)),
    mean     = mean(value, na.rm = TRUE),
    sd       = sd(value, na.rm = TRUE),
    min      = min(value, na.rm = TRUE),
    q25      = quantile(value, 0.25, na.rm = TRUE),
    median   = median(value, na.rm = TRUE),
    q75      = quantile(value, 0.75, na.rm = TRUE),
    max      = max(value, na.rm = TRUE),
    .groups  = "drop"
  )

print(summary_tbl)
write_csv(summary_tbl, file.path(assess_dir, "summary_statistics.csv"))
message("✓ Summary statistics → ", file.path(assess_dir, "summary_statistics.csv"))


# ── 3. Classify variables ──────────────────────────────────────────────────────

binary_vars <- df %>%
  select(where(~ is.numeric(.) && all(unique(.) %in% c(0, 1)))) %>%
  names()

continuous_vars <- df %>%
  select(where(is.numeric)) %>%
  select(-all_of(binary_vars)) %>%
  names()

target_var   <- "shares"
feature_vars <- setdiff(continuous_vars, target_var)

cat(sprintf(
  "Variable groups — continuous: %d  |  binary: %d  |  target: 1\n",
  length(feature_vars), length(binary_vars)
))


# ── 4. Target distribution ─────────────────────────────────────────────────────

p_raw <- df %>%
  ggplot(aes(x = shares)) +
  geom_histogram(bins = 80, fill = "#4E79A7", color = "white", linewidth = 0.15) +
  scale_x_continuous(labels = label_comma()) +
  scale_y_continuous(labels = label_comma()) +
  labs(title = "Raw shares", x = "shares", y = "count") +
  theme_hw()

p_log <- df %>%
  ggplot(aes(x = log1p(shares))) +
  geom_histogram(bins = 60, fill = "#F28E2B", color = "white", linewidth = 0.15) +
  scale_y_continuous(labels = label_comma()) +
  labs(title = "log(1 + shares)", x = "log(1 + shares)", y = "count") +
  theme_hw()

p_target <- (p_raw | p_log) +
  plot_annotation(
    title    = "Target variable: shares",
    subtitle = "Highly right-skewed; log-transformation likely needed for modeling",
    theme    = theme(plot.title = element_text(face = "bold", size = 14))
  )
ggsave(file.path(fig_dir, "target_distribution.png"), p_target,
       width = 12, height = 5, dpi = 150)

message("✓ target_distribution.png saved")


# ── 5. Continuous feature distributions (batched grid) ────────────────────────

n_cols      <- 6
batch_size  <- 24
var_batches <- split(feature_vars, ceiling(seq_along(feature_vars) / batch_size))

walk(seq_along(var_batches), function(i) {
  vars_i <- var_batches[[i]]
  n_rows  <- ceiling(length(vars_i) / n_cols)

  p <- df %>%
    select(all_of(vars_i)) %>%
    pivot_longer(everything(), names_to = "variable", values_to = "value") %>%
    ggplot(aes(x = value)) +
    geom_histogram(bins = 40, fill = "#76B7B2", color = "white", linewidth = 0.1) +
    facet_wrap(~ variable, scales = "free", ncol = n_cols) +
    scale_y_continuous(labels = label_comma()) +
    labs(
      title = sprintf("Continuous feature distributions — batch %d of %d",
                      i, length(var_batches)),
      x = NULL, y = "count"
    ) +
    theme_hw() +
    theme(strip.text = element_text(size = 7),
          axis.text  = element_text(size = 6))

  fname <- sprintf("continuous_features_batch%02d.png", i)
  ggsave(file.path(fig_dir, fname), p,
         width = 18, height = n_rows * 3 + 2, dpi = 130)
  message(sprintf("✓ %s saved", fname))
})


# ── 6. Binary feature distributions ───────────────────────────────────────────

n_cols_bin <- 5

p_binary <- df %>%
  select(all_of(binary_vars)) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "value") %>%
  mutate(value = factor(value, levels = c(0, 1), labels = c("0 (No)", "1 (Yes)"))) %>%
  ggplot(aes(x = value, fill = value)) +
  geom_bar() +
  scale_fill_manual(values = c("0 (No)" = "#BAB0AC", "1 (Yes)" = "#59A14F")) +
  scale_y_continuous(labels = label_comma()) +
  facet_wrap(~ variable, scales = "free_y", ncol = n_cols_bin) +
  labs(title = "Binary feature distributions", x = NULL, y = "count") +
  theme_hw() +
  theme(strip.text      = element_text(size = 8),
        axis.text.x     = element_text(size = 8),
        legend.position = "none")

ggsave(
  file.path(fig_dir, "binary_features.png"), p_binary,
  width  = 14,
  height = ceiling(length(binary_vars) / n_cols_bin) * 3 + 2,
  dpi    = 130
)

message("✓ binary_features.png saved")

message(sprintf(
  "\n── data-summary.R complete ──\nFigures  → %s\nStats    → %s\n",
  fig_dir, file.path(assess_dir, "summary_statistics.csv")
))

# src/preprocess_fn.R
# Reusable preprocessing function applied to both train and test data.
# Source this file in any script that needs to prepare raw data for modeling.

# Columns to drop: non-predictive or problematic
cols_to_drop <- c("url", "timedelta", "is_weekend",
                  "n_non_stop_words", "n_unique_tokens")

# Right-skewed features to log-transform via log1p(pmax(x, 0)).
# pmax(., 0) handles sentinel values of -1 in some kw_* columns.
cols_to_log <- c(
  "n_tokens_content", "num_hrefs", "num_self_hrefs", "num_imgs", "num_videos",
  "kw_max_min", "kw_avg_min", "kw_min_max", "kw_max_max", "kw_avg_max",
  "kw_min_avg", "kw_max_avg", "kw_avg_avg",
  "self_reference_min_shares", "self_reference_max_shares",
  "self_reference_avg_sharess"
)

preprocess <- function(df) {
  df <- df %>%
    rename_with(str_trim) %>%
    select(-any_of(cols_to_drop))

  df <- df %>%
    mutate(across(all_of(cols_to_log), ~ log1p(pmax(., 0))))

  # Targeted interaction terms (use log-transformed values)
  df <- df %>%
    mutate(
      weekend_x_kwavg     = (weekday_is_saturday + weekday_is_sunday) * kw_avg_avg,
      ent_x_kwavg         = data_channel_is_entertainment * kw_avg_avg,
      bus_x_kwavg         = data_channel_is_bus * kw_avg_avg,
      socmed_x_kwavg      = data_channel_is_socmed * kw_avg_avg,
      tech_x_kwavg        = data_channel_is_tech * kw_avg_avg,
      world_x_kwavg       = data_channel_is_world * kw_avg_avg,
      imgs_x_entertainment = num_imgs * data_channel_is_entertainment,
      kw_avg_avg_sq        = kw_avg_avg^2,
      n_tokens_content_sq  = n_tokens_content^2
    )

  df
}

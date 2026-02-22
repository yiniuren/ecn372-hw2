# src/plot_theme.R
# Project-wide ggplot2 theme applied to all figures.
# Source this file whenever a script produces plots.

theme_hw <- function(base_size = 11, ...) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey92", linewidth = 0.4),
      strip.background = element_rect(fill = "grey95", color = NA),
      strip.text       = element_text(face = "bold"),
      plot.title       = element_text(face = "bold", hjust = 0, size = rel(1.1)),
      plot.subtitle    = element_text(hjust = 0, color = "grey40", size = rel(0.9)),
      axis.title       = element_text(size = rel(0.9)),
      legend.position  = "bottom",
      ...
    )
}

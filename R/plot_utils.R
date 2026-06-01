# High-quality plot save via ragg.
# ragg uses Cairo-style anti-aliased text rendering for crisp output at any DPI;
# the default `png()` device on macOS produces noticeably softer/pixelated text.

if (!requireNamespace("ragg", quietly = TRUE)) {
  install.packages("ragg", repos = "https://cloud.r-project.org")
}

# Save a ggplot at publication quality.
# Defaults: 300 DPI, ragg renderer, scaling that keeps font sizes consistent.
save_plot_hq <- function(plot, path, width, height, dpi = 300, ...) {
  ggsave(filename = path, plot = plot,
         width = width, height = height, dpi = dpi,
         device = ragg::agg_png, units = "in", ...)
}

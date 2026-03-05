#!/usr/bin/env Rscript

library(ggplot2)
library(readr)
library(dplyr)
library(ggbeeswarm)

# -----------------------------
# Parse command line arguments
# -----------------------------

args <- commandArgs(trailingOnly = TRUE)

if(length(args) < 4){
  stop("Usage: Rscript plot_taxa.R <csv> <y_col> <tax_level> <outfile> [--filter col values...] [--dual values...]")
}

input_csv <- args[1]
y_col <- args[2]
tax_level <- args[3]
outfile <- args[4]

filter_col <- NULL
filter_values <- NULL
dual_values <- NULL

filter_idx <- which(args == "--filter")
dual_idx <- which(args == "--dual")

# -----------------------------
# Parse filter arguments
# -----------------------------

if(length(filter_idx) > 0){

  next_flag <- min(c(
    dual_idx[dual_idx > filter_idx],
    length(args) + 1
  ), na.rm = TRUE)

  filter_col <- args[filter_idx + 1]

  if(next_flag > filter_idx + 2){
    filter_values <- args[(filter_idx + 2):(next_flag - 1)]
  }
}

# -----------------------------
# Parse dual arguments
# -----------------------------

if(length(dual_idx) > 0){

  next_flag <- length(args) + 1
  dual_values <- args[(dual_idx + 1):(next_flag - 1)]

  if(length(dual_values) > 2){
    stop("Dual plotting supports maximum of two values.")
  }
}

# -----------------------------
# Load dataframe
# -----------------------------

df <- read_csv(input_csv, show_col_types = FALSE)

if(!(y_col %in% colnames(df))){
  stop(paste("Column", y_col, "not found in dataframe"))
}

if(!(tax_level %in% colnames(df))){
  stop(paste("Taxonomic level", tax_level, "not found in dataframe"))
}

# -----------------------------
# Apply filtering
# -----------------------------

if(!is.null(filter_col)){

  if(!(filter_col %in% colnames(df))){
    stop(paste("Filter column", filter_col, "not found in dataframe"))
  }

  if(!is.null(filter_values)){
    df <- df %>%
      filter(.data[[filter_col]] %in% filter_values)
  }
}

# -----------------------------
# Clean dataframe
# -----------------------------

plot_df <- df %>%
  filter(
    !is.na(.data[[tax_level]]),
    !is.na(.data[[y_col]])
  )

# optional length filter (helps visualization)
plot_df <- plot_df %>% filter(.data[[y_col]] > 250)

# reorder taxa by median value
plot_df[[tax_level]] <- reorder(
  plot_df[[tax_level]],
  plot_df[[y_col]],
  FUN = median,
  na.rm = TRUE
)

# -----------------------------
# Dual comparison handling
# -----------------------------

if(!is.null(dual_values)){

  if(is.null(filter_col)){
    stop("Dual plotting requires a filter column.")
  }

  plot_df <- plot_df %>%
    filter(.data[[filter_col]] %in% dual_values)

  fill_col <- filter_col
  dodge <- TRUE

} else {

  fill_col <- tax_level
  dodge <- FALSE
}

# -----------------------------
# Compute counts
# -----------------------------

count_df <- plot_df %>%
  group_by(across(all_of(c(tax_level, fill_col)))) %>%
  summarise(n = n(), .groups = "drop")

y_max <- max(plot_df[[y_col]], na.rm = TRUE)

# -----------------------------
# Build plot
# -----------------------------

p <- ggplot(
  plot_df,
  aes(
    x = .data[[tax_level]],
    y = .data[[y_col]],
    fill = .data[[fill_col]]
  )
)

# violin layer
p <- p +
  geom_violin(
    trim = TRUE,
    width = 0.65,
    alpha = 0.30,
    position = if(dodge) position_dodge(0.75) else "identity"
  )

# boxplot
p <- p +
  geom_boxplot(
    width = 0.12,
    outlier.shape = NA,
    alpha = 0.85,
    position = if(dodge) position_dodge(0.75) else "identity"
  )

# beeswarm points
p <- p +
  geom_quasirandom(
    aes(color = .data[[fill_col]]),
    dodge.width = if(dodge) 0.75 else 0,
    size = 0.5,
    alpha = 0.6
  )

# color scales
p <- p +
  scale_fill_manual(values = c("#009E73", "#E69F00")) +
  scale_color_manual(values = c("#009E73", "#E69F00")) +
  guides(color = "none")

# y-axis zoom
p <- p +
  coord_cartesian(ylim = c(200, 600))

# n labels
p <- p +
  geom_text(
    data = count_df,
    aes(
      x = .data[[tax_level]],
      y = y_max * 1.04,
      label = paste0("n=", n),
      group = .data[[fill_col]]
    ),
    position = if(dodge) position_dodge(width = 0.75) else "identity",
    size = 3
  )

# styling
p <- p +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 30, hjust = 1),
    legend.position = ifelse(dodge, "right", "none")
  ) +
  labs(
    x = tax_level,
    y = paste0(y_col, " (aa)"),
    fill = "Protein",
    title = paste(y_col, "distribution across", tax_level)
  )

# -----------------------------
# Save plot
# -----------------------------

dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

plot_width <- max(6, 1 + 0.8 * length(unique(plot_df[[tax_level]])))

ggsave(outfile, p, width = plot_width, height = 6, dpi = 300)

message(paste("Saved:", outfile))
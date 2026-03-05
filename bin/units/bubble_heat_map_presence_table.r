#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(tidyverse))

# -----------------------------
# Parse arguments
# -----------------------------

args <- commandArgs(trailingOnly = TRUE)

if(length(args) < 5){
  stop("Usage: Rscript copy_heatmap.R <csv> <tax_level> <genome_col> <protein_col> <outfile> --proteins <p1 p2 ...>")
}

input_csv   <- args[1]
tax_level   <- args[2]
genome_col  <- args[3]
protein_col <- args[4]
outfile     <- args[5]

proteins_idx <- which(args == "--proteins")

if(length(proteins_idx) == 0){
  stop("Must provide --proteins followed by protein names")
}

protein_list <- args[(proteins_idx + 1):length(args)]

# Strip any surrounding shell quotes that Snakemake :q formatting may inject
# e.g. 'SepF' -> SepF  or  "SepF" -> SepF
protein_list <- gsub("^['\"]|['\"]$", "", protein_list)

# -----------------------------
# Load dataframe
# -----------------------------

df <- read_csv(input_csv, show_col_types = FALSE)

df <- df %>%
  filter(.data[[protein_col]] %in% protein_list)

df[[protein_col]] <- factor(df[[protein_col]], levels = protein_list)

# -----------------------------
# Count copies per genome
# -----------------------------

copy_counts <- df %>%
  group_by(
    genome  = .data[[genome_col]],
    taxon   = .data[[tax_level]],
    protein = .data[[protein_col]]
  ) %>%
  summarise(
    copies = n(),
    .groups = "drop"
  )

# -----------------------------
# Count genomes per taxon
# -----------------------------

genome_counts <- df %>%
  distinct(
    genome = .data[[genome_col]],
    taxon  = .data[[tax_level]]
  ) %>%
  count(taxon, name = "genomes")

# -----------------------------
# All taxa present in the data
# -----------------------------

all_taxa <- unique(df[[tax_level]])

# -----------------------------
# Ensure every protein x taxon combination appears
# -----------------------------

max_copy_df <- expand_grid(
  taxon   = all_taxa,
  protein = factor(protein_list, levels = protein_list)
) %>%
  left_join(
    copy_counts %>%
      group_by(taxon, protein) %>%
      summarise(max_copy = max(copies), .groups = "drop"),
    by = c("taxon", "protein")
  ) %>%
  mutate(max_copy = replace_na(max_copy, 0))

# -----------------------------
# Expand copy levels
# Proteins with zero copies get a single row with copy_level = NA
# -----------------------------

prop_df <- max_copy_df %>%
  rowwise() %>%
  mutate(copy_level = list(if (max_copy > 0) 1:max_copy else NA_real_)) %>%
  unnest(copy_level, keep_empty = TRUE) %>%
  left_join(genome_counts, by = "taxon") %>%
  rowwise() %>%
  mutate(
    genomes_with_copy = if (is.na(copy_level) || max_copy == 0) {
      0L
    } else {
      sum(
        copy_counts$copies[
          copy_counts$taxon   == taxon &
          copy_counts$protein == protein
        ] >= copy_level
      )
    },
    proportion = if (max_copy == 0 || is.na(copy_level)) 0 else genomes_with_copy / genomes
  ) %>%
  ungroup()

# replace NA copy_level with 1 for x-position purposes
prop_df <- prop_df %>%
  mutate(copy_level_plot = if_else(is.na(copy_level), 1, copy_level))

# -----------------------------
# Row labels
# -----------------------------

prop_df <- prop_df %>%
  left_join(genome_counts, by = "taxon", suffix = c("", ".y")) %>%
  mutate(
    genomes     = coalesce(genomes, genomes.y),
    taxon_label = paste0(taxon, " (n=", genomes, ")")
  ) %>%
  select(-ends_with(".y"))

prop_df$protein <- factor(prop_df$protein, levels = protein_list)

# -----------------------------
# Identify proteins whose max proportion across ALL taxa < 0.05
# These will be shown as genome-count text instead of a dot
# -----------------------------

rare_proteins <- prop_df %>%
  group_by(protein) %>%
  summarise(max_prop = max(proportion), .groups = "drop") %>%
  filter(max_prop < 0.05) %>%
  pull(protein)

dot_df  <- prop_df %>% filter(!protein %in% rare_proteins)
text_df <- prop_df %>%
  filter(protein %in% rare_proteins) %>%
  # one representative row per taxon x protein
  filter(copy_level_plot == 1) %>%
  mutate(label = as.character(genomes_with_copy))

# -----------------------------
# Dot spacing: center copy-level dots symmetrically within each column.
# Dots are spaced 0.3 data units apart, centered on the protein integer position.
# -----------------------------

max_copies_per_protein <- dot_df %>%
  group_by(protein) %>%
  summarise(n_levels = max(copy_level_plot), .groups = "drop")

dot_df <- dot_df %>%
  left_join(max_copies_per_protein, by = "protein") %>%
  mutate(
    x_offset = if_else(
      n_levels == 1,
      0,
      (copy_level_plot - 1) * 0.3 - (n_levels - 1) * 0.3 / 2
    ),
    x_pos = as.numeric(protein) + x_offset
  )

# Auto plot width: 1.5 in per protein column + 2.5 in for y-axis labels
plot_width <- 2.5 + 1.5 * length(protein_list)

# -----------------------------
# Plot
# -----------------------------

p <- ggplot(mapping = aes(y = taxon_label)) +

  # --- dots for normal proteins ---
  geom_point(
    data = dot_df,
    aes(
      x     = x_pos,
      color = proportion
    ),
    size = 3
  ) +

  # --- text counts for rare proteins ---
  geom_text(
    data = text_df,
    aes(
      x     = as.numeric(protein),
      label = label
    ),
    size  = 3.5,
    color = "grey40"
  ) +

  scale_color_gradient(
    name   = "Genome proportion",
    low    = "#00C9A7",
    high   = "#FF4D6D",
    limits = c(0, 1)
  ) +

  scale_x_continuous(
    position = "top",
    breaks   = seq_along(protein_list),
    labels   = protein_list,
    expand   = expansion(add = 0.6)
  ) +

  theme_classic(base_size = 14) +

  theme(
    axis.title   = element_blank(),
    axis.text.x  = element_text(angle = 30, hjust = 0),
    axis.line.x  = element_line(),
    axis.line.y  = element_line(),
    plot.margin  = margin(t = 10, r = 10, b = 10, l = 10, unit = "mm")
  ) +

  labs(
    title   = paste("Protein copy distribution across", tax_level),
    caption = "Grey numbers = genome count (protein present in <5% of genomes)"
  )

# -----------------------------
# Save plot
# -----------------------------

dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

plot_height <- 2 + 0.5 * length(unique(prop_df$taxon_label))

ggsave(outfile, p, width = plot_width, height = plot_height, dpi = 300)

message("Saved: ", outfile)
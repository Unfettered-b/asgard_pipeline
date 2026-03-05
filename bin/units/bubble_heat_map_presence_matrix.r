#!/usr/bin/env Rscript

library(tidyverse)

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

# -----------------------------
# Load dataframe
# -----------------------------

df <- read_csv(input_csv, show_col_types = FALSE)

# -----------------------------
# Filter proteins of interest
# -----------------------------

df <- df %>%
  filter(.data[[protein_col]] %in% protein_list)

# -----------------------------
# Count copies per genome
# -----------------------------

copy_counts <- df %>%
  group_by(
    genome = .data[[genome_col]],
    taxon  = .data[[tax_level]],
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
# Total copies per taxon
# -----------------------------

mean_copy <- copy_counts %>%
  group_by(taxon, protein) %>%
  summarise(
    total_copies = sum(copies),
    .groups = "drop"
  )

# -----------------------------
# Fill missing taxon-protein combos
# -----------------------------

mean_copy <- mean_copy %>%
  complete(
    taxon,
    protein = protein_list,
    fill = list(total_copies = 0)
  )

# -----------------------------
# Join genome counts
# -----------------------------

mean_copy <- mean_copy %>%
  left_join(genome_counts, by = "taxon")

# -----------------------------
# Compute mean copy number
# -----------------------------

mean_copy <- mean_copy %>%
  mutate(
    mean_copy_number = total_copies / genomes
  )

# -----------------------------
# Create taxon labels
# -----------------------------

mean_copy <- mean_copy %>%
  mutate(
    taxon_label = paste0(taxon, " (n=", genomes, ")")
  )

# -----------------------------
# Order taxa by first protein
# -----------------------------

order_df <- mean_copy %>%
  filter(protein == protein_list[1]) %>%
  arrange(desc(mean_copy_number))

mean_copy$taxon_label <- factor(
  mean_copy$taxon_label,
  levels = unique(paste0(order_df$taxon, " (n=", order_df$genomes, ")"))
)

# -----------------------------
# Plot heatmap
# -----------------------------

p <- ggplot(mean_copy, aes(x = protein, y = taxon_label)) +
  
  geom_point(
    aes(color = mean_copy_number),
    size = 6
  ) +
  
  scale_color_viridis_c(
    name = "Mean copy number",
    option = "C"
  ) +
  
  theme_classic(base_size = 14) +
  
  theme(
    axis.text.x = element_text(angle = 30, hjust = 1),
    axis.title = element_blank()
  ) +
  
  labs(
    title = paste("Mean copy number across", tax_level)
  )

# -----------------------------
# Save plot
# -----------------------------

dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

plot_height <- 2 + 0.5 * length(unique(mean_copy$taxon_label))

ggsave(outfile, p, width = 6, height = plot_height, dpi = 300)

message("Saved:", outfile)
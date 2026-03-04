#!/usr/bin/env python3

import pandas as pd
from Bio import SeqIO

# ============================================================
# HARD-CODED PATHS
# ============================================================

METADATA_FILE = "/home/anirudh/asgard_pipeline/database/collated/Version1/filtered/85comp10con/protein_file/updated_jan2026_genome_proteins_cp85_con10.csv"
TAXONOMY_FILE = "/home/anirudh/synteny/final_genomes_flat/outputs/gtdbtk.ar53.summary.tsv"
FASTA_FILE = "/home/anirudh/asgard_pipeline/database/collated/Version1/filtered/85comp10con/fasta/v1_cp85_con10.fasta"

PROTEIN_OUTPUT = "/home/anirudh/asgard_pipeline/database/collated/Version1/filtered/85comp10con/protein_file/jan2026_85comp10con_pf.csv"
GENOME_OUTPUT = "/home/anirudh/asgard_pipeline/database/collated/Version1/filtered/85comp10con/genome_file/jan2026_85comp10con_gf.csv"
# ============================================================
# LOAD FILES
# ============================================================

meta = pd.read_csv(METADATA_FILE)
tax = pd.read_csv(TAXONOMY_FILE, sep="\t")

# ============================================================
# PROCESS TAXONOMY FILE
# ============================================================

tax["genome_file"] = tax["user_genome"].str.split("__").str[0]

tax_ranks = tax["classification"].str.split(";", expand=True)

tax["domain"] = tax_ranks[0].str.replace("d__", "", regex=False)
tax["phylum"] = tax_ranks[1].str.replace("p__", "", regex=False)
tax["class"] = tax_ranks[2].str.replace("c__", "", regex=False)
tax["order"] = tax_ranks[3].str.replace("o__", "", regex=False)
tax["family"] = tax_ranks[4].str.replace("f__", "", regex=False)
tax["genus"] = tax_ranks[5].str.replace("g__", "", regex=False)
tax["species"] = tax_ranks[6].str.replace("s__", "", regex=False)

tax = tax[
    [
        "genome_file",
        "domain",
        "phylum",
        "class",
        "order",
        "family",
        "genus",
        "species",
    ]
]

# ============================================================
# CREATE GENOME DATAFRAME
# ============================================================

gene_columns = [
    "locus_tag",
    "ftype",
    "length_bp",
    "gene",
    "EC_number",
    "COG",
    "product",
]

genome_df = meta.drop(columns=gene_columns + ["genome_path"], errors="ignore")

# remove duplicate genome rows (since original file is gene-level)
genome_df = genome_df.drop_duplicates(subset=["genome_file"])

# merge taxonomy
genome_df = genome_df.merge(tax, on="genome_file", how="left")

# ============================================================
# CREATE PROTEIN DATAFRAME
# ============================================================

protein_df = meta[
    [
        "locus_tag",
        "genome_file",
        "ftype",
        "length_bp",
        "gene",
        "EC_number",
        "COG",
        "product",
    ]
].copy()

# ============================================================
# PARSE FASTA FILE
# ============================================================

protein_lengths = {}
protein_headers = {}

for record in SeqIO.parse(FASTA_FILE, "fasta"):

    locus_tag = record.id
    protein_lengths[locus_tag] = len(record.seq)
    protein_headers[locus_tag] = record.description

protein_df["protein_length"] = protein_df["locus_tag"].map(protein_lengths)
protein_df["protein_header"] = protein_df["locus_tag"].map(protein_headers)

# add empty columns
protein_df["predicted_structure"] = ""
protein_df["IPS"] = ""
protein_df['Manual_annotation'] = ""

# reorder columns
protein_df = protein_df[
    [
        "locus_tag",
        "genome_file",
        "protein_length",
        "protein_header",
        "ftype",
        "length_bp",
        "gene",
        "EC_number",
        "COG",
        "product",
        "predicted_structure",
        "IPS",
        "Manual_annotation"
    ]
]

# ============================================================
# EXPORT
# ============================================================

protein_df.to_csv(PROTEIN_OUTPUT, index=False)
genome_df.to_csv(GENOME_OUTPUT, index=False)

print("Protein table written to:", PROTEIN_OUTPUT)
print("Genome table written to:", GENOME_OUTPUT)
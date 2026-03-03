#!/usr/bin/env python3

"""
Extract sequences and CSV rows matching protein IDs.

Inputs:
- snakemake.input.fasta
- snakemake.input.protein_file
- snakemake.input.protein_ids

Outputs:
- snakemake.output.outfasta
- snakemake.output.protein_csv
"""

from Bio import SeqIO
import pandas as pd
import sys


# -------------------------------
# Snakemake I/O
# -------------------------------

FASTA_FILE = snakemake.input.fasta
CSV_FILE = snakemake.input.protein_file
IDS_FILE = snakemake.input.protein_ids

OUT_FASTA = snakemake.output.outfasta
OUT_CSV = snakemake.output.protein_csv


# -------------------------------
# Load Protein IDs
# -------------------------------

print("📥 Loading protein IDs...")

with open(IDS_FILE) as f:
    protein_ids = set(line.strip() for line in f if line.strip())

if not protein_ids:
    sys.exit("❌ No protein IDs found. Stopping.")

print(f"🔢 {len(protein_ids)} protein IDs loaded.")


# -------------------------------
# Filter FASTA
# -------------------------------

print("🧬 Filtering FASTA sequences...")

matched_records = []

for record in SeqIO.parse(FASTA_FILE, "fasta"):
    # record.id = first word of header (before whitespace)
    if record.id in protein_ids:
        matched_records.append(record)

if not matched_records:
    print("⚠️ No matching FASTA records found.")

SeqIO.write(matched_records, OUT_FASTA, "fasta")

print(f"✅ FASTA written → {OUT_FASTA}")


# -------------------------------
# Filter CSV
# -------------------------------

print("📊 Filtering CSV file...")

df = pd.read_csv(CSV_FILE)

# Assumes column name is 'protein'
if "locus_tag" not in df.columns:
    sys.exit("❌ CSV does not contain a 'locus_tag' column.")

filtered_df = df[df["locus_tag"].isin(protein_ids)]

if filtered_df.empty:
    print("⚠️ No matching rows in CSV.")

filtered_df.to_csv(OUT_CSV, index=False)

print(f"✅ CSV written → {OUT_CSV}")

print("🎉 Extraction complete.")
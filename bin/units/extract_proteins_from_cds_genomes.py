#!/usr/bin/env python3

"""
Prokka Protein Extractor (Refactored - pathlib native)

Scans a folder of Prokka genome output directories and extracts:
1. Protein summary CSV
2. Combined FASTA file

Arguments:
    version
    folder_path
    mode (filtered/full)
    --completion
    --contamination
    --log

Author: Anirudh
"""

import sys
import argparse
import logging
from pathlib import Path

import pandas as pd
from Bio import SeqIO


# ============================================================
# HARD-CODED OUTPUT PATH
# ============================================================
OUTPUT_FOLDER = Path("/path/to/output_directory")


# ============================================================
# LOGGING SETUP
# ============================================================
def setup_logging(log_file: Path):
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    # Clear previous handlers (important in modular runs)
    if logger.hasHandlers():
        logger.handlers.clear()

    formatter = logging.Formatter(
        "%(asctime)s | %(levelname)s | %(message)s",
        "%Y-%m-%d %H:%M:%S"
    )

    # File handler
    fh = logging.FileHandler(log_file)
    fh.setFormatter(formatter)
    logger.addHandler(fh)

    # Console handler
    ch = logging.StreamHandler(sys.stdout)
    ch.setFormatter(formatter)
    logger.addHandler(ch)


# ============================================================
# QUALITY FILTER
# ============================================================
def passes_quality(genome_path: Path,
                   completion_thresh: float,
                   contamination_thresh: float) -> bool:

    quality_file = genome_path / "genome_quality.tsv"

    if not quality_file.exists():
        logging.warning(f"No genome_quality.tsv found in {genome_path.name}")
        return False

    try:
        df = pd.read_csv(quality_file, sep="\t")
        completion = float(df.loc[0, "completion"])
        contamination = float(df.loc[0, "contamination"])
    except Exception as e:
        logging.error(f"Error reading quality file in {genome_path.name}: {e}")
        return False

    return completion >= completion_thresh and contamination <= contamination_thresh


# ============================================================
# MAIN LOGIC
# ============================================================
def main():

    parser = argparse.ArgumentParser(
        description="Extract proteins from Prokka output folders."
    )

    parser.add_argument("version", help="Pipeline version")
    parser.add_argument("folder_path", type=Path,
                        help="Folder containing Prokka genome directories")
    parser.add_argument("mode", choices=["filtered", "full"],
                        help="Extraction mode")
    parser.add_argument("--completion", type=float,
                        help="Completion threshold (required if filtered)")
    parser.add_argument("--contamination", type=float,
                        help="Contamination threshold (required if filtered)")
    parser.add_argument("--log", type=Path, required=True,
                        help="Log file path")

    args = parser.parse_args()

    OUTPUT_FOLDER.mkdir(parents=True, exist_ok=True)
    setup_logging(args.log)

    logging.info("========== RUN START ==========")
    logging.info(f"Version: {args.version}")
    logging.info(f"Input folder: {args.folder_path.resolve()}")
    logging.info(f"Mode: {args.mode}")
    logging.info(f"Completion threshold: {args.completion}")
    logging.info(f"Contamination threshold: {args.contamination}")
    logging.info(f"Output folder: {OUTPUT_FOLDER.resolve()}")

    if args.mode == "filtered":
        if args.completion is None or args.contamination is None:
            logging.error("Filtered mode requires --completion and --contamination.")
            sys.exit(1)

    if not args.folder_path.exists():
        logging.error(f"Input folder does not exist: {args.folder_path}")
        sys.exit(1)

    genome_count = 0
    protein_count = 0
    protein_records = []

    combined_fasta_path = OUTPUT_FOLDER / f"combined_proteins_{args.version}.faa"
    csv_output_path = OUTPUT_FOLDER / f"proteins_summary_{args.version}.csv"

    with combined_fasta_path.open("w") as fasta_out:

        for genome_path in sorted(args.folder_path.iterdir()):

            if not genome_path.is_dir():
                continue

            # Filter if required
            if args.mode == "filtered":
                if not passes_quality(
                        genome_path,
                        args.completion,
                        args.contamination):
                    logging.info(f"Filtered out genome: {genome_path.name}")
                    continue

            faa_files = list(genome_path.glob("*.faa"))

            if not faa_files:
                logging.warning(f"No .faa file found in {genome_path.name}")
                continue

            faa_path = faa_files[0]
            genome_count += 1
            logging.info(f"Processing genome: {genome_path.name}")

            for record in SeqIO.parse(faa_path, "fasta"):

                protein_id = record.id
                header = record.description
                length = len(record.seq)

                protein_records.append({
                    "protein_id": protein_id,
                    "source_genome": genome_path.name,
                    "header": header,
                    "length": length
                })

                # Write to combined FASTA
                record.id = f"{protein_id}|{genome_path.name}"
                record.description = ""
                SeqIO.write(record, fasta_out, "fasta")

                protein_count += 1

    # Create dataframe
    df = pd.DataFrame(protein_records)
    df.to_csv(csv_output_path, index=False)

    logging.info("========== RUN SUMMARY ==========")
    logging.info(f"Number of genomes scanned: {genome_count}")
    logging.info(f"Number of proteins found: {protein_count}")
    logging.info(f"CSV output: {csv_output_path}")
    logging.info(f"FASTA output: {combined_fasta_path}")
    logging.info("========== RUN COMPLETE ==========")


if __name__ == "__main__":
    main()
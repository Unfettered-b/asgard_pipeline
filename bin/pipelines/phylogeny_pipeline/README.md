# Phylogeny Pipeline

`bin/pipelines/phylogeny_pipeline/Snakefile` continues from a reviewed extraction run. It validates reviewed FASTA input, optionally extends/deduplicates the sequence set, builds a multiple sequence alignment, trims it, infers a tree, and uploads tree/dataset files to iTOL.

## Main rules and sub-rules

This pipeline is self-contained in its `Snakefile` and does not include separate `.smk` sub-rule files.

| Rule | What it does |
| --- | --- |
| `assert_review_inputs` | Verifies required reviewed FASTA inputs exist. |
| `make_rev_csv` | Filters the extraction CSV to rows present in the reviewed FASTA. |
| `add_fasta_sequences` | Appends configured additional FASTA sequences to the reviewed set. |
| `cdhit_100` | Removes exact duplicate sequences with CD-HIT at 100% identity. |
| `build_final_metadata_csv` | Reconciles the final nonredundant FASTA with reviewed metadata. |
| `align` | Aligns proteins using configured FAMSA, MAFFT, or MUSCLE settings. |
| `trim` | Trims the alignment according to configured trimming method/options. |
| `run_phylogeny` | Infers the final tree with the configured phylogenetic method/options. |
| `msa_to_itol` | Converts the alignment to an iTOL MSA dataset. |
| `table2itol` | Converts metadata tables into iTOL annotation datasets. |
| `upload_to_itol` | Uploads the tree and annotation datasets to iTOL. |
| `link_log_file` | Links the pipeline log into the result directory. |

## Python scripts called

| Script | Called by | Purpose |
| --- | --- | --- |
| `bin/units/add_fasta_sequences.py` | `add_fasta_sequences` | Combines the reviewed FASTA with configured extra FASTA files. |
| `bin/units/build_final_metadata_csv.py` | `build_final_metadata_csv` | Builds metadata for the final FASTA sequence set. |
| `bin/units/msa_to_itol_dataset.py` | `msa_to_itol` | Converts the alignment into an iTOL-compatible MSA annotation file. |

## Non-Python helpers called

The pipeline also calls external alignment/tree tools (FAMSA, MAFFT, MUSCLE, trimming tools, IQ-TREE/FastTree depending on config), `table2itol.R` for iTOL dataset generation, and `itol_upload.sh` for iTOL upload.

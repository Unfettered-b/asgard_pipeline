# Database Updation Pipeline

`bin/pipelines/updation/Snakefile` updates the local genome/protein database. It prepares genome download lists, downloads/extracts/link genomes, runs quality/taxonomy/annotation tools, and collates genome/protein summary tables.

## Main rules and sub-rules

This pipeline is self-contained in its `Snakefile` and does not include separate `.smk` sub-rule files.

| Rule | What it does |
| --- | --- |
| `check_database` | Checks whether the expected database inputs/outputs are present. |
| `get_summary` | Retrieves or prepares metadata summaries used for genome selection. |
| `prepare_download_list` | Creates the list of genomes to download. |
| `download_genomes` | Downloads selected genomes. |
| `extract_genomes` | Extracts downloaded genome archives. |
| `link_run_genomes` | Links genomes into the current run workspace. |
| `add_manual_genome` | Adds manually supplied genomes into the run. |
| `checkm2` | Runs CheckM2 quality assessment. |
| `link_filtered` | Links genomes that pass quality/filter criteria. |
| `skder` | Runs sketching/dereplication support steps for genomes. |
| `gtdbtk` | Runs GTDB-Tk taxonomy classification. |
| `taxa_counts` | Plots taxonomic count summaries. |
| `update_master_checkm2` | Updates the master CheckM2 quality table. |
| `update_master_gtdbtk` | Updates the master GTDB-Tk taxonomy table. |
| `bakta` | Runs Bakta genome annotation. |
| `interproscan` | Runs InterProScan for an annotated genome/proteome. |
| `all_interproscan` | Aggregates completion of InterProScan jobs. |
| `collate_proteins` | Collates protein FASTA/annotation data from run outputs. |
| `make_genome_csv` | Builds the updated genome metadata CSV. |
| `make_protein_csv` | Builds the updated protein metadata CSV. |

## Python scripts called

No standalone Python scripts are invoked directly by the current `Snakefile`. Most processing is performed through shell commands and external tools.

## Non-Python helpers called

The workflow calls external bioinformatics tools such as CheckM2, GTDB-Tk, Bakta, InterProScan, and R script `plot_taxa_counts.r` for taxonomy-count plots.

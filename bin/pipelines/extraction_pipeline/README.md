# Extraction Pipeline

`bin/pipelines/extraction_pipeline/Snakefile` builds an exploratory protein set for a configured `run.protein_name`. It selects one extraction mode, then always runs exploration, sequence-similarity-network (SSN), plotting, and optional iTOL upload targets.

## Included sub-rule files

| Sub-rule file | When it is used | What it does |
| --- | --- | --- |
| `rules/parse_ips.smk` | Included when `modes.parse_ips.enabled` is true. | Searches an aggregated InterProScan parquet for configured signature descriptions, writes matching protein IDs/domain tables/iTOL domain files, then extracts matching sequences and metadata. |
| `rules/hmmsearch.smk` | Included when `modes.hmmsearch.enabled` is true. | Uses configured InterPro accessions from a raw InterPro parquet to identify matching proteins, build iTOL domain data, and extract FASTA/CSV records. |
| `rules/from_manual.smk` | Included when `modes.from_manual.enabled` is true. | Filters a curated protein metadata table by manual annotation and optional taxonomy, exports FASTA/CSV/ID files, and parses InterPro annotations for the selected IDs. |
| `rules/from_fasta_and_csv.smk` | Included when `modes.from_fasta_csv.enabled` is true. | Copies user-provided FASTA, CSV, and iTOL domain inputs into the standard extraction output layout. |
| `rules/exploration.smk` | Always included after the extraction mode. | Produces length plots, taxon counts, a quick FastTree tree, iTOL color strips, annotation datasets, optional MAD rooting, and optional iTOL upload. |
| `rules/ssn_3.smk` | Always included after the extraction mode. | Deduplicates sequences, computes all-vs-all similarities, filters SSN edges at configured bitscore thresholds, exports Cytoscape files, annotates nodes, clusters components, and optionally copies SSN outputs to Windows. |
| `rules/arcog_psiblast.smk` | Present but not included by the main Snakefile. | Prototype rules for creating arCOG ID sets, retrieving proteins, making a BLAST database, and running PSI-BLAST. |
| `rules/orthogroups.smk` | Present but not included by the main Snakefile. | Preliminary OrthoFinder workflow that links filtered proteomes and runs OrthoFinder. |
| `rules/old/ssn.smk`, `rules/old/ssn_2.smk` | Archived only. | Older SSN implementations replaced by `rules/ssn_3.smk`. |

## Python scripts called

| Script | Called by | Purpose |
| --- | --- | --- |
| `bin/units/parse_ips4.py` | `rules/parse_ips.smk` (`parse_ips`) | Queries aggregated/raw InterProScan parquet inputs for configured search terms and writes selected protein IDs plus domain/iTOL annotation outputs. |
| `bin/units/get_fasta_csv_from_ids.py` | `rules/parse_ips.smk` and `rules/hmmsearch.smk` (`merge_file`) | Uses selected IDs to subset the master FASTA and protein/genome metadata into the extraction FASTA and CSV outputs. |
| `bin/units/parse_ips_acc.py` | `rules/hmmsearch.smk` (`ips_acc_parse`) | Finds proteins matching configured InterPro accessions in the raw parquet and emits IDs, matching domain TSV, and iTOL domain files. |
| `bin/units/from_manual.py` | `rules/from_manual.smk` (`from_manual`) | Filters manually annotated protein metadata and extracts the corresponding sequences and CSV rows. |
| `bin/units/parse_ips_manuall_annot_ver.py` | `rules/from_manual.smk` (`parse_ips`) | Builds domain protein tables and iTOL domain annotations for manually selected protein IDs. |
| `bin/units/plot_lengths.py` | `rules/exploration.smk` (`length_histogram`) | Plots selected protein length distributions. |
| `bin/units/generate_colorstrip.py` | `rules/exploration.smk` (`itol_colorstrip`) | Converts metadata into an iTOL color-strip dataset. |
| `bin/units/get_annotation_csv.py` | `rules/exploration.smk` (`df_for_annotation`) | Prepares a table of annotation columns for iTOL dataset generation. |
| `bin/units/msa_to_itol_dataset.py` | `rules/exploration.smk` (`msa_to_itol`) | Converts an alignment into an iTOL-compatible multiple-sequence-alignment dataset. |
| `bin/units/ssn_cluster.py` | `rules/ssn_3.smk` (`ssn_cluster`) | Assigns SSN nodes to connected components/clusters from filtered edge and node tables. |

## Non-Python helpers called

The pipeline also calls R scripts (`bubble_heat_map_presence_table.r`, `coencoding_heatmap.r`, `taxon_violin_plot.r`, `plot_taxa_counts.r`, `table2itol.R`) and shell helpers (`fasttree_pipeline.sh`, `itol_upload.sh`, `ssn_cdhit.sh`, `ssn_search.sh`, `ssn_nodes.sh`, `ssn_filter.sh`, `ssn_cytoscape.sh`, `ssn_annotate.sh`). These produce plots, phylogenetic helper files, iTOL uploads, and SSN intermediates.

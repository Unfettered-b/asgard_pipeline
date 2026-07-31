# Extraction Pipeline

`bin/pipelines/extraction_pipeline/Snakefile` builds a standardized exploratory protein set for the configured `run.protein_name`. The main Snakefile chooses exactly one input/extraction mode, then always runs the shared exploration, plotting, and sequence-similarity-network (SSN) stages.

## Main Snakefile flow

| Stage | Rules or includes | What happens |
| --- | --- | --- |
| Configuration and directories | top-level Python in `Snakefile` | Reads the Snakemake config, creates `database/protein_sets/<protein>/<run_id>/`, and defines the exploration, phylogeny, SSN, log, and benchmark directories. |
| Extraction-mode dispatch | `include: "rules/parse_ips.smk"`, `include: "rules/hmmsearch.smk"`, `include: "rules/from_manual.smk"`, or `include: "rules/from_fasta_and_csv.smk"` | Selects the first enabled mode under `config["modes"]`. Only one extraction mode is included for a run. |
| Shared exploration | `include: "rules/exploration.smk"` | Adds quality-control plots, a quick exploratory tree, iTOL datasets, and optional iTOL upload for the unreviewed protein set. |
| Shared SSN | `include: "rules/ssn_3.smk"` | Adds the current SSN workflow: CD-HIT deduplication, all-vs-all search, filtered network exports, node annotations, clustering, and optional copy-to-Windows support. |
| Top-level plotting | `protein_copy_heatmap_unreviewed`, `protein_coencoding_heatmap_unreviewed`, `plot_taxa` | Builds additional R-based visual summaries from the unreviewed extraction CSV. |
| Final target aggregation | `rule all` | Requests the pipeline log link, sequence/SSN outputs, exploration plots, taxon counts, quick tree, and optional upload/copy targets. |

## Sub-rule file: `rules/parse_ips.smk`

This mode is used when `modes.parse_ips.enabled` is true. It starts from InterProScan parquet data and finds proteins whose domain/signature descriptions match the configured search terms.

| Rule | Inputs | Outputs | Helper scripts | What it does |
| --- | --- | --- | --- | --- |
| `parse_ips` | Aggregated InterPro database parquet (`inputs.database`) and raw InterPro parquet (`inputs.raw_database`) | `<protein>_domain_proteins.tsv`, `<protein>.ids`, `<protein>_itol_domains/` | `bin/units/parse_ips4.py` | Searches InterProScan records using `modes.parse_ips.search.search_string` and regex/string settings, writes matching protein IDs, protein-domain associations, and iTOL domain annotation files. |
| `merge_file` | Master protein CSV, master FASTA, selected IDs, genome metadata CSV | `<protein>.unr.fasta`, `<protein>.unr.csv` | `bin/units/get_fasta_csv_from_ids.py` | Subsets the master FASTA and metadata to matching IDs, optionally filters hypothetical proteins, applies configured taxonomy filters, and writes the unreviewed extraction FASTA/CSV. |

## Sub-rule file: `rules/hmmsearch.smk`

This extraction mode is used when `modes.hmmsearch.enabled` is true. Despite the file name, this sub-rule parses configured InterPro accessions from a raw InterProScan parquet and then extracts matching records.

| Rule | Inputs | Outputs | Helper scripts | What it does |
| --- | --- | --- | --- | --- |
| `ips_acc_parse` | Raw InterPro parquet (`inputs.raw_database`) | `<protein>.ids`, `<protein>_domain_proteins.tsv`, `<protein>_itol_domains/` | `bin/units/parse_ips_acc.py` | Finds proteins carrying configured accession groups (`modes.hmmsearch.acc_groups`) and builds the same ID/domain/iTOL-domain products used by downstream rules. |
| `merge_file` | Master protein CSV, master FASTA, selected IDs, genome metadata CSV | `<protein>.unr.fasta`, `<protein>.unr.csv` | `bin/units/get_fasta_csv_from_ids.py` | Extracts selected sequences and metadata into the standard unreviewed FASTA/CSV outputs. |

## Sub-rule file: `rules/from_manual.smk`

This extraction mode is used when `modes.from_manual.enabled` is true. It starts from an existing manually curated annotation table rather than discovering proteins from InterPro terms.

| Rule | Inputs | Outputs | Helper scripts | What it does |
| --- | --- | --- | --- | --- |
| `from_manual` | Protein metadata CSV, genome metadata CSV, collated FASTA | `<protein>.ids`, `<protein>.unr.fasta`, `<protein>.unr.csv` | `bin/units/from_manual.py` | Filters the protein table by configured manual annotation values and optional `taxon_level`/`taxon_filter`, then extracts matching IDs, sequences, and metadata. |
| `parse_ips` | Raw InterPro parquet and the selected ID file | `<protein>_domain_proteins.tsv`, `<protein>_itol_domains/` | `bin/units/parse_ips_manuall_annot_ver.py` | Adds domain/protein associations and iTOL domain annotation files for the manually selected proteins. |

## Sub-rule file: `rules/from_fasta_and_csv.smk`

This extraction mode is used when `modes.from_fasta_csv.enabled` is true. It assumes the sequence set and metadata were prepared outside the pipeline.

| Rule | Inputs | Outputs | Helper scripts | What it does |
| --- | --- | --- | --- | --- |
| `copy_inputs` | User-supplied CSV, FASTA, and iTOL domain directory from `modes.from_fasta_csv` | `<protein>.unr.fasta`, `<protein>.unr.csv`, `<protein>_domain_proteins.tsv`, `<protein>_itol_domains/` | shell commands only | Copies the provided FASTA/CSV/domain files into the extraction output layout and creates a simple domain TSV that assigns every CSV row to the configured protein name. |

## Sub-rule file: `rules/exploration.smk`

This file is always included after the extraction mode. It operates on `<protein>.unr.fasta` and `<protein>.unr.csv` to produce exploratory plots, a fast preliminary tree, and iTOL-ready annotation datasets.

| Rule | Inputs | Outputs | Helper scripts | What it does |
| --- | --- | --- | --- | --- |
| `length_histogram` | Unreviewed FASTA | `<protein>_length_hist.png` | `bin/units/plot_lengths.py` | Plots the distribution of extracted protein sequence lengths. |
| `taxa_counts` | Unreviewed CSV | `<protein>_taxa_count.svg` | `bin/units/plot_taxa_counts.r` | Deduplicates genomes and plots class-level bars split by order. |
| `exploratory_fasttree` | Unreviewed FASTA | alignment/tree files prefixed `<protein>_unr_fasttree` | `bin/units/fasttree_pipeline.sh` | Runs a quick alignment/tree workflow for initial inspection. |
| `itol_colorstrip` | Unreviewed CSV | `<protein>_colorstrip.txt` | `bin/units/generate_colorstrip.py` | Creates an iTOL color-strip dataset from metadata. |
| `df_for_annotation` | Unreviewed CSV | annotation dataframe for iTOL | `bin/units/get_annotation_csv.py` | Selects/normalizes configured metadata columns before iTOL conversion. |
| `msa_to_itol` | Exploratory alignment | `itol_msa.txt` | `bin/units/msa_to_itol_dataset.py` | Converts the exploratory MSA to an iTOL MSA dataset. |
| `table2itol` | Annotation dataframe | iTOL annotation files and `annotation.done.flag` | `bin/units/table2itol.R` | Converts tabular metadata into iTOL datasets such as labels, colors, symbols, gradients, or domains. |
| `madroot` | Exploratory tree | rooted exploratory tree | `madRoot` external command | Optionally roots the quick tree when `phylogeny.madroot` is enabled. |
| `upload_to_itol` | Tree, color strip, annotation files, MSA dataset, domain annotations | `<protein>_fast_itol_uploaded.flag` | `bin/units/itol_upload.sh` | Optionally uploads the exploratory tree and datasets to iTOL. |

## Sub-rule file: `rules/ssn_3.smk`

This is the active SSN workflow. It is always included and consumes the unreviewed FASTA/CSV created by the selected extraction mode.

| Rule | Inputs | Outputs | Helper scripts | What it does |
| --- | --- | --- | --- | --- |
| `ssn_cdhit` | `<protein>.unr.fasta` | `<protein>.nr.fasta`, CD-HIT cluster file | `bin/units/ssn_cdhit.sh` | Deduplicates proteins using CD-HIT with the configured identity threshold. |
| `ssn_search` | Nonredundant FASTA | `<protein>.similarities.tsv` | `bin/units/ssn_search.sh` | Performs the all-vs-all sequence similarity search and writes pairwise hit statistics. |
| `ssn_nodes` | Nonredundant FASTA | `<protein>.nodes.tsv` | `bin/units/ssn_nodes.sh` | Creates SSN node metadata, including sequence lengths. |
| `ssn_filter` | Similarity TSV and node table | `<protein>.bs<bitscore>.edges.tsv` | `bin/units/ssn_filter.sh` | Filters edges by configured bitscore, coverage, and e-value thresholds for each requested SSN level. |
| `ssn_cytoscape` | Filtered edges and nodes | Cytoscape `.sif` and `.ea` files | `bin/units/ssn_cytoscape.sh` | Converts filtered edges into Cytoscape network and edge-attribute formats. |
| `ssn_annotate` | Node table and unreviewed CSV | `<protein>.tax.tsv` | `bin/units/ssn_annotate.sh` | Adds taxonomy/metadata annotations to SSN nodes. |
| `ssn_cluster` | Nodes and all filtered edge tables | `<protein>.clusters.csv` | `bin/units/ssn_cluster.py` | Assigns nodes to connected components/clusters across the configured SSN thresholds. |
| `ssn_network` | Aggregated SSN outputs | no new file; aggregate rule | none | Collects all network, annotation, cluster, and Cytoscape products for Snakemake targeting. |
| `copy_outs_to_windows` | SSN outputs | `copied_to_windows.flag` | shell commands only | Optionally copies finished SSN products to a configured Windows-accessible directory. |

## Sub-rule file: `rules/arcog_psiblast.smk` (prototype, not included by default)

This file is present in the extraction rules directory but the main Snakefile does not include it. It documents an unfinished/prototype arCOG PSI-BLAST workflow.

| Rule | Inputs | Outputs | Helper scripts | What it does |
| --- | --- | --- | --- | --- |
| `create_arcog_id_set` | arCOG/ASCOG metadata and config filters | ID set | inline Python | Builds a selected arCOG/ASCOG identifier set from config-driven filters. |
| `retrieve_proteins_from_ids` | ID set and protein sources | retrieved FASTA/metadata | inline Python/shell | Retrieves proteins for the selected arCOG IDs. |
| `make_blastdb` | Protein FASTA | BLAST database files | `makeblastdb` external command | Builds a BLAST database for PSI-BLAST. |
| `psiblast` | Query sequences and BLAST database | PSI-BLAST output | `psiblast` external command | Searches the database iteratively using PSI-BLAST. |

## Sub-rule file: `rules/orthogroups.smk` (preliminary, not included by default)

This file is present but not included by the main extraction Snakefile. It contains preliminary OrthoFinder support.

| Rule | Inputs | Outputs | Helper scripts | What it does |
| --- | --- | --- | --- | --- |
| `link_proteomes` | Filtered Bakta proteomes | linked OrthoFinder input directory marker | inline Python | Symlinks selected `.faa` proteomes into an OrthoFinder input folder. |
| `orthofinder` | Linked proteome directory | `OrthoFinder.done` marker and OrthoFinder results | `orthofinder` external command | Runs OrthoFinder on the linked proteomes. |

## Archived sub-rule files: `rules/old/ssn.smk` and `rules/old/ssn_2.smk`

These files are retained for historical reference and are not included by the main Snakefile.

| File | What it contains | Replacement |
| --- | --- | --- |
| `rules/old/ssn.smk` | A monolithic SSN workflow around `bin/units/run_ssn.sh`, plus optional copy-to-Windows support. | Replaced by the rule-by-rule workflow in `rules/ssn_3.smk`. |
| `rules/old/ssn_2.smk` | An older expanded SSN workflow with CD-HIT/search/filter/Cytoscape/annotation/cluster rules. | Replaced by `rules/ssn_3.smk`, which adds node generation and updated output aggregation. |

## Top-level R plotting rules in `Snakefile`

These rules live in the main extraction Snakefile rather than a sub-rule file and run after the unreviewed CSV exists.

| Rule | R file | Inputs and outputs | What the R file does |
| --- | --- | --- | --- |
| `protein_copy_heatmap_unreviewed` | `bin/units/bubble_heat_map_presence_table.r` | Reads `<protein>.unr.csv`; writes `plots/<protein>/copy_heatmap_<level>.unr.svg` for configured taxonomic levels. | Filters rows to configured proteins, counts per-genome copy number by taxon, computes the proportion of genomes at each copy level, orders taxa by hierarchy, and plots bubble heatmaps. Rare proteins are shown as labels rather than nearly invisible dots. |
| `protein_coencoding_heatmap_unreviewed` | `bin/units/coencoding_heatmap.r` | Reads `<protein>.unr.csv`; writes `coencoding_abs.unr.svg` and `coencoding_cond.unr.svg`. | Converts genome/protein presence to a wide matrix, computes absolute co-encoding `P(A and B) / N` and conditional co-encoding `P(B | A)`, optionally facets by a metadata group, clusters protein order, and renders paired heatmaps. |
| `plot_taxa` | `bin/units/taxon_violin_plot.r` | Reads `<protein>.unr.csv`; writes `protein_length_vs_<level>.svg` for configured taxonomic levels. | Builds violin/box/beeswarm plots for a chosen numeric column, usually protein length, across taxonomic levels. It supports metadata filtering, dual group comparisons, explicit y-axis limits, median-based taxon ordering, and count labels. |

## R files called from included sub-rules

| R file | Called by | What it does |
| --- | --- | --- |
| `bin/units/plot_taxa_counts.r` | `rules/exploration.smk` / `taxa_counts` | Reads the extraction CSV, deduplicates rows by `genome_file`, counts genomes by `class` and `order`, assigns class/order color palettes, and writes a stacked bar chart with per-class total labels. |
| `bin/units/table2itol.R` | `rules/exploration.smk` / `table2itol` | Converts tabular metadata into iTOL-compatible dataset files. The script supports identifiers/labels, label backgrounds, symbols, gradients, simple bars, binary data, domains, templates, separators, missing-value handling, and output-directory options. |

## Python scripts called by the active extraction workflow

| Script | Called by | Purpose |
| --- | --- | --- |
| `bin/units/parse_ips4.py` | `rules/parse_ips.smk` / `parse_ips` | Queries aggregated/raw InterProScan parquet inputs for configured search terms and writes selected protein IDs plus domain/iTOL annotation outputs. |
| `bin/units/get_fasta_csv_from_ids.py` | `rules/parse_ips.smk` and `rules/hmmsearch.smk` / `merge_file` | Uses selected IDs to subset the master FASTA and protein/genome metadata into extraction FASTA and CSV outputs. |
| `bin/units/parse_ips_acc.py` | `rules/hmmsearch.smk` / `ips_acc_parse` | Finds proteins matching configured InterPro accessions in the raw parquet and emits IDs, matching domain TSV, and iTOL domain files. |
| `bin/units/from_manual.py` | `rules/from_manual.smk` / `from_manual` | Filters manually annotated protein metadata and extracts the corresponding sequences and CSV rows. |
| `bin/units/parse_ips_manuall_annot_ver.py` | `rules/from_manual.smk` / `parse_ips` | Builds domain protein tables and iTOL domain annotations for manually selected protein IDs. |
| `bin/units/plot_lengths.py` | `rules/exploration.smk` / `length_histogram` | Plots selected protein length distributions. |
| `bin/units/generate_colorstrip.py` | `rules/exploration.smk` / `itol_colorstrip` | Converts metadata into an iTOL color-strip dataset. |
| `bin/units/get_annotation_csv.py` | `rules/exploration.smk` / `df_for_annotation` | Prepares a table of annotation columns for iTOL dataset generation. |
| `bin/units/msa_to_itol_dataset.py` | `rules/exploration.smk` / `msa_to_itol` | Converts an alignment into an iTOL-compatible multiple-sequence-alignment dataset. |
| `bin/units/ssn_cluster.py` | `rules/ssn_3.smk` / `ssn_cluster` | Assigns SSN nodes to connected components/clusters from filtered edge and node tables. |

## Shell helpers and external commands called by the active extraction workflow

| Helper or command | Called by | What it does |
| --- | --- | --- |
| `bin/units/fasttree_pipeline.sh` | `rules/exploration.smk` / `exploratory_fasttree` | Runs the quick tree-building path used for extraction exploration. |
| `madRoot` | `rules/exploration.smk` / `madroot` | Roots the exploratory tree when configured. |
| `bin/units/itol_upload.sh` | `rules/exploration.smk` / `upload_to_itol` | Uploads trees and iTOL dataset files. |
| `bin/units/ssn_cdhit.sh` | `rules/ssn_3.smk` / `ssn_cdhit` | Wraps CD-HIT sequence deduplication. |
| `bin/units/ssn_search.sh` | `rules/ssn_3.smk` / `ssn_search` | Runs the pairwise sequence-similarity search. |
| `bin/units/ssn_nodes.sh` | `rules/ssn_3.smk` / `ssn_nodes` | Generates node tables from FASTA records. |
| `bin/units/ssn_filter.sh` | `rules/ssn_3.smk` / `ssn_filter` | Filters similarity hits into SSN edge tables. |
| `bin/units/ssn_cytoscape.sh` | `rules/ssn_3.smk` / `ssn_cytoscape` | Exports SSN edge files to Cytoscape formats. |
| `bin/units/ssn_annotate.sh` | `rules/ssn_3.smk` / `ssn_annotate` | Adds metadata/taxonomy annotations to SSN nodes. |

# Selection Pressure Pipeline

`bin/pipelines/selection_pressure_pipeline/Snakefile` prepares codon alignments for selected proteins, runs configured HyPhy selection tests, parses/analyzes the results, and prepares iTOL annotation outputs.

## Main rules and sub-rules

This pipeline is self-contained in its `Snakefile` and does not include separate `.smk` sub-rule files.

| Rule | What it does |
| --- | --- |
| `subset_annotations` | Selects metadata rows for the configured annotations/proteins. |
| `index_genomes` | Builds an index over configured genome sequence files for downstream extraction. |
| `extract_sequences` | Extracts nucleotide/protein sequences for selected hits. |
| `filter_length_outliers` | Removes sequence length outliers before alignment/selection analysis. |
| `selection_prep` | Prepares codon-aware alignment inputs and tree files. |
| `trim_codon_alignment` | Trims codon alignments prior to HyPhy. |
| `hyphy_fel` | Runs HyPhy FEL when enabled. |
| `hyphy_meme` | Runs HyPhy MEME when enabled. |
| `hyphy_fubar` | Runs HyPhy FUBAR when enabled. |
| `hyphy_absrel` | Runs HyPhy aBSREL when enabled. |
| `hyphy_slac` | Runs HyPhy SLAC when enabled. |
| `parse_hyphy` | Parses HyPhy JSON outputs into tabular summaries. |
| `analyze_hyphy` | Produces downstream summaries/plots from parsed HyPhy data. |
| `merge_protein_metadata` | Joins selection-pressure results with protein metadata. |
| `table2itol` | Converts result tables into iTOL annotation datasets. |
| `upload_main_tree_to_itol` | Uploads the tree and datasets to iTOL. |

## Python scripts called

| Script | Called by | Purpose |
| --- | --- | --- |
| `bin/units/subset_annotations.py` | `subset_annotations` | Filters the protein annotation table to configured annotation values. |
| `bin/units/index_genomes.py` | `index_genomes` | Creates lookup indexes for genome files used in sequence extraction. |
| `bin/units/extract_sequences.py` | `extract_sequences` | Retrieves selected coding/protein sequences from indexed genomes. |
| `bin/units/filter_length_outliers.py` | `filter_length_outliers` | Removes sequences outside configured length thresholds. |
| `bin/units/trim_codon_aln.py` | `trim_codon_alignment` | Trims codon alignments while preserving reading-frame structure. |
| `bin/units/hyphy_parser.py` | `parse_hyphy` | Converts HyPhy JSON/result files into CSV/TSV summaries. |
| `bin/units/hyphy_analysis.py` | `analyze_hyphy` | Summarizes parsed HyPhy results and generates downstream analysis artifacts. |
| `bin/units/merge_protein_metadata.py` | `merge_protein_metadata` | Merges selection results with protein metadata for annotation/reporting. |

## Non-Python helpers called

The workflow uses `selection_prep.sh` to prepare selection inputs, HyPhy command-line tools for model tests, `table2itol.R` for iTOL datasets, and `itol_upload.sh` for upload.

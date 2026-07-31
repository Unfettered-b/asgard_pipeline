# Synteny Pipeline

`bin/pipelines/synteny_pipeline/Snakefile` builds gene-neighborhood/synteny views for configured proteins. It can start from an existing folder of selected proteins or subset a database, choose representative genomes, extract/annotate GenBank neighborhoods, cluster neighborhoods, classify functional bins, and generate clinker plots plus summary figures.

## Included sub-rule files

| Sub-rule file | When it is used | What it does |
| --- | --- | --- |
| `rules/from_existing_folder.smk` | Included by the main Snakefile. | Placeholder/extension point for starting from an existing protein folder; currently contains no active rules. |
| `rules/from_database.smk` | Included by the main Snakefile. | Provides `get_data_from_database`, which subsets the master protein table to configured gene-neighborhood protein sets. |

## Main rules

| Rule | What it does |
| --- | --- |
| `link_log_file` | Links the run log into the synteny output directory. |
| `top_genome_by_quality_per_class` | Selects the best-quality genome per class using quality metrics. |
| `top_genome_per_class` | Selects representative genomes per class without the quality-specific ranking. |
| `get_and_modify_gbk` | Extracts and modifies GenBank records around selected loci. |
| `annotate_domains` | Adds InterPro/domain annotations to GenBank records. |
| `quantify_neighborhood_synteny` | Quantifies protein neighborhoods for synteny-aware inputs. |
| `collate_neighborhoods` | Collates per-genome neighborhood outputs. |
| `cluster_neighborhood_synteny` | Clusters neighborhood architectures for synteny outputs. |
| `to_cluster` | Builds cluster-level summary tables. |
| `classify_functional_bins` | Classifies proteins/domains into functional ontology bins. |
| `color_map_gen` | Builds color maps for clinker visualizations. |
| `synteny_plot` | Runs clinker to render synteny plots. |
| `inject_clinker_colors` | Recolors clinker output using generated color maps. |
| `quantify_neighborhood` | Quantifies neighborhoods for frequency/cluster analyses. |
| `plot_pfam_frequency` | Plots Pfam/domain frequency in neighborhoods. |
| `cluster_neighborhood` | Clusters non-synteny-specific neighborhoods. |
| `plot_cluster_frequency` | Plots cluster frequency summaries. |

## Python scripts called

| Script | Called by | Purpose |
| --- | --- | --- |
| `bin/units/subset_dataframe.py` | `rules/from_database.smk` (`get_data_from_database`) | Filters a CSV by configured protein names/annotation column. |
| `bin/units/top_quality_genome_per_class.py` | `top_genome_by_quality_per_class` | Selects highest-quality representatives per taxonomic class. |
| `bin/units/top_genome_per_class.py` | `top_genome_per_class` | Selects representative genomes per class. |
| `bin/units/extract_synteny_2.py` | `get_and_modify_gbk` | Extracts genomic neighborhoods and writes modified GenBank files. |
| `bin/units/annotate_gbk_w_ips.py` | `annotate_domains` | Adds InterPro/domain annotations to GenBank features. |
| `bin/units/get_protein_neighborhoods.py` | `quantify_neighborhood_synteny`, `quantify_neighborhood` | Computes neighborhood composition around target proteins. |
| `bin/units/cluster_neighborhood.py` | `cluster_neighborhood_synteny`, `cluster_neighborhood` | Clusters neighborhoods by composition/architecture. |
| `bin/units/build_cluster_df.py` | `to_cluster` | Builds a cluster-level dataframe from neighborhood cluster assignments. |
| `bin/units/ontology_classifier.py` | `classify_functional_bins` | Maps annotations/domains into ontology-based functional categories. |
| `bin/units/clinker_color_mapper.py` | `color_map_gen` | Generates clinker color mappings for genes/domains. |
| `bin/units/recolor_clinker.py` | `inject_clinker_colors` | Injects generated colors into clinker plot output. |
| `bin/units/plot_pfam_frequency.py` | `plot_pfam_frequency` | Plots Pfam/domain frequency summaries. |

## Non-Python helpers called

The workflow also uses `clinker` for synteny visualization and `plot_clusters2.r` for cluster-frequency plots.

# HMM Search Pipeline

`bin/pipelines/hmmsearch_pipeline/Snakefile` resolves configured Pfam names/IDs and ASCOG terms, builds or extracts HMM profiles, searches a protein FASTA database with HMMER, and optionally extracts genomic neighborhoods plus a PDF review report.

## Main rules and sub-rules

This pipeline is self-contained in its `Snakefile` and does not include separate `.smk` sub-rule files.

| Rule | What it does |
| --- | --- |
| `download_pfam` | Downloads and uncompresses the Pfam-A HMM database when the configured file is missing. |
| `press_pfam` | Runs `hmmpress` so HMMER can search/extract from the Pfam database. |
| `build_pfam_mapping` | Creates a two-column Pfam name-to-accession mapping from the HMM database headers. |
| `resolve_pfam_ids` | Matches configured terms against Pfam and ASCOG metadata, writing selected Pfam IDs and ASCOG rows. |
| `make_cog_hmms` | Builds HMMs from selected ASCOG alignments and annotates them with accession/description metadata. |
| `extract_hmms` | Extracts selected Pfam HMMs and combines them with generated ASCOG HMMs. |
| `press_combined` | Presses the combined HMM database. |
| `hmmsearch` | Runs HMMER against the configured protein FASTA database. |
| `parse_results` | Converts domain-table output into CSV. |
| `filter_results` | Applies score/e-value/domain filters and writes final hits. |
| `extract_hit_sequences` | Pulls hit sequences from the source FASTA. |
| `review_gate` | Creates a manual review checkpoint before optional full genomic extraction/reporting. |
| `extract_genomic_sequences` | Extracts genomic regions around hits when `Run_full` is enabled. |
| `generate_pdf_report` | Builds a PDF sequence report when `Run_full` is enabled. |

## Python scripts called

| Script | Called by | Purpose |
| --- | --- | --- |
| `scripts/domtblout_to_csv.py` | `parse_results` | Parses HMMER `--domtblout` output into a tabular CSV of domain hits. |
| `scripts/extract_hits_fasta.py` | `extract_hit_sequences` | Reads hit CSV rows and extracts matching protein sequences from the configured FASTA database. |
| `scripts/extract_genomic_regions.py` | `extract_genomic_sequences` | Uses filtered hits and database metadata to write genomic sequence regions around each hit. |
| `scripts/generate_pdf_report.py` | `generate_pdf_report` | Creates a PDF report summarizing extracted hit sequences/regions for review. |

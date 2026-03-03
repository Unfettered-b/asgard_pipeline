🧬 ASGARD Pipeline

A modular, reproducible bioinformatics workflow framework built using Snakemake, designed for structured protein set extraction, curation, and downstream analysis.

🚀 Overview

ASGARD Pipeline is designed as a multi-pipeline framework.
Each biological workflow lives in its own modular pipeline directory, while sharing:

Unified executor (run_pipeline.sh)

Config-driven execution

Structured logging

Conda-based reproducibility

Manual review gates (human-in-the-loop design)

🏗 Architecture
asgard_pipeline/
│
├── bin/
│   ├── run_pipeline.sh
│   ├── pipelines/
│   │   ├── protein_pipeline/
│   │   │   ├── Snakefile
│   │   │   └── rules/
│   │   └── ...
│   └── envs/
│
├── processes/
│   ├── protein_pipeline_IPS_ftsz.yaml
│   └── ...
│
├── database/
├── logs/
└── README.md
🧠 Execution Model

Pipelines are executed via:

bash bin/run_pipeline.sh processes/<config.yaml>

The config file determines:

Which pipeline to run

Input files

Target protein

Run ID

Log directory

Execution cores

📄 Config Structure

Minimal example:

pipeline: protein_pipeline
protein_name: ftsz
run_id: ftsz_test_run
log_dir: logs/
cores: 24

database: path/to/interpro.parquet
protein_file: path/to/protein.csv
fasta_file: path/to/all.fasta

search_string: ftsz
rstring: null
📜 Logging System

Each run generates a structured log:

<log_dir>/<pipeline>_<protein>_<run_id>.log

The log contains:

Run metadata

Config snapshot

Full Snakemake output

Timestamps

Execution details

Manual reruns append to the same log file if run_id remains unchanged.

🧪 Conda Environments

Environments are created automatically by Snakemake.

Stored under .snakemake/conda/.

Hash-based isolation ensures reproducibility.

Built using libmamba backend.

🔍 Manual Review Gates

Certain pipelines may include manual curation steps.

Workflow pauses when:

.rev.fasta does not exist

REVIEW_DONE.flag not present

User must:

Curate .unr.fasta

Save as .rev.fasta

Create marker:

touch REVIEW_DONE.flag

Re-run pipeline

🛡 Design Principles

Config-driven execution

Modular pipeline separation

File-state driven workflow control

Human-in-the-loop validation

Reproducibility first

🔮 Future Extensions

Additional pipelines (alignment, phylogeny, annotation, etc.)

Cluster profile support

Automated report generation

Pipeline registry

Schema-based config validation
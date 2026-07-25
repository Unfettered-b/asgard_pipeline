# Protein Exploration and Phylogenetic Analysis

This workflow describes how to identify, curate, and infer the phylogeny of protein families from the assembled genome database.

> **Prerequisite**
>
> The genome database and protein database must already be generated before running this workflow.

The workflow consists of three stages:

1. Rough protein extraction
2. Manual curation
3. Phylogenetic analysis

---

# Configuration

To begin a new analysis, duplicate an existing configuration file (template support will be added in a future release).

## Run Information

The following fields under the `run` object must be updated before each run:

```yaml
run:
  protein_name:
  id:
  reason:
```

### Parameters

| Parameter      | Description                                                                                       |
| -------------- | ------------------------------------------------------------------------------------------------- |
| `protein_name` | Name of the protein family being analysed. Creates the top-level output directory.                |
| `id`           | Unique identifier for the current run. Creates a subdirectory under the protein family directory. |
| `reason`       | Short description of the purpose of this run for future reference.                                |

Outputs are organized as

```text
database/protein_sets/{protein_name}/{run.id}
```

Each pipeline invocation is automatically recorded in

```text
processes/run_manifest.tsv
```

The manifest stores

* protein name
* run ID
* reason
* timestamp
* execution status (success or failure)

---

# Extraction Modes

The extraction workflow supports multiple modes.

```yaml
modes:
  parse_ips:
    enabled: false

  hmmsearch:
    enabled: true

  from_manual:
    enabled: false

  from_fasta_csv:
    enabled: false

  arcog:
    enabled: false
```

> **Important**
>
> Only **one extraction mode** should be enabled at a time.
>
> If multiple modes are enabled simultaneously, the pipeline executes whichever mode is checked first in the Snakefile, which may not be the intended behaviour.

---

# Stage 1 — Rough Protein Extraction

The purpose of this stage is to identify **candidate proteins** from the complete protein database.

The selected proteins are tagged in the `manual_curation` column of the collated protein database.

Two extraction methods are available.

## 1. `parse_ips`

Searches the **InterProScan description** field.

Example:

```yaml
parse_ips:
  enabled: true
  search:
    search_string: actin
    rstring:
```

Two search options are available:

| Option          | Description               |
| --------------- | ------------------------- |
| `search_string` | Simple substring search   |
| `rstring`       | Regular expression search |

Only one of these should be specified.

---

## 2. `hmmsearch`

Searches InterProScan accession IDs instead of text descriptions.

Example:

```yaml
hmmsearch:
  enabled: true
  acc_groups:
    - PF00022
    - IPR004000
```

The accession list may contain

* Pfam IDs
* InterPro IDs

---

## Why is this only a rough extraction?

This stage intentionally captures a broad set of candidate proteins.

For example,

```text
search_string: actin
```

may retrieve

* Actin
* Actin-like proteins
* Interacting proteins
* Other proteins containing the word "actin"

Further filtering is therefore required.

---

## Output

After extraction, the pipeline automatically generates

* multiple sequence alignment
* preliminary phylogenetic tree
* iTOL visualization
* domain architecture annotation

The tree should be inspected manually.

Copy the leaf labels corresponding to proteins you wish to retain into an ID file located in

```text
database/protein_sets/protein_ids/
```

---

## Mapping Manual Annotations

Protein IDs are mapped back into the collated protein database using

```text
bin/standalones/add_manual_annotation.py
```

Edit the annotation mapping inside the script:

```python
annotation_files = {
    "{annotation_name}":
        "database/protein_sets/protein_ids/{file}.ids",
}
```

where

* the dictionary key becomes the manual annotation stored in the database
* the value points to the ID file containing the selected proteins

---

# Stage 2 — Manual Curation

Create a **new run ID** before beginning manual curation.

Enable the `from_manual` extraction mode.

Example:

```yaml
from_manual:
  enabled: true
  manual_annotation_filter:
    - actin
```

The pipeline now extracts only proteins matching the specified manual annotations.

A refined multiple sequence alignment and phylogenetic tree are generated.

Inspect these outputs to remove

* truncated proteins
* poorly aligned sequences
* obvious false positives
* duplicate sequences

The generated FASTA and alignment files are located in

```text
database/protein_sets/{protein_name}/{run.id}/extraction_exploration/
```

After curation,

1. Move the FASTA file one directory higher.
2. Rename

```text
*.unr.fasta
```

to

```text
*.rev.fasta
```

This curated FASTA becomes the input for the final phylogenetic analysis.

---

# Stage 3 — Phylogenetic Analysis

Set

* `run.id` to the ID of the completed manual curation run
* `phyl_id` to the desired output identifier for the phylogeny

Configure the alignment, trimming, and tree-building methods as required.

Example configuration:

```yaml
phylogeny:
  alignment:
    method: mafft

  trimming:
    method: clipkit

  tree:
    method: iqtree
```

The pipeline currently supports

| Step           | Supported Methods     |
| -------------- | --------------------- |
| Alignment      | MAFFT, FAMSA, MUSCLE  |
| Trimming       | ClipKIT, TrimAl, BMGE |
| Tree inference | IQ-TREE               |

The remaining parameters allow customization of each tool, including

* alignment settings
* trimming options
* substitution model
* bootstrap support
* SH-aLRT support
* rooting
* multithreading

Modify these parameters according to the requirements of your analysis before running the workflow.

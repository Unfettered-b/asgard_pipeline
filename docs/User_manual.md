# Asgard Pipeline User Manual

The **Asgard Pipeline** is a **Snakemake-based workflow** for
downloading, organizing, and analyzing prokaryotic genomes, with a
particular emphasis on **Asgard archaea**. The pipeline provides an
integrated framework for:

-   Genome download and database updates
-   Genome annotation
-   Protein database construction
-   Protein exploration and functional annotation
-   Phylogenetic inference
-   Gene synteny analysis

A **Graphical User Interface (GUI)** is also available and is currently
under active development.

------------------------------------------------------------------------

# Quick Start

``` bash
# Clone the repository
git clone https://github.com/Synthetic-Cell-Biology-Lab/asgard_pipeline.git
cd asgard_pipeline

# Create the conda environment
conda env create -f bin/asgard.yaml
conda activate asgard

# Download required databases
bash bin/download_database.sh

# (Optional) Install GUI dependencies
bash bin/GUI_setup.sh

# Download genomes
snakemake --configfile processes/updation.yaml

# Run a BLAST search
bash bin/run_blast.sh <query_name>
```

> **Note:** Replace `<query_name>` with the name of your FASTA file
> (without the `.fasta` extension).

------------------------------------------------------------------------

# Installation

## 1. Clone the Repository

``` bash
git clone https://github.com/Synthetic-Cell-Biology-Lab/asgard_pipeline.git
cd asgard_pipeline
```

## 2. Install Conda

Install any Conda distribution (Miniforge, Miniconda, or Anaconda).

Official documentation:

https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html

## 3. Create the Environment

``` bash
conda env create -f bin/asgard.yaml
conda activate asgard
```

## 4. Download Required Databases

Run:

``` bash
bash bin/download_database.sh
```

This downloads and initializes the required databases:

-   Bakta
-   InterProScan
-   CheckM2
-   GTDB-Tk

> **Note:** The database download script is under active development.
> Future versions will automatically generate configuration files and
> populate paths.

------------------------------------------------------------------------

# Optional: Graphical User Interface

Install GUI dependencies:

``` bash
bash bin/GUI_setup.sh
```

Launch the GUI:

``` bash
bash bin/run_gui.sh
```

------------------------------------------------------------------------

# Downloading Genome Databases

All genome download settings are configured in:

``` text
processes/updation.yaml
```

## Download by Organism Name

Example configuration:

``` yaml
organisms:
  - name: "promethearchaeati"
    assembly_level:
    refseq_only: false
```

### Parameters

  -----------------------------------------------------------------------
  Parameter                        Description
  -------------------------------- --------------------------------------
  `name`                           Organism name exactly as listed in the
                                   NCBI Datasets database.

  `assembly_level`                 Restrict downloads to specific
                                   assembly levels. Leave blank to
                                   download all available assemblies.

  `refseq_only`                    Download only RefSeq assemblies if set
                                   to `true`.
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## Updating an Existing Database

To update an existing local genome collection:

``` yaml
cds:
  bakta_db: "/path/to/bakta/db"
  existing: "/path/to/existing/cds_genomes"
```

The pipeline downloads only genomes that are not already present.

------------------------------------------------------------------------

## Download by Accession

Example:

``` yaml
manual_genomes:
  hc1:
    - accession: GCA_055385335.1

  sc1:
    - accession: my_custom_mag_01
      path: /data/manual/my_mag.fna
```

Supported inputs:

-   NCBI GCA accession
-   Local genome FASTA
-   Custom accession identifier

------------------------------------------------------------------------

## Output

The update workflow produces a collated genome database under:

``` text
database/collated/
```

This serves as the input for downstream analyses.

------------------------------------------------------------------------

# Running BLAST

1.  Place your query FASTA file inside:

``` text
database/blast/queries/
```

Example:

``` text
database/blast/queries/ftsz.fasta
```

2.  Run:

``` bash
bash bin/run_blast.sh ftsz
```

where `ftsz` is the filename without the `.fasta` extension.

------------------------------------------------------------------------

# Running Pipelines

All the pipelines present in the Asgard pipeline are stored in 

```text
bin/pipelines

```
To run a pipeline, make appropriate config files and use 

```text

bash bin/run_pipeline.sh processes/{configfile}.yaml

```

------------------------------------------------------------------------

# Single Genome Interproscan

go to 
```txt
bin/standalones/run_one_ips.sh
```

edit the genome parameter to the genome file and its path

and run the script as such

```bash
bash bin/standalones/run_one_ips.sh
```

The outputs are stored in 

```txt
database/cds_genomes/{organism}/{genome}/
```


------------------------------------------------------------------------

# Project Structure

``` text
asgard_pipeline/
├── bin/
├── database/
    ├── blast/
        ├── queries/
        └── results/
├── processes/
├── workflow/
└── README.md
```

------------------------------------------------------------------------

# Notes

-   All pipeline parameters are controlled through YAML configuration
    files.
-   Activate the Conda environment before running workflows.
-   Database downloads only need to be performed once unless updates are
    required.
-   The GUI is optional; every workflow can also be executed from the
    command line.

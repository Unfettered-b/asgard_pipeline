# Asgard Pipeline User Manual

The **Asgard Pipeline** is a comprehensive pipeline that allows the user to download, explore and analyze the proteins in Prokaryotic genomes, particularly for Asgardarchaeota. There is provision for **downloading new genomes/ updating exisiting database**, Exploring the proteins in the genomes, Phylogenetic inference and Synteny analysis of gene/protein sets. The pipeline is constructed using **Snakemake**.
There is also provision of a **Graphical User Interface (GUI)** but it's still under construction.


## Installation Guide

Clone this repository 

```bash
git clone https://github.com/Synthetic-Cell-Biology-Lab/asgard_pipeline

```
Next, we need to download all the requisite databases for constructing the genome and protein database. This includes **bakta**, **Interproscan**, **CheckM2** and **GTDB**

run the download_database.sh

```bash
bash bin/download_database.sh

```


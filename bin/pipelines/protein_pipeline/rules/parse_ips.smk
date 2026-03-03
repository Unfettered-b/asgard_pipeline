########################################
# Parse IPS
########################################

rule parse_ips:
    input:
        database = config["database"]
    output:
        outfile = f"{EXPLORATION_DIR}/{PROTEIN}_domain_proteins.tsv",
        protein_ids = f"{EXPLORATION_DIR}/{PROTEIN}.ids"
    params:
        search_string = config.get("search_string", None),
        rstring = config.get("rstring", None)
    conda:
        f"{config['env_dir']}/duckdb_handler.yaml"
    message:
        """
        ===============================
        Running parse_ips
        ===============================
        """
    script:
        f"{CURRENT_DIR}/bin/units/parse_ips.py"


########################################
# Extract FASTA + CSV
########################################

rule merge_file:
    input:
        protein_file = config["protein_file"],
        fasta = config["fasta_file"],
        protein_ids = f"{EXPLORATION_DIR}/{PROTEIN}.ids"
    output:
        outfasta = f"{EXPLORATION_DIR}/{PROTEIN}.unr.fasta",
        protein_csv = f"{EXPLORATION_DIR}/{PROTEIN}.unr.csv"
    params:
        remove_hypotheticals = config.get("remove_hypotheticals", False)
    conda:
        f"{config['env_dir']}/Reg.yaml"
    message:
        """
        ===============================
        Running merge_file
        ===============================
        """
    script:
        f"{CURRENT_DIR}/bin/units/get_fasta_csv_from_ids.py"


############################################
# Exploratory FastTree
############################################

rule exploratory_fasttree:
    input:
        fasta = f"{EXPLORATION_DIR}/{PROTEIN}.unr.fasta"
    output:
        tree = f"{EXPLORATION_DIR}/{PROTEIN}_unr_fasttree.treefile"
    threads: config.get("phylogeny_threads", 8)
    conda:
        f"{config['env_dir']}/phylogeny.yaml"
    params:
        prefix = f"{EXPLORATION_DIR}/{PROTEIN}_unr_fasttree"
    message:
        """
        ==========================================
        🌳 Exploratory FastTree
        ==========================================
        """
    shell:
        """
        bash {CURRENT_DIR}/bin/units/fasttree_pipeline.sh \
            {input.fasta} \
            {params.prefix} \
            {threads}
        """


########################################
# Generate iTOL Colorstrip
########################################

rule itol_colorstrip:
    input:
        fasta = f"{EXPLORATION_DIR}/{PROTEIN}.unr.fasta"
    output:
        f"{EXPLORATION_DIR}/{PROTEIN}_colorstrip.txt"
    shell:
        """
        python {CURRENT_DIR}/bin/units/generate_colorstrip.py \
            {input.fasta} \
            {output} \
            "header"
        """


########################################
# Upload to iTOL
########################################

rule upload_to_itol:
    input:
        tree = f"{EXPLORATION_DIR}/{PROTEIN}_unr_fasttree.treefile",
        colorstrip = f"{EXPLORATION_DIR}/{PROTEIN}_colorstrip.txt",
        default = lambda wildcards: config.get("default_annotation", "")
    output:
        tree_ids = f"{EXPLORATION_DIR}/{PROTEIN}_fast_itol_uploaded.flag"
    params:
        project = config.get("itol_project", "Asgard")
    shell:
        """
        bash {CURRENT_DIR}/bin/units/itol_upload.sh \
            {input.tree} \
            {params.project} \
            {output.tree_ids} \
            {input.colorstrip} \
            {input.default}
        """


########################################
# Manual Review Gate
########################################

rule review_gate:
    input:
        flag = f"{EXPLORATION_DIR}/{PROTEIN}_fast_itol_uploaded.flag",
        fasta = f"{EXPLORATION_DIR}/{PROTEIN}.unr.fasta",
        tree = f"{EXPLORATION_DIR}/{PROTEIN}_unr_fasttree.treefile"
    output:
        f"{RESULT_DIR}/REVIEW_DONE.flag"
    run:
        import os

        rev_fasta = f"{RESULT_DIR}/{PROTEIN}.rev.fasta"
        marker = output[0]

        if os.path.exists(rev_fasta) and os.path.exists(marker):
            print("✅ Manual review already completed.")
            return

        print("\n🔍 MANUAL REVIEW REQUIRED\n")
        print(f"Review FASTA: {input.fasta}")
        print(f"Tree file: {input.tree}")
        print(f"Save curated file as: {rev_fasta}")
        print(f"Then run: touch {marker}\n")

        raise SystemExit(1)
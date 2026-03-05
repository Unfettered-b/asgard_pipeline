import os


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
        project = config.get("itol_project", "Asgard"),
        tree_name = f"fast_{config.get('run_id', 'run')}_{PROTEIN}"
    shell:
        """
        bash {CURRENT_DIR}/bin/units/itol_upload.sh \
            {input.tree} \
            {params.project} \
            {params.tree_name} \
            {output.tree_ids} \
            {input.colorstrip} \
            {input.default}
        """

########################################
# Manual Review Gate
########################################

REVIEW_GATE_INPUTS = [
    f"{EXPLORATION_DIR}/{PROTEIN}.unr.fasta",
    f"{EXPLORATION_DIR}/{PROTEIN}_unr_fasttree.treefile"
]

if config.get("run_itol_upload", False):
    REVIEW_GATE_INPUTS.append(f"{EXPLORATION_DIR}/{PROTEIN}_fast_itol_uploaded.flag")



rule review_gate:
    input:
        REVIEW_GATE_INPUTS
    output:
        rev_fasta = f"{RESULT_DIR}/{PROTEIN}.rev.fasta",
        marker = f"{RESULT_DIR}/REVIEW_DONE.flag"
    run:
        import os

        if os.path.exists(output.rev_fasta) and os.path.exists(output.marker):
            print("✅ Manual review already completed.")
            return

        print("\n🔍 MANUAL REVIEW REQUIRED\n")
        print(f"Review FASTA: {input[0]}")
        print(f"Tree file: {input[1]}")

        if len(input) > 2:
            print(f"iTOL upload flag: {input[2]}")
        print(f"Save curated file as: {output.rev_fasta}")
        print(f"Then run: touch {output.marker}\n")

        raise SystemExit(1)
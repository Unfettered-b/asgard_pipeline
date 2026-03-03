########################################
# Parse IPS
########################################

rule parse_ips:
    input:
        database = config["database"]
    output:
        outfile = f"{RESULT_DIR}/{PROTEIN}_domain_proteins.tsv",
        protein_ids = f"{RESULT_DIR}/{PROTEIN}.ids"
    params:
        search_string = config.get("search_string", None),
        rstring = config.get("rstring", None)
    conda:
        f"{config['env_dir']}/duckdb_handler.yaml"
    message:
        """
        ===============================
        Running parse_ips
        Input: {input}
        Output: {output}
        ===============================
        """
    script:
        "../../../units/parse_ips.py"


########################################
# Extract FASTA + CSV
########################################

rule merge_file:
    input:
        protein_file = config["protein_file"],
        fasta = config["fasta_file"],
        protein_ids = f"{RESULT_DIR}/{PROTEIN}.ids"
    output:
        outfasta = f"{RESULT_DIR}/{PROTEIN}.unr.fasta",
        protein_csv = f"{RESULT_DIR}/{PROTEIN}.unr.csv"
    conda:
        f"{config['env_dir']}/Reg.yaml"
    message:
        """
        ===============================
        Running merge_file
        Input: {input}
        Output: {output}
        ===============================
        """
    script:
        "../../../units/get_fasta_csv_from_ids.py"


########################################
# Manual Review Gate
########################################

rule review_gate:
    input:
        f"{RESULT_DIR}/{PROTEIN}.unr.fasta"
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
        print(f"Review: {input[0]}")
        print(f"Save curated file as: {rev_fasta}")
        print(f"Then run: touch {marker}\n")

        raise SystemExit(1)
rule from_manual:
    input:
        protein_file = config['protein_file'],
        genome_file = config['genome_file'],
        fasta_file = config['fasta_file']
    params:
        taxonomic_level = config.get('taxon_level', None),
        taxon_filter = config.get("taxon_filter", None),
        annotation_filter = config.get("manual_annotation_filter", [])
    output:
        protein_ids = f"{EXPLORATION_DIR}/{PROTEIN}.ids",
        outfasta = f"{EXPLORATION_DIR}/{PROTEIN}.unr.fasta",
        protein_csv = f"{EXPLORATION_DIR}/{PROTEIN}.unr.csv"

    conda:
        f"{config['env_dir']}/Reg.yaml"
    shell:
        """
        python {CURRENT_DIR}/bin/units/from_manual.py \
            {input.protein_file} \
            {input.genome_file} \
            {input.fasta_file} \
            {output.protein_ids} \
            {output.outfasta} \
            {output.protein_csv} \
            {params.taxonomic_level} \
            {params.taxon_filter} \
            {params.annotation_filter}
        """

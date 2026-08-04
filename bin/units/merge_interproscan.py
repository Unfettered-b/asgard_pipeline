from pathlib import Path
import duckdb

files = list(snakemake.input)
outfile = snakemake.output.parquet

con = duckdb.connect()
con.execute(f"""
COPY (
    SELECT *
    FROM read_csv(
        ?,
        delim='\t',
        header=false,
        columns={{
            'protein_accession':'VARCHAR',
            'sequence_md5':'VARCHAR',
            'sequence_length':'INTEGER',
            'analysis':'VARCHAR',
            'signature_accession':'VARCHAR',
            'signature_description':'VARCHAR',
            'start':'INTEGER',
            'end':'INTEGER',
            'score':'VARCHAR',
            'status':'VARCHAR',
            'date':'VARCHAR',
            'interpro_accession':'VARCHAR',
            'interpro_description':'VARCHAR',
            'go_terms':'VARCHAR',
            'pathways':'VARCHAR'
        }},
        filename=true
    )
)
TO '{outfile}'
(FORMAT PARQUET, COMPRESSION ZSTD);
""", [files])
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
            'protein':'VARCHAR',
            'md5':'VARCHAR',
            'length':'INTEGER',
            'analysis':'VARCHAR',
            'sig_acc':'VARCHAR',
            'sig_desc':'VARCHAR',
            'start':'INTEGER',
            'end':'INTEGER',
            'score':'VARCHAR',
            'status':'VARCHAR',
            'date':'VARCHAR',
            'ipr_acc':'VARCHAR',
            'ipr_desc':'VARCHAR',
            'go_terms':'VARCHAR',
            'pathways':'VARCHAR'
        }},
        filename=true
    )
)
TO '{outfile}'
(FORMAT PARQUET, COMPRESSION ZSTD);
""", [files])
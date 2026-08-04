#!/usr/bin/env python3

import sys
import os
import tempfile

import duckdb
import pyarrow as pa
import pyarrow.parquet as pq


try:
    snakemake
    IN_PARQUET = snakemake.input[0]
    OUT_PARQUET = snakemake.output[0]
except NameError:
    IN_PARQUET = sys.argv[1]
    OUT_PARQUET = (
        sys.argv[2]
        if len(sys.argv) > 2
        else "protein_summary.parquet"
    )

print("Sorting by protein...")

tmpdir = tempfile.mkdtemp(prefix="ips_sort_")
sorted_parquet = os.path.join(tmpdir, "sorted.parquet")

con = duckdb.connect()

# Allow spilling to disk
con.execute("SET preserve_insertion_order=false")
con.execute(f"SET temp_directory='{tmpdir}'")

con.execute(f"""
COPY (
    SELECT
        protein,
        ipr_acc,
        ipr_desc,
        go_terms,
        pathways
    FROM read_parquet('{IN_PARQUET}')
    ORDER BY protein
)
TO '{sorted_parquet}'
(FORMAT PARQUET, COMPRESSION ZSTD);
""")

con.close()

print("Streaming aggregation...")

pf = pq.ParquetFile(sorted_parquet)

schema = pa.schema([
    ("protein", pa.string()),
    ("domains", pa.string()),
    ("go_terms", pa.string()),
    ("pathways", pa.string()),
])

writer = pq.ParquetWriter(
    OUT_PARQUET,
    schema,
    compression="zstd",
)

current = None

domains = set()
gos = set()
paths = set()

ROWS_PER_WRITE = 50000

out_protein = []
out_domains = []
out_go = []
out_path = []


def flush_current():
    if current is None:
        return

    out_protein.append(current)
    out_domains.append("; ".join(sorted(domains)) if domains else None)
    out_go.append("; ".join(sorted(gos)) if gos else None)
    out_path.append("; ".join(sorted(paths)) if paths else None)


def flush_batch():
    global out_protein, out_domains, out_go, out_path

    if not out_protein:
        return

    table = pa.table({
        "protein": out_protein,
        "domains": out_domains,
        "go_terms": out_go,
        "pathways": out_path,
    })

    writer.write_table(table)

    out_protein = []
    out_domains = []
    out_go = []
    out_path = []


batch_no = 0

for batch in pf.iter_batches(
    batch_size=250000,
    columns=[
        "protein",
        "ipr_acc",
        "ipr_desc",
        "go_terms",
        "pathways",
    ],
):

    batch_no += 1
    print(f"Batch {batch_no}")

    protein = batch.column(0).to_pylist()
    ipr_acc = batch.column(1).to_pylist()
    ipr_desc = batch.column(2).to_pylist()
    go_terms = batch.column(3).to_pylist()
    pathways = batch.column(4).to_pylist()

    for p, acc, desc, go, path in zip(
        protein,
        ipr_acc,
        ipr_desc,
        go_terms,
        pathways,
    ):

        if current is None:
            current = p

        if p != current:

            flush_current()

            domains.clear()
            gos.clear()
            paths.clear()

            current = p

            if len(out_protein) >= ROWS_PER_WRITE:
                flush_batch()

        if acc and acc != "-" and desc and desc != "-":
            domains.add(desc)

        if go and go != "-":
            gos.update(x for x in go.split("|") if x)

        if path and path != "-":
            paths.update(x for x in path.split("|") if x)


flush_current()
flush_batch()

writer.close()

print("Done.")
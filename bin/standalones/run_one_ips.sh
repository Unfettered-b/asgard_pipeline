genome="GCA_055385335.1.fna"
input_faa="database/cds_genomes/promethearchaeati/${genome}/${genome}.faa"
clean_faa="database/cds_genomes/promethearchaeati/${genome}/${genome}_clean.faa"
threads=8
base="database/cds_genomes/promethearchaeati/${genome}/${genome}"

mkdir -p "interpro_temp/${genome}" logs

sed '/^>/! s/\*//g' "${input_faa}" > "${clean_faa}"

/home/anirudh/interproscan/interproscan.sh \
    -i "${clean_faa}" \
    -f tsv,xml,gff3 \
    -appl Pfam,Gene3D,SUPERFAMILY \
    -dp -goterms -pa \
    -cpu "${threads}" \
    -T "interpro_temp/${genome}" \
    -b "${base}" \
    > "logs/${genome}.log" 2>&1

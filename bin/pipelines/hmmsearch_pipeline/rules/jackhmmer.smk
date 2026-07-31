from pathlib import Path

BASE_DIR = config["run"]["base_dir"]


RUN_ID= config["run"]["id"]
BASE_DIR = os.getcwd()
PROJECT_NAME = config['run']['protein_name']
CURRENT_DIR = config.get("run", {}).get('base_dir', workflow.basedir)
RESULT_DIR = Path(f"{BASE_DIR}/database/protein_sets/{PROJECT_NAME}/{RUN_ID}")


JACKHMMER_DIR=f"{RESULT_DIR}/jackhmmer"

rule all:
   input:
      f"{JACKHMMER_DIR}/{RUN_ID}hmmprofile.hmm",
      f"{JACKHMMER_DIR}/{RUN_ID}_hits.txt",
      f"{JACKHMMER_DIR}/{RUN_ID}.hmm.h3m"

#download protein file 


rule download_proteinfile:
   params:
       uniprot_id=config["inputs"]["jackhmmer"]["params"]["accession_id"]
   output:
      output_fasta=f"{JACKHMMER_DIR}/{RUN_ID}.fasta"

   shell:
      """
      curl -X GET "https://rest.uniprot.org/uniprotkb/{params.uniprot_id}.fasta"> {output.output_fasta}
      """


rule jackhmmer:
   input:
      file= f"{JACKHMMER_DIR}/{RUN_ID}.fasta",         
      database=config["inputs"]["database"]["uniprot_db"].format(base_dir=BASE_DIR)

   output:
      output_hits = f"{JACKHMMER_DIR}/{RUN_ID}_hits.txt",              #hits from jackhmmer
      alignment_file= f"{JACKHMMER_DIR}/{RUN_ID}.aln.sto"              #alignment file
    
   params:
      num_iterations= config["inputs"]["jackhmmer"]["params"]["iterations"],
      evalue_cutoff=config["inputs"]["jackhmmer"]["params"]["evalue_cutoff"],
      incE=config["inputs"]["jackhmmer"]["params"]["incE"]

   shell:
      """
      jackhmmer -A {output.alignment_file} -N {params.num_iterations} -E {params.evalue_cutoff} -o {output.output_hits} {input.file} {input.database}

     """


rule make_hmmerdb:
   input:
      alignment_file  = f"{JACKHMMER_DIR}/{RUN_ID}.aln.sto"                        
      
   output:
      hmm_file= f"{JACKHMMER_DIR}/{RUN_ID}hmmprofile.hmm"              

   shell:
      """  
      hmmbuild {output.hmm_file} {input.alignment_file}   
      """
   
rule press:
    input:
        f"{JACKHMMER_DIR}/{RUN_ID}hmmprofile.hmm"
    output:
        f"{JACKHMMER_DIR}/{RUN_ID}.hmm.h3m"
    shell:
        """
        hmmpress {input}
        """




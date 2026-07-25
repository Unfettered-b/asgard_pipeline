
rule jaclhmmer:
    inputs: 
       file= f"",
       database= f"",
    output:
        out_file= f""             
    
    params:
       num_iterations= config["jackhmmer"]["num_iterations"],
       evalue_cutoff=config["jackhmmer"]["e_value_cutoff"],
       incE=config["jackhmmer"]["incE"],


    shell:
      """
    jackhmmer \
        -N {params.num_iterations} \
        -incE {params.incE} \
        -E {params.evalue_cutoff} \
        -o {output.out_file} \
        {input.file} \
        {input.database}

     """


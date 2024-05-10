#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.workflow = 'FBMN-gnps2'
params.db = 'data/COCONUT.psv'
params.savegraph=1
params.ion_mode=1
params.adduct='[M+H]+'
params.ppm=15

// CPUs and Cores for the workflow
params.num_processes = 8  
params.max_cpus_per_process = 1  //  TODO : update if the chemwalker process uses parallelization (more than 1 cpus)


// Workflow Boiler Plate
params.OMETALINKING_YAML = "flow_filelinking.yaml"
params.OMETAPARAM_YAML = "job_parameters.yaml"
params.publishdir = "./nf_output"
TOOL_FOLDER = "$baseDir/bin"

process generateComps {
    publishDir "$params.publishdir", mode: 'copy'

    conda "$TOOL_FOLDER/conda_env.yml"
    
    input:
    val taskid 
    val workflow

    output:
    path 'component_values.txt', emit: comp_values_file

    script:
    """
    python $TOOL_FOLDER/ChemWalker/bin/network_walk save-component-ids --taskid $taskid --workflow $workflow --outputfile component_values.txt
    """
}

process chemWalker {
    cpus params.max_cpus_per_process
    publishDir "${params.publishdir}/tsv_files_directory", mode: 'copy'

    conda "$TOOL_FOLDER/conda_env.yml"

    input:
    val taskid 
    val workflow
    each comp
    val savegraph
    path db
    path metfragpath
    val ion_mode
    val adduct
    val ppm
    

    output:
    path "${comp}_output_file.tsv", optional: true, emit: tsv_file
    path "${comp}_output_file.graphml", optional: true
    
    
    // echo $comp > ${comp}_output_file.tsv
    // echo $comp > ${comp}_output_file.graphml
    """    
    python $TOOL_FOLDER/ChemWalker/bin/network_walk random-walk --taskid $taskid --workflow $workflow --comp $comp --out "${comp}_output_file" --savegraph $savegraph --db $db --metfragpath $metfragpath --kw \'{"ispositive": $ion_mode, "adduct": "$adduct", "ppm": $ppm}\'
    """
}


process mergeTSV {
    publishDir "${params.publishdir}", mode: 'copy'
    conda "$TOOL_FOLDER/conda_env.yml"
    // This process is not working because csvstack does not work with \t separators. TODO Speak with Ricardo if we can use , or ; and escape strings with quotes ""
    cpus = 1
    input:
    path tsv_files

    output:
    path 'random_walk_output.tsv'

    script:
    """

    csvstack $tsv_files > random_walk_output.tsv
    """
}


process mergeTSVPython {
    publishDir "${params.publishdir}/tsv_files_directory", mode: 'copy'
    conda "$TOOL_FOLDER/conda_env.yml"
    cpus = 1
    
    input:
    path tsv_files

    output:
    path 'random_walk_output.tsv'

    script:
    """
    python $TOOL_FOLDER/merge_tsv.py --directory tsv_files_directory --output random_walk_output.tsv
    """
}


workflow {
    cpus = params.num_processes
    taskid = params.taskid
    workflow = params.workflow
    comp = params.comp
    savegraph = params.savegraph
    metfragpath = Channel.fromPath("$TOOL_FOLDER/ChemWalker/bin/MetFrag2.3-CL.jar")
    
    db = Channel.fromPath(params.user_db)
    
    
    if (comp == 0){
        components_file = generateComps(taskid, workflow)
        
        components_channel = components_file.splitText().map{ it.trim() }
        
        tsv_files_channel = Channel.of([])
        components_channel.each{ component -> 
        (tsv_file, graphml_file) = chemWalker(taskid, workflow, component, savegraph, db, metfragpath, params.ion_mode, params.adduct, params.ppm)
        tsv_files_channel = tsv_files_channel.mix(chemWalker.out.tsv_file)
        }.collect()
        
        //tsv_files_channel.view()
        mergeTSV(tsv_files_channel.collect())
        
    }
    else{    
        chemWalker(taskid, workflow, comp, savegraph, db, metfragpath, params.ion_mode, params.adduct, params.ppm)
    }
    
}


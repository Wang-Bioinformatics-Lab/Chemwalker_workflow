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
params.memory = '8 GB'

// Workflow Boiler Plate
params.OMETALINKING_YAML = "flow_filelinking.yaml"
params.OMETAPARAM_YAML = "job_parameters.yaml"
TOOL_FOLDER = "$baseDir/bin"

process generateComps {
    publishDir "./nf_output", mode: 'copy', overwrite: false

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
    memory params.memory
    publishDir "./nf_output", mode: 'copy', overwrite: false

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
    path "${comp}_output_file.graphml", optional: true, emit: graphml_file
    
    """
    python $TOOL_FOLDER/ChemWalker/bin/network_walk random-walk --taskid $taskid --workflow $workflow --comp $comp --out "${comp}_output_file" --savegraph $savegraph --db $db --metfragpath $metfragpath --kw \'{"ispositive": $ion_mode, "adduct": "$adduct", "ppm": $ppm}\'
    """
}

process mergeTSV {
    publishDir "./nf_output", mode: 'copy', overwrite: false
    conda "$TOOL_FOLDER/conda_env.yml"
    cpus = 1
    
    input:
    path tsv_files

    output:
    path 'random_walk_output.tsv'

    script:
    """
    awk 'FNR==1 && NR!=1 { next; } { print }' ${tsv_files.join(' ')} > random_walk_output.tsv
    """
}

process zipGraphML {
    publishDir "./nf_output", mode: 'copy', overwrite: false
    conda "$TOOL_FOLDER/conda_env.yml"
    cpus = 1
    input:
    path graphml_files

    output:
    path 'graphml_files.tar.gz'

    script:
    """
    tar -cvzf graphml_files.tar.gz $graphml_files
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
    try {
        comp = comp as Integer
    } catch (Exception e) {
        error "Parameter 'comp' must be an integer. Given: ${params.comp}"
    }
    // if (comp <= 0){
    if (comp < 0){
        error "Component number must be greater than 0. Given: ${comp}"
    }
    else if (comp == 0){
        components_file = generateComps(taskid, workflow)
        components_channel = components_file.splitText().map{ it.trim() }
    }
    else{
        components_channel = Channel.of(comp)
    }

        tsv_files_channel = Channel.empty()
        graphml_files_channel = Channel.empty()

        (tsv_file, graphml_file) = chemWalker(taskid, workflow, components_channel, savegraph, db, metfragpath, params.ion_mode, params.adduct, params.ppm)
        tsv_files_channel = tsv_files_channel.mix(chemWalker.out.tsv_file)
        graphml_files_channel = graphml_files_channel.mix(chemWalker.out.graphml_file)
        
        mergeTSV(tsv_files_channel.collect()) 
        zipGraphML(graphml_files_channel.collect())
}


# chemwalker Nextflow

To test the workflow the next command should be executed:

```
make run [-e --taskid $taskid --workflow $workflow --comp $comp --db $db --metfragpath $metfragpath
```

For documentation about the chemwalker tool, please read the source tool [publication](https://doi.org/10.1093/bioinformatics/btad078) and [repository](https://github.com/computational-chemical-biology/ChemWalker/)

The variables taskid, and comp are mandatory and do not have default values. 
However, workflow, db and metfragpath have default values. The workflow will be FBMN if not specified V2, db will be COCONUT, and metfragpath will be the commandline present in the github for the version 2.3. 


To learn NextFlow checkout this documentation:

https://www.nextflow.io/docs/latest/index.html

## Parameters in nextflow 

The parameters in nextflow follow the next priority:

i. Parameters specified on the command line (--something value)
ii. Parameters provided using the -params-file option
iii. Config file specified using the -c my_config option
iv. The config file named nextflow.config in the current directory
v. The config file named nextflow.config in the workflow project directory
vi. The config file $HOME/.nextflow/config
vii. Values defined within the pipeline script itself (e.g. main.nf)

In case you wish to set your parameters directly in nextflow, please use the next syntaxis:


```
nextflow [options] ./nf_workflow.nf --spectra ${spectra_path} --library ${library_path} --ionmode (positive/negative) ${ion_mode} --download (yes/no) ${download} --ion_mode_exclusion (yes/no) ${ion_mode_exclusion}
```

## Run in a conda environment

To run the workflow in a conda environment, there is a configuration file [conda_env.yml](bin/conda_env.yml). This file configured the environment named chemwalker-env. It can be created and activated by:

```
conda env create -f bin/conda_env.yml
conda activate chemwalker-env
```


```
nextflow [options] ./nf_workflow.nf --annotations="$(annotations_file)" --path_to_spectra="$(path_to_spectra)" --ppm_tolerance=$(ppm_tolerance) --resume -c nextflow.config
```

## Deploy in your own server

Install nextflow according to the [documentation](https://www.nextflow.io/docs/latest/install.html). And run the previous commands. You can specify the resources with the next parameters:
```
params.num_processes = 8 // TODO USE ACCORDING TO YOUR SERVER RESOURCES
params.max_cpus_per_process = 1 // TODO USE ACCORDING TO YOUR SERVER RESOURCES
params.memory = '8 GB' // TODO USE ACCORDING TO YOUR SERVER RESOURCES
```


## Deployment in GNPS2

Check [Nexftlow template instructions from Mingxun Wang](https://github.com/Wang-Bioinformatics-Lab/Nextflow_Workflow_Template)

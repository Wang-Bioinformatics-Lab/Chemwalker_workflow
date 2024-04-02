savegraph=1
ion_mode=1
adduct="[M+H]+"
ppm=15
user_db='data/COCONUT.psv'
run:
	nextflow run ./nf_workflow.nf --taskid $(taskid) --workflow $(workflow) --comp $(comp) --user_db $(user_db) --savegraph $(savegraph) --ion_mode $(ion_mode) --adduct $(adduct) --ppm $(ppm) -resume -c nextflow.config

clean:
	rm -Rf .nextflow* work bin/*__pycache__* nf_output/*

run_hpcc:
	nextflow run ./nf_workflow.nf --taskid $(taskid) --workflow $(workflow) --comp $(comp) --user_db $(user_db) --savegraph $(savegraph) --ion_mode $(ion_mode) --adduct $(adduct) --ppm $(ppm) -resume -c nextflow_hpcc.config

run_docker:
	nextflow run ./nf_workflow.nf --taskid $(taskid) --workflow $(workflow) --comp $(comp) --user_db $(user_db) --savegraph $(savegraph) --ion_mode $(ion_mode) --adduct $(adduct) --ppm $(ppm) -resume -with-docker <CONTAINER NAME>

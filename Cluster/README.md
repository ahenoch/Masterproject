# Quick Tutorial

Alexander Henoch
2020-09-05

## Prerequisites:

### conda environments

- configs:
	- conda config --add channels defaults
	- conda config --add channels bioconda
	- conda config --add channels conda-forge

- projektarbeit:
	- conda create -n projektarbeit
	- conda activate projektarbeit
	- conda install ruby
	- conda install cd-hit
	- conda install mafft
	- conda install raxml
	- conda install newick_utils
	- conda install viennarna
	- conda install parallel
	- conda install jalview
	- conda deactivate

- vegeta
	- git clone https://github.com/klamkiew/vegeta.git
	- add vegeta to $PATH
	- conda create -n vegeta python=3.6
	- conda activate vegeta
	- conda install -c pip
	- conda install -c cd-hit
	- conda install -c mafft
	- conda install -c locarna
	- conda install -c glpk
	- pip install numpy biopython colorlog umap-learn hdbscan docopt scipy
	- conda deactivate
	
#### usage:

- with standart settings for Influenza C (every influenza type is supported)
	- cd Cluster
	- bash -i script.sh -p 8 -i C/ > .log
	- &> .log is not nesessary and you can start the script from wherever you want

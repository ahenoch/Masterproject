# Masterproject

## Evalution of VeGETAs core functions on _Influenza B virus_ subsets

### Introduction

In this project the clustering tools [usearch](https://academic.oup.com/bioinformatics/article-lookup/doi/10.1093/bioinformatics/btq461) and [CD-HIT](https://academic.oup.com/bioinformatics/article-lookup/doi/10.1093/bioinformatics/btl158) are compared to a new tool named [VeGETA](https://github.com/klamkiew/vegeta) that uses [HDBSCAN](http://link.springer.com/10.1007/978-3-642-37456-2_14) for its clustering function. All three tools are ranked by the related clustering quality. 

The tools were used on random subsets of various FASTA files containing the (segmented) genomes of all strains of _Influenza B virus_. Clustering _Influenza A virus_
segments is skipped here, because the enormous number of highly different sequences forevery segment makes random subsets extremely various. Some random sequences out of many ten thousands with highly different sequence, result in nearly the same number of clusters as used random sequences, especially with sequence identity based algorithms,like the ones used by usearch and CD-HIT. _Influenza C virus_ is skipped also because there exist roughly 100 sequences per segment and the differences in these sequences are negligible, compared in a multiple sequence alignment. This is resulting in a small amount of clusters per tool, mostly only one, which is obstructive for the creation of a rating pipeline and meaningful statements about the clustering quality. 

The clusters of _Influenza B virus_ were compared and their quality rated by a calculated score, using the clusters representative, with a vector based rating method created in this project. After calculation of the used algorithms clustering quality, VeGETA is used on the same random subset of sequences, to calculate the overall secondary structure of the clustered sequences. These resulting secondary structures are validated by literature in the report.

### Prerequisites

To use the proposed pipeline on the given set of Files in the repository, two conda environments need to exist. To create these results the following block of code can be used.

```
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --add channels r

conda create -n projektarbeit
conda activate projektarbeit

conda install ruby
conda install cd-hit
conda install mafft
conda install raxml
conda install newick_utils
conda install viennarna
conda install parallel
conda install jalview

conda deactivate

git clone https://github.com/klamkiew/vegeta.git
export PATH="$HOME/vegeta/bin:$PATH" 
    #include in .Bashrc or .profile for permanent PATH modification 

conda create -n vegeta python=3.6
conda activate vegeta

conda install -c pip
conda install -c cd-hit
conda install -c mafft
conda install -c locarna
conda install -c glpk

pip install numpy biopython colorlog umap-learn hdbscan docopt scipy

conda deactivate
```

To start the pipeline the script must be executed in an interactive shell to have access to the environments. 

```
cd Masterproject/Cluster
bash -i script.sh -p 8 -i B/ > .log
```

For execution on _Influenza B virus_ and _Influenza C virus_ subsets the command can be extended to include both.

```
cd Masterproject/Cluster
bash -i script.sh -p 8 -i B/ -i C/ > .log
```

All steps to use the proposed pipeline are described in detail in the report.

---

Special thanks to Daniel Desiro and Kevin Lamkiewicz for supervision!

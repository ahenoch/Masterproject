*[IAV]: _Influenza A virus_
*[IBV]: _Influenza B virus_
*[ICV]: _Influenza C virus_

# Masterproject

## Evalution of VeGETAs core functions on _Influenza B virus_ subsets

In this project the clustering tools [usearch](https://academic.oup.com/bioinformatics/article-lookup/doi/10.1093/bioinformatics/btq461) and [CD-HIT](https://academic.oup.com/bioinformatics/article-lookup/doi/10.1093/bioinformatics/btl158) are compared to a new tool named [VeGETA](https://github.com/klamkiew/vegeta) that uses [HDBSCAN](http://link.springer.com/10.1007/978-3-642-37456-2_14) for its clustering function. 

The tools were used on random subsets of various FASTA files containing the (segmented) genomes of all strains of IBV. Clustering IAV
segments is skipped here, because the enormous number of highly different sequences forevery segment makes random subsets extremely various. Some random sequences out of many ten thousands with highly different sequence, result in nearly the same number of clusters as used random sequences, especially with sequence identity based algorithms,like the ones used by usearch and CD-HIT. ICV is skipped also because there exist roughly 100 sequences per segment and the differences in these sequences are negligible, compared in a multiple sequence alignment (MSA). This is resulting in a small amount of clusters per tool, mostly only one, which is obstructive for the creation of a rating pipeline and meaningful statements about the clustering quality. 

The clusters of IBV were compared and their quality rated by a calculated score, using the clusters representative, with a vector based rating method created in this project. After calculation of the used algorithms clustering quality, VeGETA is used on the same random subset of sequences, to calculate the overall secondary structure of the clustered sequences. These resulting secondary structures are validated by literature in the report.

#!/bin/bash

set -e

usage () { 
	echo "Usage: $0 [-p <number procsses>] [-i inputdir 1] [-i ...]" 1>&2; exit 1; 
}

while getopts ":p:i:" option ; do
        case ${option} in
        p) proc=${OPTARG} ;;
        i) indir=( ${indir[@]} $(basename ${OPTARG}) ) ;;
        *) usage ;;
        esac
done
shift $((OPTIND -1))

if [ -z "$proc" ]; then
	usage
fi

if [ ${#indir[@]} -eq 0 ]; then
	usage
fi

scriptdir=$(realpath $(dirname $0))

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		
		if ! [ -f "$segment/GenomicFastaResults.fasta" ]; then
			usage
		fi
		
		if ! [ -d "$segment/Results" ]; then
			mkdir $segment/Results
			mkdir $segment/Results/{MAFFT,RAxML,VeGETA,NW_Utils,usearch,CD-HIT-EST,Rating,FASTA}
		else
			rm -r $segment/Results
			mkdir $segment/Results
			mkdir $segment/Results/{MAFFT,RAxML,VeGETA,NW_Utils,usearch,CD-HIT-EST,Rating,FASTA}
		fi		
	done
done

conda activate projektarbeit

echo 'Working on deleting replicas.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input=$segment/GenomicFastaResults.fasta
		output=$segment/Results/FASTA/unique.fasta
		nice cd-hit-est -M 2000 -s 1 -c 1 -T $proc -c 1 -i $input -o $output
	done
done

echo 'Finished deleting replicas.'

###get random 500 sequences

echo 'Working on extraction of random sequences.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input=$segment/Results/FASTA/unique.fasta
		output=$segment/Results/FASTA/rndm.fasta
		${scriptdir}/Scripts/random.sh -i $input -o $output -n 500
	done
done

echo 'Finished extraction of random sequences.'

###correction of genome direction

echo 'Working on correction of strand direction.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input=$segment/Results/FASTA/rndm.fasta
		output=$segment/Results/FASTA/corr.fasta
		${scriptdir}/Scripts/direction.sh -i $input -o $output
	done
done

echo 'Finished correction of strand direction.'

###aligment with MAFFT

echo 'Working on MAFFT alignment.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input=$segment/Results/FASTA/corr.fasta
		output=$segment/Results/MAFFT/MSA.fasta
		nice mafft --auto --reorder --quiet --thread $proc $input > $output
	done
done

echo 'Finished MAFFT alignment.'

##visualization with Jalview

echo 'Working on rendering Jalview picture.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
                input=$segment/Results/MAFFT/MSA.fasta
                output=$segment/Results/MAFFT/MSA.svg
                nice jalview -nodisplay -colour Nucleotide -open $input -svg $output
        done
done

echo 'Finished rendering Jalview picture.'

###phylogenic tree with RAxML

echo 'Working on building RAxML tree.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input=$segment/Results/MAFFT/MSA.fasta
		output=$segment/Results/RAxML
		sed -i '/^>/ s/[]:()[]//g' $input && nice raxmlHPC-PTHREADS-SSE3 -T $proc -N 100 -f a -x 1234 -p 1234 -m GTRGAMMA -s $input -w $output -n Tree
        done
done

echo 'Finished building RAxML tree.'

###correction of RAxML Tree

echo 'Working on correction of RAxML tree.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input=$segment/Results/RAxML/RAxML_bipartitionsBranchLabels.Tree
		ruby ${scriptdir}/Scripts/raxml2drawing.rb $input && sed -i -r 's/(\|[^:]+)//g; s/gb//g' ${input}.corrected
	done
done

echo 'Finished correction of RAxML tree.'

conda deactivate

####VeGETA

conda activate vegeta

echo 'Working on VeGETA clustering.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input=$segment/Results/FASTA/corr.fasta
		output=$segment/Results/VeGETA/
		nice vegeta $input -o $output -p $proc
        done
done

echo 'Finished VeGETA clustering.'

conda deactivate

###extract Ornament, CSS and spread color scheme on basis of cluster number from VeGETA

conda activate projektarbeit

echo 'Working on extraction of color scheme from VeGETA.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input=$segment/Results/VeGETA/vegeta/cluster.txt
		input2=$segment/Results/VeGETA/vegeta/corr_repr.fa
		output=$segment/Results/VeGETA/
		${scriptdir}/Scripts/veg.sh -c ${input} -r ${input2} -o $output
        done
done

echo 'Finished extraction of color scheme from VeGETA.'

####CD-HIT-EST

echo 'Wokring on CD-HIT-EST clustering.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input=$segment/Results/FASTA/corr.fasta
		output=$segment/Results/CD-HIT-EST/centroid
		nice cd-hit-est -T $proc -i $input -o $output -c 0.95 -n 8
        done
done

echo 'Finished CD-HIT-EST clustering.'

###extract Ornament, CSS and spread color scheme on basis of cluster number from usearch

echo 'Working on extraction of color scheme from CD-HIT-EST.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input=$segment/Results/CD-HIT-EST/
		output=$segment/Results/CD-HIT-EST/
		${scriptdir}/Scripts/cdh.sh -c ${input}centroid.clstr -r ${input}centroid -o $output
        done
done


echo 'Finished extraction of color scheme from CD-HIT-EST.'

####usearch

echo 'Working on usearch clustering.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input=$segment/Results/FASTA/corr.fasta
		output=$segment/Results/usearch/centroid
		output2=$segment/Results/usearch/cluster
		${scriptdir}/Scripts/usearch -cluster_fast $input -id 0.95 -centroids $output -clusters $output2
        done
done

echo 'Finished usearch clustering.'

###extract Ornament, CSS and spread color scheme on basis of cluster number from usearch

echo 'Working on extraction of color scheme from usearch.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input=$segment/Results/usearch/
		output=$segment/Results/usearch/
		${scriptdir}/Scripts/ucl.sh -c ${input}cluster -r ${input}centroid -o $output
        done
done

echo 'Finished extraction of color scheme from usearch.'

echo 'Working on mafft alignment of centroids.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		input1=$segment/Results/CD-HIT-EST/centroid
		input2=$segment/Results/usearch/centroid
		input3=$segment/Results/VeGETA/vegeta/corr_repr.fa
		output1=$segment/Results/MAFFT/cd-hit.fasta
		output2=$segment/Results/MAFFT/usearch.fasta
		output3=$segment/Results/MAFFT/vegeta.fasta
		nice mafft --auto --reorder --quiet --thread $proc $input1 > $output1
		nice mafft --auto --reorder --quiet --thread $proc $input2 > $output2
		nice mafft --auto --reorder --quiet --thread $proc $input3 > $output3
	done
done

echo 'Finished mafft alignment of centroids.'

###export result with Newick Utils

echo 'Working on rendering VeGETA result SVG.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		seg=$(basename $segment)
		input=$segment/Results/RAxML/RAxML_bipartitionsBranchLabels.Tree
		input2=$segment/Results/VeGETA/
		output=$segment/Results/NW_Utils/${type}_${seg:0:2}_vegeta.svg
		nice nw_topology -I ${input}.corrected > ${input}.topo && nw_display -v 25 -i "font-size:10" -l "font-size:10;font-family:helvetica;font-style:italic" -Il -w 5000 -s -r -b "opacity:0" -c ${input2}css.map -o ${input2}ornament.map ${input}.topo > $output
        done
done

echo 'Finished rendering VeGETA result SVG.'

echo 'Working on rendering usearch result SVG.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		seg=$(basename $segment)
		input=$segment/Results/RAxML/RAxML_bipartitionsBranchLabels.Tree
		input2=$segment/Results/usearch/
		output=$segment/Results/NW_Utils/${type}_${seg:0:2}_usearch.svg
		nice nw_display -v 25 -i "font-size:10" -l "font-size:10;font-family:helvetica;font-style:italic" -Il -w 5000 -s -r -b "opacity:0" -c ${input2}css.map -o ${input2}ornament.map ${input}.topo > $output
        done
done

echo 'Finished rendering usearch result SVG.'

echo 'Working on rendering CD-HIT-EST result SVG.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		seg=$(basename $segment)
		input=$segment/Results/RAxML/RAxML_bipartitionsBranchLabels.Tree
		input2=$segment/Results/CD-HIT-EST/
		output=$segment/Results/NW_Utils/${type}_${seg:0:2}_cd-hit-est.svg
		nice nw_display -v 25 -i "font-size:10" -l "font-size:10;font-family:helvetica;font-style:italic" -Il -w 5000 -s -r -b "opacity:0" -c ${input2}css.map -o ${input2}ornament.map ${input}.topo > $output
        done
done

echo 'Finished rendering usearch result SVG.'

###export result of secondary structure with Vienna

echo 'Working rendering Vienna result SVG.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
		seg=$(basename $segment)
		input=$segment/Results/VeGETA/vegeta/corr_repr_finalAlignment.stk
		output=$segment/Results/
		nice RNAplot -i $input -a -o svg -t 2
		mv alignment_0001_ss.svg ${output}${type}_${seg:0:2}_structure.svg
        done
done

echo 'Finished rendering Vienna result SVG.'

echo 'Working on Rating Clusters.'

for type in ${indir[@]}; do
	for segment in ${scriptdir}/$type/*; do 
                input1=$segment/Results/MAFFT/MSA.fasta
                input2=$segment/Results/CD-HIT-EST/clstr_cdh
                input3=$segment/Results/usearch/clstr_ucl
                input4=$segment/Results/VeGETA/clstr_veg
                input5=$segment/Results/Rating/clstr
                output=$segment/Results/Rating/
                cat $input2 $input3 $input4 > $input5 && ${scriptdir}/Scripts/rating.sh -m $input1 -o $output -i $input5 -p $proc -c ${scriptdir}/Scripts/Codons.tsv
        done
done

echo 'Finished Rating Cluster.'

conda deactivate

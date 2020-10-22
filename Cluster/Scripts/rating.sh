#!/bin/bash

#Comparison of Clustering Algorithms
#12.09.2020
#Alexander Henoch

set -e

vectorize () {
	python3 $1/vectorize.py $2 $3 $4
	#echo $1 $2 $3 $4
}

rating () {

	Rscript $1/rating.R $2 $3

}

usage() { 
	echo "Usage: $0 [-m <msa input path>] [-o <output dir>] [-i inputcluster] [-c codontable] [-p ]" 1>&2; exit 1; 
}

while getopts ":m:o:i:c:p:" option ; do
	case ${option} in
	m) inmsa=${OPTARG} ;;
	o) outdir=${OPTARG} ;;
	i) inclstr=${OPTARG} ;;
	c) incodon=${OPTARG} ;;
	p) proc=${OPTARG} ;;
	*) usage ;;
	esac
done
shift $((OPTIND -1))

if ! [ "${outdir: -1}" = "/" ]; then
	outdir+=/
fi

if ! [ -f "$inmsa" ] || ! [ -f "$inclstr" ] || ! [ -f "$incodon" ] || [ -z "$proc" ] || ! [ -d "$outdir" ]; then
	usage
fi

if ! [ -d "${outdir}.tmp" ]; then
	mkdir ${outdir}.tmp	
else
	rm -r ${outdir}.tmp
	mkdir ${outdir}.tmp
fi

if ! [ -d "${outdir}cluster" ]; then
	mkdir ${outdir}cluster	
else
	rm -r ${outdir}cluster
	mkdir ${outdir}cluster
fi

if ! [ -d "${outdir}vectors" ]; then
	mkdir ${outdir}vectors
else
	rm -r ${outdir}vectors
	mkdir ${outdir}vectors
fi

scriptdir=$(realpath $(dirname $0))
tmpmsa=${outdir}.tmp/msa

rating=${outdir}rating.csv
>$rating
log=${outdir}rating.log
>$log

export -f vectorize
export -f rating

sed 's/ /_/g' $inmsa | awk '/^[>;]/ { if (seq) { print seq }; seq=""; print } /^[^>;]/ { seq = seq $0 } END { print seq }' > $tmpmsa

while read line; do
        
        #read line by line
	IFS=',' read -r -a arr_line <<< "$line"
        
        tool=$(echo ${arr_line[0]})
        num=$(echo ${arr_line[1]})
        centr=$(echo ${arr_line[2]})
        seqs=$(echo ${arr_line[3]})
        
        #splitt last column in array itself
        IFS=' ' read -r -a arr_seq <<< "$seqs"
	
	#arr_centr=()
	fst_centr=$(sed -n "/^>gb:$centr/{n;p}" $tmpmsa)
	#j=0
	#while [ $(($j+$stp)) -lt ${#fst_centr} ]; do 
	
	#	arr_centr=( ${arr_centr[@]} ${fst_centr:$j:$win} )
	
		#if [ $j -eq 0 ]; then
		#	arr_centr=( ${arr_centr[@]} ${fst_centr:$j:$win+2} )
		#else
		#	arr_centr=( ${arr_centr[@]} ${fst_centr:$j-2:$win+4} )
		#fi	
		
	#	((j+=stp))    
	#done
	
        #echo $centr ${arr_centr[@]} > ${outdir}.tmp/cluster/${tool}_${num}
        echo $centr$'\t'$fst_centr > ${outdir}cluster/${tool}_${num}
        
        for seq in ${arr_seq[@]}; do
        
        	#arr_seq=()
		fst_seq=$(sed -n "/^>gb:$seq/{n;p}" $tmpmsa)
		#i=0
		#while [ $(($i+$stp)) -lt ${#fst_seq} ]; do 
			
		#	arr_seq=( ${arr_seq[@]} ${fst_seq:$i:$win} )
			#if [ $i -eq 0 ]; then
			#	arr_seq=( ${arr_seq[@]} ${fst_seq:$i:$win+2} )
			#else
			#	arr_seq=( ${arr_seq[@]} ${fst_seq:$i-2:$win+4} )
			#fi	
			
		#	((i+=stp))    
		#done
        
        	#echo $seq ${arr_seq[@]} >> ${outdir}.tmp/cluster/${tool}_${num}
        	echo $seq$'\t'$fst_seq >> ${outdir}cluster/${tool}_${num}
        
        done
        
done < $inclstr

ls ${outdir}cluster/ | parallel --progress --keep-order --jobs $proc "vectorize $scriptdir ${outdir}vectors $incodon ${outdir}cluster/{}" >> $log

ls ${outdir}vectors/ | parallel --progress --keep-order --jobs $proc "rating $scriptdir ${outdir}vectors/{}" >> $rating

Rscript ${scriptdir}/output.R $rating ${outdir}output.csv 

rm -r ${outdir}.tmp

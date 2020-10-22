#!/bin/bash

usage() { echo "Usage: $0 [-i <input path>] [-o <output path>] [-f <fasta path>]" 1>&2; exit 1; }

while getopts ":i:o:f:" option ; do
        case ${option} in
        i) infile=${OPTARG} ;;
        o) outfile=${OPTARG} ;;
	f) fafile=${OPTARG} ;;
        *) usage ;;
        esac
done
shift $((OPTIND -1))

> $outfile

if ! [ -f "$infile" ] || ! [ -f "$outfile" ] || ! [ -f "$fafile" ]; then
	usage
fi

genome=''
IFS=$'\t' 
sed 1d $infile | while read name pb2 pb1 p3 he np mp ns; do

	IFS=',' read -r -a pb2 <<< "$pb2"
	IFS=',' read -r -a pb1 <<< "$pb1"
	IFS=',' read -r -a p3 <<< "$p3"
	IFS=',' read -r -a he <<< "$he"
	IFS=',' read -r -a np <<< "$np"
	IFS=',' read -r -a mp <<< "$mp"
	IFS=',' read -r -a ns <<< "$ns"
	
	for seg1 in "${pb2[@]}"; do
	for seg2 in "${pb1[@]}"; do
	for seg3 in "${p3[@]}"; do
	for seg4 in "${he[@]}"; do
	for seg5 in "${np[@]}"; do
	for seg6 in "${mp[@]}"; do
	for seg7 in "${ns[@]}"; do

		segall=($seg1 $seg2 $seg3 $seg4 $seg5 $seg6 $seg7)
		echo ${segall[@]}
		
		echo '>gb:'$seg1'|gb:'$seg2'|gb:'$seg3'|gb:'$seg4'|gb:'$seg5'|gb:'$seg6'|gb:'$seg7'|Strain Name:'$name >> $outfile

		genome=''

		for seg in "${segall[@]}"; do
			genome+=$(sed -n '/'$seg'/,/^>/ p' $fafile | sed '1d;$d' | sed ':a;N;$!ba;s/\n//g')
		done

		split_genome=$(echo $genome | sed -r 's/(.{,60})/\1\\n/g')

		echo -e $split_genome | sed '$d' >> $outfile

	done
	done
	done
	done
	done
	done
	done

done

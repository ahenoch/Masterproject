#!/bin/bash

usage() { echo "Usage: $0 [-i <input path>] [-o <output path>]" 1>&2; exit 1; }

orf_calc () {
	trip=1
	orfstart=0
	orfend=0
	orflength=0
	neworf=0
	inframe=0
	prime=( "$1" )
	prime+=('END')
	for i in ${prime[@]}; do
		if [[ "${#i}" -eq "3" ]]; then
			if [[ "ATG" = "$i" ]]; then
				if [[ "$orfend" -ge "$orfstart" ]]; then			
					orfstart=$trip
					inframe=1
				fi
			fi
			if [[ "TGA" = "$i" || "TAA" = "$i" || "TAG" = "$i" || "END" = "$i" ]]; then 			
				orfend=$trip
				if [[ "$inframe" -eq "1" ]]; then				
					neworf=$((orfend-orfstart))
					if [[ "$neworf" -gt "$orflength" ]]; then
						orflength=$(($neworf+1))	
					fi
					inframe=0
				fi	
			fi
			((trip++))
		fi
	done
	echo $orflength
}

strand_detection () {
	fiveprime1=$(echo $genome | fold -w3)
	threeprime1=$(echo $genome | tr 'A,C,G,T' 'T,G,C,A' | rev | fold -w3)
	fiveprime2=$(echo $genome | cut -c2- | fold -w3)
	threeprime2=$(echo $genome | tr 'A,C,G,T' 'T,G,C,A' | rev | cut -c2- | fold -w3)
	fiveprime3=$(echo $genome | cut -c3- | fold -w3)
	threeprime3=$(echo $genome | tr 'A,C,G,T' 'T,G,C,A' | rev | cut -c3- | fold -w3)
	
	fiveprimeorf1=$(orf_calc "$(echo ${fiveprime1[@]})")
	threeprimeorf1=$(orf_calc "$(echo ${threeprime1[@]})")	
	fiveprimeorf2=$(orf_calc "$(echo ${fiveprime2[@]})")
	threeprimeorf2=$(orf_calc "$(echo ${threeprime2[@]})")
	fiveprimeorf3=$(orf_calc "$(echo ${fiveprime3[@]})")
	threeprimeorf3=$(orf_calc "$(echo ${threeprime3[@]})")

	fiveprimeorf=( $fiveprimeorf1 $fiveprimeorf2 $fiveprimeorf3 )
	fiveprimeorf_sort=($(echo ${fiveprimeorf[*]}| tr " " "\n" | sort -n))

	threeprimeorf=( $threeprimeorf1 $threeprimeorf2 $threeprimeorf3 )
	threeprimeorf_sort=($(echo ${threeprimeorf[*]}| tr " " "\n" | sort -n))
	
	if [[ "${fiveprimeorf_sort[2]}" -ge "${threeprimeorf_sort[2]}" ]]; then
		mrna=$(echo $genome | sed -r 's/(.{,70})/\1\\n/g')
	else
		mrna=$(echo $genome | tr 'A,C,G,T' 'T,G,C,A' | rev | sed -r 's/(.{,70})/\1\\n/g')
		reversed+=( "$accession" )
	fi 
}

while getopts ":i:o:" option ; do
        case ${option} in
        i) infile=${OPTARG} ;;
        o) outfile=${OPTARG} ;;
	*) usage ;;
        esac
done

shift "$((OPTIND -1))"

> $outfile

if ! [ -f "$infile" ] || ! [ -f "$outfile" ]; then
	usage
fi

reversed=()
header="^>"
genome=''
#linesnum=$(grep -o ">" $infile | wc -l)
#n=1
accession=''

while read -r line; do
	
	if [[ $line =~ $header ]] ; then
		if ! [[ -z "$genome" ]]; then
						
			strand_detection
			echo -e $mrna >> $outfile
			genome=''
			((n++))
		fi
		echo $line >> $outfile
		#perc=$(printf "%.0f\n" $(echo "scale=2; $n/$linesnum*100" | bc -l))
		#echo -ne '('$perc'%)\r'
		accession=$(echo $line | sed 's/ /|/g' | sed 's/|.*//g')
	fi

	if ! [[ $line =~ $header ]] ; then
		genome+=$line
	fi

done < $infile
strand_detection
echo -e $mrna >> $outfile
for m in ${reversed[@]}; do
	echo $m
done


#!/bin/bash

usage() { echo "Usage: $0 [-c <input cluster file>] [-r <input representatives file>] [-o <output dir>]" 1>&2; exit 1; }

function color {

	colors=()
	color1=('#ff0000')
	color2=()
	color3=('#00ff00')
	color4=()
	color5=('#0000ff')
	color6=()

	steps=$(( ($1 + (6 - 1) ) / 6 ))
	if [ "$steps" -eq "1" ]; then
		colors=('#ff0000' '#ffff00' '#00ff00' '#00ffff' '0000ff' 'ff00ff')
	else
		num=$(( 255 / ( steps * 2 ) ))
		for i in $(seq 2 2 $(( ( steps * 2 ) -1 )) ); do
			hex=$(printf '%x\n' $(( $i * num)))
			if [ "${#hex}" -eq "1" ]; then
				hex="0${hex}"
			fi
			color1+=("#ff${hex}00")			#-> ffff00
			color2=("#${hex}ff00" "${color2[@]}")	#-> 00ff00
			color3+=("#00ff${hex}")			#-> 00ffff
			color4=("#00${hex}ff" "${color4[@]}")	#-> 0000ff
			color5+=("#${hex}00ff")			#-> ff00ff
			color6=("#ff00${hex}" "${color6[@]}")	#-> ff0000
		done
		color2=("#ffff00" "${color2[@]}")
		color4=("#00ffff" "${color4[@]}")
		color6=("#ff00ff" "${color6[@]}")
		colors=("${color1[@]}" "${color2[@]}" "${color3[@]}" "${color4[@]}" "${color5[@]}" "${color6[@]}")
	fi
}

while getopts ":c:r:o:" option ; do
        case ${option} in
        c) in_clust=${OPTARG} ;;
	r) in_repr=${OPTARG} ;;
        o) outdir=${OPTARG} ;;
	*) usage ;;
        esac
done

if ! [ -f "$in_clust" ] || ! [ -f "$in_repr" ] || ! [ -d "$outdir" ]; then
	usage
fi

shift $((OPTIND -1))

if ! [ "${outdir: -1}" = "/" ]; then
	outdir+=/
fi

#echo $in_clust
#echo $in_repr
#echo $outdir
>${outdir}css.map
>${outdir}ornament.map
>${outdir}clstr_veg

n=0
m=0
header="^Cluster"
header2="^Cluster: -1"
newcluster=""
cluster=()

while read -r line; do

	if [[ $line =~ $header ]] ; then
		if ! [[ -z "$newcluster" ]]; then

			cluster+=("${newcluster::-1}")			
			newcluster=""
		fi
		((n++))
		
		if [[ $line =~ $header2 ]] ; then
			m=1
		fi

	fi

	if ! [[ $line =~ $header ]] ; then		
		newcluster+=$( echo $line | sed 's/gb_//g' | sed 's/|.*/ /g' )	
	fi

done < $in_clust

cluster+=("${newcluster::-1}")
newcluster=""

clades=$n
color clades

header="^>"
reprcluster=""

while read -r line; do
	
	if [[ $line =~ $header ]] ; then
		reprcluster+=$( echo ${line:1} | sed 's/gb_//g' | sed 's/|.*/ /g' )	
	fi

done < $in_repr

echo $'"<circle style=\'fill:cyan;stroke:blue\' r=\'3\' />" I '$reprcluster >> ${outdir}ornament.map 

repr_list=( $reprcluster )

if [ "$m" -eq "0" ]; then
	
	for j in $(seq 0 $(( n - 1 )) ); do
		echo '"stroke-width:1.5; stroke:'${colors[$j]}'" I '${cluster[$j]} >> ${outdir}css.map
		echo "VeGETA, $j, ${repr_list[$j]}, ${cluster[$j]}" >> ${outdir}clstr_veg
	done

else 
	for j in $(seq 0 $(( n - 1 )) ); do
		if [ "$j" -eq "$(( n - 1 ))" ]; then
			echo '"stroke-width:1.5; stroke:'${colors[$j]}'" I '${cluster[$j]} >> ${outdir}css.map	
			echo $'"<circle style=\'fill:red;stroke:red\' r=\'3\' />" I '${cluster[$j]} >> ${outdir}ornament.map
			unclstr=( $(echo ${cluster[$j]}) )
			for uncl in ${unclstr[@]}; do
				echo "VeGETA, $j, $uncl, $uncl" >> ${outdir}clstr_veg
				((j++))
			done
			#echo ${unclstr[@]}
		else
			echo '"stroke-width:1.5; stroke:'${colors[$j]}'" I '${cluster[$j]} >> ${outdir}css.map
			echo "VeGETA, $j, ${repr_list[$j]}, ${cluster[$j]}" >> ${outdir}clstr_veg
		fi
	done
fi

#1  x=00
#4  x=00, ff         (255/1)
#7  x=00, 7f, ff     (255/2)
#10 x=00, 55, aa, ff (255/3)

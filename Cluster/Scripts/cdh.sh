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

#echo $in_clust
#echo $in_repr
#echo $outdir
>${outdir}css.map
>${outdir}ornament.map
#>${outdir}clstr_cdh
>${outdir}clstr_cdh

cat $in_clust > ${in_clust}.tmp
echo >> ${in_clust}.tmp

n=$(grep -c '^>' $in_clust)
clades=$n
color clades

reprcluster=$(sed -n '/^>/{s/>gb:\([a-zA-Z0-9]*\)|.*/\1/p}' $in_repr)
echo $'"<circle style=\'fill:cyan;stroke:blue\' r=\'3\' />" I '$reprcluster >> ${outdir}ornament.map 

repr_list=( $(sed -n 's/^.*>gb:\([^|]*\)|.*\*$/\1/p' $in_clust) )

for j in $(seq 0 $(( n - 1 )) ); do
	cluster=$(sed -n '/^>Cluster '$j'/,/^>/ p' ${in_clust}.tmp | sed '1d;$d' | sed -n '/>/{s/.*>gb:\([a-zA-Z0-9]*\)|.*/\1/p}')
	echo '"stroke-width:1.5; stroke:'${colors[$j]}'" I '$cluster >> ${outdir}css.map
	echo "cd-hit, $j, ${repr_list[$j]}, "$cluster >> ${outdir}clstr_cdh
done

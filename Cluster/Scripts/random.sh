#!/bin/bash

usage() { echo "Usage: $0 [-i <input path>] [-o <output path>] [-n <number>]" 1>&2; exit 1; }

while getopts ":i:o:n:" option ; do
        case ${option} in
        i) infile=${OPTARG} ;;
        o) outfile=${OPTARG} ;;
        n) num=${OPTARG} ;;
	*) usage ;;
        esac
done
shift $((OPTIND -1))

> $outfile

if ! [ -f "$infile" ] || ! [ -f "$outfile" ] || [ -z "$num" ]; then
	usage
fi

tmpfile=$(dirname "$(readlink -f "$infile")")"/.tmpfile"
awk '/^>/{sub(">", ">"++i"_")}1' $infile > $tmpfile

linesnum=$(grep -o ">" $tmpfile | wc -l)

rndmnum=($(shuf -i 1-$linesnum -n $num | sort -n))

for i in "${rndmnum[@]}" ; do

	sed -n '/^>'$i'_/,/^$/{p}' $tmpfile >> $outfile
done

rm $tmpfile
sed -i 's/>[0-9]*_/>/g' $outfile

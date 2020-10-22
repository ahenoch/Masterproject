#!/usr/bin/python3

import re
import os
import sys
import csv
import collections
import difflib

def search(entry, triplet, triplet_names):

    match_triplet = difflib.get_close_matches(entry, triplet_names, 1, 1)
    if not match_triplet:
        amino = 0
        
    else:
        match = match_triplet[0]
        amino = triplet[match]
        
    return(amino)

def orf(entry):
	trip_end = ['tga', 'taa' ,'tag', 'end']
	#trip_start = ['ATG', 'GTG, TTG']
	trip_start = ['atg']
	pos = 1
	orfstart = 0
	orfend = 0
	orflength = 0
	neworf = 0
	inframe = 0
	newgenome = ''
	frame=''

	trips = re.findall('...', entry)
	trips.append('end')

	for trip in trips:
		if inframe == 0:
			if trip in trip_start:
				orfstart = pos
				inframe = 1
				newgenome = trip
		else:
			if not trip == 'end':
				newgenome += trip
			if trip in trip_end:
				orfend = pos
				neworf = orfend - orfstart
				if neworf > orflength:
					orflength = neworf
					frame = newgenome
				inframe = 0
		pos += 1
	return(frame)

def main():

	outdir = sys.argv[1]
	incodon = sys.argv[2]
	stp = int(sys.argv[3])
	win = int(sys.argv[4])
	incluster = sys.argv[5]
  
	triplet = collections.defaultdict(list)

	with open(incodon, newline='') as csvfile:
		reader = csv.reader(csvfile, delimiter='\t')
	
		for row in reader:
			trip = row[1]
			acid = row[0]
			
			triplet[trip].append([acid])
			
	triplet_names = list(triplet.keys())
	
	with open(incluster, newline='') as csvfile:
		reader = csv.reader(csvfile, delimiter='\t')
		header = next(reader)
		
		entry = header[1]
		
		entry_rev = entry[::-1].translate(str.maketrans('at', 'ta')).translate(str.maketrans('cg', 'gc'))
		frame_list = [orf(entry), orf(entry[1:]), orf(entry[2:])]
		frame_rev_list = [orf(entry_rev), orf(entry_rev[1:]), orf(entry_rev[2:])]

		frame = max(frame_list, key=len)
		frame_rev = max(frame_rev_list, key=len)
		
		if len(frame) >= len(frame_rev):
			
			if frame == '' or len(frame) <= 30:
				orfstart=0
				orfend=0
				length=0
			else:
				utr = entry.split(frame)
				orfstart=len(utr[0])
				orfend=len(utr[1])
				length=len(frame)
		else:
			
			if frame_rev == '' or len(frame_rev) <= 30:
				orfstart=0
				orfend=0
				length=0
			else:
				utr = entry_rev.split(frame_rev)
				orfstart=len(utr[0])
				orfend=len(utr[1])
				length=len(frame_rev)

		#print(length, orfstart, orfend)
		
		if orfstart%3 == 0:
			centr = []
		elif orfstart%3 == 1:
			centr = ['XX' + header[1][0:orfstart%3]]
		else:	
			centr = ['X' + header[1][0:orfstart%3]]
			
		centr_utr5 = [header[1][k:k+3] for k in range(orfstart%3,orfstart, 3)]
		centr_trips = [header[1][l:l+3] for l in range(orfstart, len(header[1]), 3)]
		#centr_utr3 = [header[1][m:m+3] for m in range(orfstart+length, len(header[1]), 3)]
		
		centr.extend(centr_utr5)
		centr.extend(centr_trips)
		#centr.extend(centr_utr3)
		
		#print(centr)
		
		if header != None:
			
			out = []
			for row in reader:
						
				if orfstart%3 == 0:
					seq = []
					ol = 0
				elif orfstart%3 == 1:
					seq = ['XX' + row[1][0:orfstart%3]]
					ol = 2
				else:	
					seq = ['X' + row[1][0:orfstart%3]]
					ol = 1
					
				seq_utr5 = [row[1][n:n+3] for n in range(orfstart%3,orfstart, 3)]
				seq_trips = [row[1][o:o+3] for o in range(orfstart, len(row[1]), 3)]
				#seq_utr3 = [row[1][p:p+3] for p in range(orfstart+length, , 3)]
				
				seq.extend(seq_utr5)
				seq.extend(seq_trips)
				#seq.extend(seq_utr3)
				
				#print(seq)
				
				result = row[0]
				start = 1 + ol
				end = (len(seq)-1)*3 + len(seq[len(seq)-1]) + ol
				result = [row[0]]
				
				#print(start); print(end)
				
				i = start
				while i <= end:
					#print(i)
					rate = 0
					for nuc in range(i, i + win):
					
						try:
							t = int(nuc / 3) + (nuc % 3 > 0) - 1
							u = [nuc%3-1,2][nuc%3==0]

							centr_nuc = centr[t][u]
							seq_nuc = seq[t][u]
							
							if centr_nuc != seq_nuc:
								if centr_nuc == '-' and seq_nuc == '-':
									rate = rate + 0 #gap on gap
								elif search(centr[t], triplet, triplet_names) == search(seq[t], triplet, triplet_names) and search(seq[t], triplet, triplet_names) != 0:
									rate = rate + 1 #silent mutation
								elif (centr_nuc == 'a' and seq_nuc == 'g') or (centr_nuc == 'g' and seq_nuc == 'a'):
									rate = rate + 2 #purin mutation
								elif (centr_nuc == 'c' and seq_nuc == 't') or (centr_nuc == 't' and seq_nuc == 'c'):
									rate = rate + 2 #pyrimidin mutation
								else:
									rate = rate + 3 #big mutations
								
						except:
							pass
							#print(nuc)
					
					#print(nucs)
					i = i + stp
					result.append(rate)
				out.append(result)
			outpath = outdir + '/' + os.path.basename(incluster)
			with open(outpath, 'a') as outfile:
				outfile_write = csv.writer(outfile, delimiter=',', lineterminator='\n')
				outfile_write.writerows(out)

if __name__ == "__main__":
	main()

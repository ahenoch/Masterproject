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
	incluster = sys.argv[3]
  
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
		
		entry = ''
		frame_list = []
		frame = ''
		
		entry = header[1].replace("-", "")
		frame_list = [orf(entry), orf(entry[1:]), orf(entry[2:])]
		frame = max(frame_list, key=len)
	
		if frame == '' or len(frame) <= 30:
			centr = header[1]
			centr_trips = [0] * len(centr)
			
		else:
			utr = entry.split(frame)
			centr = header[1]
			centr_trips=[0] * len(utr[0])
			centr_trips.extend([frame[int(l/3)*3:int(l/3)*3+3] for l in range(0, len(frame))])
			centr_trips.extend([0] * len(utr[1]))

		j = 0
		for i in centr:
			if i == '-':
				centr_trips.insert(j, 0)
			j = j + 1

		#print(centr)
		#print(centr_trips)
		
		if header != None:
			
			out = []
			for row in reader:
				
				entry = ''
				frame_list = []
				frame = ''
					
				entry = row[1].replace("-", "")
				frame_list = [orf(entry), orf(entry[1:]), orf(entry[2:])]
				frame = max(frame_list, key=len)
				
				if frame == '' or len(frame) <= 30:
					seq = row[1]
					seq_trips = [0] * len(seq)
					
				else:
					utr = entry.split(frame)
					seq = row[1]
					seq_trips=[0] * len(utr[0])
					seq_trips.extend([frame[int(k/3)*3:int(k/3)*3+3] for k in range(0, len(frame))])
					seq_trips.extend([0] * len(utr[1]))
				
				m = 0
				for n in seq:
					if n == '-':
						seq_trips.insert(m, 0)
					m = m + 1
					
				#print(seq)
				#print(seq_trips)
				print(header[0], row[0])
				
				result = [row[0]]
				o = 0

				while o < len(row[1]):
					
					centr_nuc = centr[o]
					seq_nuc = seq[o]
					centr_trip = centr_trips[o]
					seq_trip = seq_trips[o]
					rate = 0
					
					if centr_nuc != seq_nuc:
						if (centr_nuc == 'n' and seq_nuc != '-') or (seq_nuc == 'n' and centr_nuc != '-'):
							rate = 0
						elif centr_trip != 0 and seq_trip != 0 and search(centr_trip, triplet, triplet_names) == search(seq_trip, triplet, triplet_names):
							rate = 1 #silent mutation
						elif (centr_nuc == 'a' and seq_nuc == 'g') or (centr_nuc == 'g' and seq_nuc == 'a'):
							rate = 2 #purin mutation
						elif (centr_nuc == 'c' and seq_nuc == 't') or (centr_nuc == 't' and seq_nuc == 'c'):
							rate = 2 #pyrimidin mutation
						else:
							rate = 3 #big mutations
					
					print(centr_nuc, seq_nuc, centr_trip, seq_trip, rate)
					
					o = o + 1	
					
					result.append(rate)
				
				out.append(result)
			outpath = outdir + '/' + os.path.basename(incluster)
			with open(outpath, 'a') as outfile:
				outfile_write = csv.writer(outfile, delimiter=',', lineterminator='\n')
				outfile_write.writerows(out)

if __name__ == "__main__":
	main()

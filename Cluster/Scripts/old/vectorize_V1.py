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
		
		entry = header[1].replace("-", "")
		
		entry_rev = entry[::-1].translate(str.maketrans('at', 'ta')).translate(str.maketrans('cg', 'gc'))
		frame_list = [orf(entry), orf(entry[1:]), orf(entry[2:])]
		frame_rev_list = [orf(entry_rev), orf(entry_rev[1:]), orf(entry_rev[2:])]

		frame = max(frame_list, key=len)
		frame_rev = max(frame_rev_list, key=len)
		
		if len(frame) >= len(frame_rev):
			
			if frame == '' or len(frame) <= 30:
				centr_orfstart=-1
				centr_orfend=-1
				centr_length=0
				centr_trips=[]
				
			else:
				utr = entry.split(frame)
				centr_orfstart=len(utr[0])
				centr_orfend=len(utr[1])
				centr_length=len(frame)
				centr_trips = [entry[l:l+3] for l in range(centr_orfstart, centr_orfstart + centr_length, 3)]
		else:
			
			if frame_rev == '' or len(frame_rev) <= 30:
				centr_orfstart=-1
				centr_orfend=-1
				centr_length=0
				centr_trips=[]
			else:
				utr = entry_rev.split(frame_rev)
				centr_orfstart=len(utr[0])
				centr_orfend=len(utr[1])
				centr_length=len(frame_rev)
				centr_trips = [entry[l:l+3] for l in range(centr_orfstart, centr_orfstart + centr_length, 3)]

		#print(header[1])
		#print(centr_length, centr_orfstart, centr_orfend)
		#print(centr_trips)
		
		if header != None:
			
			out = []
			for row in reader:
					
				entry = row[1].replace("-", "")
		
				entry_rev = entry[::-1].translate(str.maketrans('at', 'ta')).translate(str.maketrans('cg', 'gc'))
				frame_list = [orf(entry), orf(entry[1:]), orf(entry[2:])]
				frame_rev_list = [orf(entry_rev), orf(entry_rev[1:]), orf(entry_rev[2:])]

				frame = max(frame_list, key=len)
				frame_rev = max(frame_rev_list, key=len)
				
				if len(frame) >= len(frame_rev):
					
					if frame == '' or len(frame) <= 30:
						seq_orfstart=-1
						seq_orfend=-1
						seq_length=0
						seq_trips = []
					else:
						utr = entry.split(frame)
						seq_orfstart=len(utr[0])
						seq_orfend=len(utr[1])
						seq_length=len(frame)
						seq_trips = [entry[k:k+3] for k in range(seq_orfstart, seq_orfstart + seq_length, 3)]
				else:
					
					if frame_rev == '' or len(frame_rev) <= 30:
						seq_orfstart=-1
						seq_orfend=-1
						seq_length=0
						seq_trips = []
					else:
						utr = entry_rev.split(frame_rev)
						seq_orfstart=len(utr[0])
						seq_orfend=len(utr[1])
						seq_length=len(frame_rev)		
						seq_trips = [entry[k:k+3] for k in range(seq_orfstart, seq_orfstart + seq_length, 3)]
				
				#print(row[1])
				#print(seq_length, seq_orfstart, seq_orfend)
				#print(seq_trips)
			
				result = [row[0]]
				i = 0
				seq_pos = 0
				centr_pos = 0
				
				while i < len(row[1]):
					
					centr_nuc = header[1][i]
					seq_nuc = row[1][i]
					rate = 0
						
					if seq_orfstart <= seq_pos < seq_orfstart + seq_length and centr_orfstart <= centr_pos < centr_orfstart + centr_length and centr_nuc != '-' and seq_nuc != '-':		
					
						centr_as = centr_trips[int((centr_pos - centr_orfstart) / 3)]#[centr_pos%3]
						seq_as = seq_trips[int((seq_pos - seq_orfstart) / 3)]#[seq_pos%3]
						
						if centr_nuc != seq_nuc:
							if centr_nuc == 'n' or seq_nuc == 'n':
								rate = 0
							elif search(centr_as, triplet, triplet_names) == search(seq_as, triplet, triplet_names):
								rate = 1 #silent mutation
							elif (centr_nuc == 'a' and seq_nuc == 'g') or (centr_nuc == 'g' and seq_nuc == 'a'):
								rate = 2 #purin mutation
							elif (centr_nuc == 'c' and seq_nuc == 't') or (centr_nuc == 't' and seq_nuc == 'c'):
								rate = 2 #pyrimidin mutation
							else:
								rate = 3 #big mutations
						
						#print(centr_nuc, seq_nuc, centr_as, seq_as, rate)

					else:
						
						if centr_nuc != seq_nuc:
							if centr_nuc == 'n' or seq_nuc == 'n':
								rate = 0
							elif (centr_nuc == 'a' and seq_nuc == 'g') or (centr_nuc == 'g' and seq_nuc == 'a'):
								rate = 2 #purin mutation
							elif (centr_nuc == 'c' and seq_nuc == 't') or (centr_nuc == 't' and seq_nuc == 'c'):
								rate = 2 #pyrimidin mutation
							else:
								rate = 3 #big mutations	
						
						#print(centr_nuc, seq_nuc, 0, 0, rate)
						
					if centr_nuc != '-':
						centr_pos = centr_pos + 1	
						
					if seq_nuc != '-':
						seq_pos = seq_pos + 1	
					
					i = i + 1	
					
					result.append(rate)
				
				out.append(result)
			outpath = outdir + '/' + os.path.basename(incluster)
			with open(outpath, 'a') as outfile:
				outfile_write = csv.writer(outfile, delimiter=',', lineterminator='\n')
				outfile_write.writerows(out)

if __name__ == "__main__":
	main()

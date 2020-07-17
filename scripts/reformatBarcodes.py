import sys
import re
import matplotlib.pyplot as plt
import numpy as np
import statistics

sys.path.insert(1,'../')

def Revcomp(input):
	comp = ""
	for letter in input:
		comp += pairBasePair(letter)	
	return comp[::-1]

def pairBasePair(bp):
	switch = {
		'A':'T',
		'T':'A',
		'G':'C',
		'C':'G'
	}
	return switch.get(bp)


seqs = []
with open('/home/jeffbrady/Data/19322Brd/out/bar.fasta','r') as data:
	dataList = data.readlines()
	for i in range(0,len(dataList),2):
		seq ={
			'ID': dataList[i].strip('\n'),
			'barcode' : dataList[i+1].strip('\n'),
		}
		print(f"{seq['ID']}")
		print(f"{Revcomp(seq['barcode'][:6])}{Revcomp(seq['barcode'][6:])}")

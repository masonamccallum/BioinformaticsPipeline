#python addtaxonToOTU.py reads.sintax tabOTU.txt > taxonTabOTU.txt
import subprocess
import time
import os
import sys

fileToFix = sys.argv[1]
tabOTUFile = sys.argv[2]

import fileinput
import re

def findOTUTaxon(otuTitle):
	with open("temp.txt") as file:
		for line in file:
			if otuTitle in line:
				return line.split(":")[1]

with open("temp.txt", "w") as temp:
	with open(fileToFix,"r") as file:
		for line in file:
			taxonReformat = ""
			otuNum = line.split('\t')[0]
			taxon = line.split('+')[1]
			taxon = taxon.strip('\t')
			levels = taxon.split(',')
			numLevels = len(levels)
			for level in levels:
				taxonReformat += level.split(':')[1]
				numLevels -= 1
				if numLevels > 0:
					taxonReformat += '; ' 
			print(f'{otuNum}:{taxonReformat}', end="", file=temp)
	
with open(tabOTUFile, "r") as file:
	for line in file:
		otuline = line.split('\t')[0]
		line = line.replace('\n','')
		if otuline == "#OTU ID":
			print(f'{line}\ttaxonomy')
		else:
			print(f'{line}\t{findOTUTaxon(otuline)}',end='')

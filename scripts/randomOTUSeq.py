#grep "Firm" reads.sintax > firmReads.sintax
#cat firmReads.sintax |tr '\t' ' '| cut -d' ' -f1 > otuIDX.txt
#python randomOTUSeq.py otuIDX.txt OTU.fasta > subsetOTU
import sys
import random
import fileinput

firmOTUs = []
with open(sys.argv[1],"r") as firm:
	for line in firm:
		line = line.replace('\n','')
		firmOTUs.append(line)
	rndSampFirmOTUs = random.sample(firmOTUs,10)

for line in fileinput.input(sys.argv[2], inplace=True):
	if '>' not in line and not fileinput.isfirstline():
		line = line.replace('\n','')
	elif not fileinput.isfirstline():
		line = '\n' + line
	print(f'{line}',end="")

with open(sys.argv[2],"r") as OTU:
	rndOTUIDX = []
	for i,line in enumerate(OTU,1):
		line = line.replace('\n','')
		if '>' in line and line[1:] in rndSampFirmOTUs:
			rndOTUIDX.append(i)
			print(line)
		if i-1 in rndOTUIDX:
			j=0
			print(line)

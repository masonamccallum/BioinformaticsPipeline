import sys

sys.path.insert(1,'../')
barFile = sys.argv[1]

seqs = []
bar16S = open("out/16Sbar.fasta","w")
barITS = open("out/ITSbar.fasta","w")

with open(barFile,'r') as barIn:
	dataList = barIn.readlines()
	for i in range(0,len(dataList),2):
		seq ={
			'ID': dataList[i].strip('\n'),
			'barcode' : dataList[i+1].strip('\n'),
		}
		if "ITS" in seq['ID']:
			barITS.write(seq['ID']+'\n')
			barITS.write(seq['barcode']+'\n')
		elif "16S" in seq['ID']:
			bar16S.write(seq['ID']+'\n')
			bar16S.write(seq['barcode']+'\n')
		else:
			print(f"{seq['ID']}")
			print(f"{seq['barcode']}")
			

barITS.close()
bar16S.close()

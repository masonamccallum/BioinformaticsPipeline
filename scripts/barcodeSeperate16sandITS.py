import sys

sys.path.insert(1,'../')
barFile = sys.argv[1]

seqs = []
bar16S = open("out/16Sbar.fasta","w")
barITS = open("out/ITSbar.fasta","w")
bar18S = open("out/18Sbar.fasta","w")

with open(barFile,'r') as barIn:
	dataList = barIn.readlines()
	for i in range(0,len(dataList),2):
		seq ={
			'ID': dataList[i].strip('\n'),
			'barcode' : dataList[i+1].strip('\n'),
		}
		if "ITS" in seq['ID']:   #If this is not specified sequences are assumed to be 16s
			barITS.write(seq['ID']+'\n')
			barITS.write(seq['barcode']+'\n')
		if "18S" in seq['ID']:
			bar18S.write(seq['ID']+'\n')
			bar18S.write(seq['barcode']+'\n')
		else:
			bar16S.write(seq['ID']+'\n')
			bar16S.write(seq['barcode']+'\n')

barITS.close()
bar16S.close()
bar18S.close()

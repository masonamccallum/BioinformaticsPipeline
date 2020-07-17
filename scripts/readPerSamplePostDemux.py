import sys
import re
import matplotlib.pyplot as plt
import numpy as np
import statistics
import pandas as pd

#sys.path.insert(1,'../')


count = {}
#with open('/home/jeffbrady/Analysis/20105Brd/out/fwd_demux.fastq','r') as data:
with open(sys.argv[1],'r') as data:
	print('Starting Count of reads per sample')
	dataList = data.readlines()
	for i in range(0,len(dataList),4):
		print(f'{i} of {len(dataList)}\r',end="")
		seq ={
			'ID': dataList[i].strip('\n'),
		}
		trim1 = seq['ID'].split('sample=>',1)[1]
		trim2 = trim1.split(';',1)[0]
		if count.get(trim2) is None:
			count[trim2] = [1]
		else:
			count[trim2][0] += 1
data = pd.DataFrame.from_dict(count, orient='index',columns=['count'])
pd.set_option('display.max_rows', None)
data.sort_values(by=['count'], inplace=True, ascending=False)
print(data)

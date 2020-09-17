import time
import os
import sys

rankOptions = ['d','p','c','o','f','g']
fileToFix = sys.argv[1]

def badLine(line):
	r= "Uniq[0-9]*;size=[0-9]*;\t([dpcofg]:(\"?).*(\"?)\(.{6}\).){6}\+\t([dpcofg]:(\"?).*(\"?)(,?)){6}"
	if re.search(r,line):
		return False 
	else:
		return True 

def printTaxonomy(line):
	lineData = {}
	lineData.update({"Name":line.split(':',1)[0].split('\t',1)[0]})
	lineData.update({'taxonomy':{}})
	rank = line.split('\t')[1].split(',')
	for r in rank:
		level = r.split(':',1)[0]
		taxa = r.split(':',1)[1].split('(')[0]
		conf = r.split('(')[1].split(')')[0]
		lineData['taxonomy'].update({level:(taxa,conf)})
	for r in rankOptions:
		if r not in lineData['taxonomy'].keys():
			lineData['taxonomy'].update({r:('__unknown__','1.0000')})
	output = ""
	output += lineData['Name'] + '\t'
	for i,r in list(enumerate(rankOptions)):
		output += r + ':'
		output += lineData['taxonomy'].get(r)[0]
		output += '(' + lineData['taxonomy'].get(r)[1] + ')'
		if i < len(rankOptions) - 1:
			output += ','
	output += '\t+\t'
	for i,r in list(enumerate(rankOptions)):
		output += r + ':'
		output += lineData['taxonomy'].get(r)[0]
		if i < len(rankOptions) - 1:
			output += ','
	return output

import re
i = 0
with open(fileToFix, "r") as file:
	for line in file:
		#if re.search('^.*\s+\s$',line):
		if badLine(line):
			i+=1
			line = printTaxonomy(line)
		line = line.strip("\n")
		print(line)

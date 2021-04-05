#python 97_otu_taxonomy.txt tabOTU.txt > taxonTabClosedOTU.txt
# This will add greengenes taxonomy to your closed reference OTU table

import subprocess
import time
import os
import sys
import fileinput
import re

ggTaxonFile = sys.argv[1]
tabOTUFile = sys.argv[2]

def findOTUTaxon(otuNumber):
    with open(ggTaxonFile,'r') as f:
        for line in f.readlines():
            line = line.split()
            if otuNumber == line[0]:
                return ''.join([str(element) for element in line[1:]])
            

with open(tabOTUFile, "r") as file:
    for line in file:
        otuline = line.split('\t')[0]
        line = line.replace('\n','')
        if otuline == "#OTU ID":
            print(f'{line}\ttaxonomy')
        else:
            otuNumber = otuline
            print(f'{line}\t{findOTUTaxon(otuNumber)}')

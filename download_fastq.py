import os
import synapseclient
import synapseutils
import argparse
import re

syn = synapseclient.login()

parser = argparse.ArgumentParser()
parser.add_argument("-synId", "--synId",  help="Proivde synapse Id of fastq files")
parser.add_argument("-sampleId", "--sampleId",  help="Proivde sample Id")
args = parser.parse_args()
print('syn id:', args.synId)
print('sample id:', args.sampleId)

dirName = './'

c = 0
walkedPath = synapseutils.walk(syn, args.synId)
for dirpath, dirname, filename in walkedPath:
	for (inFileName,inFileSynId) in filename:
		downloadDir = dirName
		if args.sampleId in inFileName:
			print('in if:', inFileName)
			entity = syn.get(inFileSynId, downloadLocation = dirName)
		c += 1

print ('c:', c)

exit()

import os
import glob
import re
import time
import subprocess
import argparse


#python run.py -studyName STUDYNAME -metaFile metaFile.txt -synId SYNID
parser = argparse.ArgumentParser()
parser.add_argument("-studyName", "--studyName",  help="Proivde study name")
parser.add_argument("-metaFile", "--metaFile",  help="Proivde meta file which has sample info")
parser.add_argument("-synId", "--synId",  help="Proivde synapss ID of fastq files")
args = parser.parse_args()
print('syn id:', args.synId)

studyName = args.studyName
metaFile = args.metaFile
#synapse ID for the location of fastq files
synId = args.synId

#name of script used with qsub
jobScript = 'jobscript.sh'

#make a directory for log files
folderId = studyName
#get the current dir to pass to the jobscript as the master dir. the master dir is the dir for the master node and has the scripts to be copied to each compute node
masterDir = os.getcwd()


#read the meta file and run the snakemake pipeline for each sample
#the meta files are different per each study so will need to change below to find the sample names and age and models if exist
k = 0
with open(metaFile, 'r') as handler:
	for line in handler:
		line = line.strip()
		#skip header line
		if re.search(r'individualID', line):
			continue
		s1 = line.split('\t')
		#read traits
		indivId = s1[0]
		age = s1[2]
		model = s1[3]
		if model == 'APP/PS1':#this line is specific for this example
			model = 'Het'
		#assign a sample ID
		sampleId = model + age + indivId
		print ('sampleId:', sampleId)
		#assign a job name to follow when running on servers
		jobName = 'j'+sampleId
		print ('jobName:', jobName)

		#call jobscript/snakemake for this  file using qsub if using Amazon compute nodes
		if 0:
			cmd = 'qsub -pe smp 1 -N ' + jobName + ' ' + jobScript + ' ' + masterDir + ' ' + folderId + ' ' + sampleId + ' ' + synId
			print ('cmd:', cmd)
			os.system(cmd)
		#call jobscript/snakemake without qsub
		if 1:
			cmd = 'sh '  + jobScript + ' ' + masterDir + ' ' + folderId + ' ' + sampleId + ' ' + synId
			print('cmd:', cmd)
			os.system(cmd)

		#break if needed
		#k = k + 1
		#if k == 1:
		#	break


exit()

import os
import glob
import re
import time
import urllib.request
from datetime import datetime
#$snakemakeCmd --force  -j --nolock --config masterDir=$MASTERDIR  folderId=$FOLDERID sampleId=$SAMPLEID jobDir=$JOBDIR fastqFolder=$FASTQDIR


masterDir = config['masterDir']
folderId = config["folderId"]
sampleId = str(config["sampleId"])
jobDir = config["jobDir"]
fastqFolder = config["fastqFolder"]
print ('masterDir:', masterDir, 'folderId:',folderId,'sampleId:', sampleId, 'fastqFolder:', fastqFolder)

timeFile = sampleId +'_snake_timing.txt'


rule all:
	input:
		a=expand('{sampleId}_files_copied.txt', sampleId=sampleId)

#rule copy_fastq_files:
#	input:
#		a = 'need.txt'
#	output:
#		a = '/scratch/{sampleId}_fastq'
#	run:
		#make a fastq dir
#		fastqDir = '/scratch/' + wildcards.sampleId + '_fastq'
#		cmd = 'mkdir ' + fastqDir
#		os.system(cmd)
#		fastqFileName = wildcards.sampleId + '_1.fastq.gz'
#		print('fastqFile:', fastqFileName)
#		cmd = 'cp ' + fastqFolder + '/' + fastqFileName + ' ' + fastqDir
#		os.system(cmd)
#		fastqFileName = wildcards.sampleId + '_2.fastq.gz'
#		print('fastqFile:', fastqFileName)
#		cmd = 'cp ' + fastqFolder + '/' + fastqFileName + ' ' + fastqDir
#		os.system(cmd)


rule run_FastQC:
	input:
		a = 'fastq_files'
	output:
		a = directory('{sampleId}_FastQC')
	run:
		#path to fastqc cmd
		fastQCCmd = 'path_to/FastQC/fastqc '
		os.system('mkdir ' + output.a)
		currTime = str(datetime.now())
		os.system("echo 'before FastQC '" + currTime + " >> " + timeFile)
		#get the fastq files
		for file in os.listdir(input.a):
			if file == 'download_fastq.py':
				continue
			cmd = fastQCCmd + input.a + '/' + file + ' -o ' + output.a
			os.system(cmd)

		currTime = str(datetime.now())
		os.system("echo 'after FastQC '" + currTime + " >> " + timeFile)


rule align_star:
	input:
		a = '{sampleId}_FastQC',
		b = 'fastq_files'
	output:
		a = '{sampleId}_STAR_ReadsPerGene.out.tab'
	run:
		starPath = '/PATHTOSTAR/'
		genomeDir = 'STAR_MM10'
		outNamePrefix = wildcards.sampleId + '_STAR_'
		gtfFileName = 'mm10_ERCC92_tab.gtf'#mouse
		numThreads = 16
		fastqFile_1 = ''
		fastqFile_2 = ''
		c = 0
		for file in os.listdir(input.b):
			if re.search(r'_1.fastq.gz', file):
				fastqFile_1 = input.b + '/' + file
				c += 1
			elif re.search(r'_2.fastq.gz', file):
				fastqFile_2 = input.b + '/' + file
				c += 1

		print ('c:',c)
		starCmd = ''
		print ('fastq 1:', fastqFile_1,'fastq 2:', fastqFile_2)
		if c == 1:
			starCmd = starPath + 'STAR' + ' --runThreadN ' + str(numThreads) + ' --genomeDir ' + genomeDir + ' --sjdbGTFfile  ' + gtfFileName + ' --quantMode GeneCounts ' + ' --readFilesCommand zcat ' + ' --outSAMtype BAM SortedByCoordinate --outFileNamePrefix ' +  outNamePrefix + ' --readFilesIn ' + fastqFile_1
		elif c == 2:
			starCmd = starPath + 'STAR' + ' --runThreadN ' + str(numThreads) + ' --genomeDir ' + genomeDir + ' --sjdbGTFfile  ' + gtfFileName + ' --quantMode GeneCounts ' + ' --readFilesCommand zcat ' + ' --outSAMtype BAM SortedByCoordinate --outFileNamePrefix ' +  outNamePrefix + ' --readFilesIn ' + fastqFile_1 + ' ' + fastqFile_2
		else:
			print ('more than two fastq files')
			exit()

		print('STAR cmd:', starCmd)
		currTime = str(datetime.now())
		os.system("echo 'before STAR ' " + currTime + " >> " + timeFile)
		os.system(starCmd)
		currTime = str(datetime.now())
		os.system("echo 'after STAR ' " + currTime + " >> " + timeFile)

rule upload_files_S3:
	input:
		a = '{sampleId}_STAR_ReadsPerGene.out.tab'
	output:
		a = '{sampleId}_files_copied.txt'
	run:
		print ('Copying files')
		os.system("echo 'Copying following files:' >> " + output.a + "\n")
		#create an S3 folder on amazon
		s3Folder='s3://FOLDER/'
		s3JobFolder='s3://FOLDER/' + folderId
		s3SampleFolder=s3JobFolder + '/' + sampleId
		#go thru files/folders in directory
		for file in glob.glob("*"):
			print('file:', file)
			#upload the fastQC folder files
			if re.search(r'FastQC', file):
				print ('fastqc:', file)
				#store the fastq files to the folder after looping in it
				for fName in os.listdir(file):
					upFile = os.path.join(file,fName)
					cpCmd = 'aws s3 cp ' + upFile + ' ' + s3SampleFolder + '/FastQC/' + fName
					print('fastqc cpCmd:', cpCmd)
					os.system(cpCmd)
					cmd = "echo uploading '" + fName + " ' >> " + output.a
					os.system(cmd)
				continue

			#uplaod STAR files
			if 1:
				if re.search(r'STAR', file):
					print ('STAR file:',file)
					if re.search(r'STAR_MM10', file):
						continue
					if re.search(r'STARgenome', file):
						continue
					#if re.search(r'sortedByCoord.out.bam', file):
					#	continue
					cpCmd = 'aws s3 cp ' + file + ' ' + s3SampleFolder + '/STAR/' + file
					print('STAR cp cmd:', cpCmd)
					os.system(cpCmd)
					cmd = "echo uploading '" + file + " ' >> " + output.a
					os.system(cmd)
					#also copy the count files to the main folder
					if re.search(r'ReadsPerGene.out.tab', file):
						cpCmd = 'aws s3 cp ' + file + ' ' + s3SampleFolder +  '/' + file
						os.system(cpCmd)
					continue

		#copy the meta file
		#metaFile
		#copy back to home directory
		os.system("cp " + output.a + ' ' + jobDir)
		currTime = str(datetime.now())
		os.system("echo 'after uploading files ' " + currTime + " >> " + timeFile)
		#copy the time file back
		cpCmd = 'aws s3 cp ' + timeFile + ' ' + s3SampleFolder + '/' + timeFile
		os.system(cpCmd)

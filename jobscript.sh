#!/bin/sh

#cmd = 'qsub -pe smp 1 -N ' + jobName + ' ' + jobScript + ' ' + masterDir + ' ' + folderId + ' ' + sampleId + ' ' + synId
MASTERDIR=$1
FOLDERID=$2
SAMPLEID=$3
#the synapse ID
SYNID=$4

#assign the tmp dir on the tmp node. this could be /tmp or /scratch
export TMPDIR='../scratch'

#move to tmp/scratch dir
cd $TMPDIR

#make a job dir on the compute compute node TMPDIR
JOBDIR=$FOLDERID'_'$SAMPLEID
echo 'JOBDIR:' $JOBDIR
mkdir $JOBDIR

#move to the job dir
cd $JOBDIR

#create a log file
logFile=./$FOLDERID'_'$SAMPLEID'_log.txt'
echo $logFile
touch $logFile
echo "Hostname: $(hostname)" > $logFile

#create a fastq folder
FASTQDIR='fastq_files'
mkdir $FASTQDIR

#move into fastq folder
cd $FASTQDIR
#copy and call the downalod fastq script
downloadFastqName='download_fastq.py'
scp $MASTERDIR'/'$downloadFastqName './'

#call the download script
python download_fastq.py -synId $SYNID -sampleId $SAMPLEID

#move back to job folder
cd ..


#cp the snake file to tmpdir
scp $MASTERDIR'/Snakefile' './'

#: <<'END'
#check if the STAR_MM10 directory exists. We used S3 to store the STAR index files
t=$(date +%F_%T)
echo "Before calling aws copy $t" >> $logFile
STARDIR='STAR_MM10'
if [ ! -d "$STARDIR" ]; then
  echo "Creating STAR dir" >> $logFile
  mkdir $STARDIR
  #copy the the STAR index files from amazon S3
  aws s3 cp s3://STARDIR/STARINDEX ./
  #copy gtf files
  aws s3 cp s3://STARDIR/GTFFILE ./
else
  echo "STAR dir already EXISTS, checking if files exist" >> $logFile

fi
t=$(date +%F_%T)
echo "After calling aws copy $t" >> $logFile
#END

t=$(date +%F_%T)
echo "Before calling Snakemake $t" >> $logFile

#the  snakemake command
snakemakeCmd=snakemake
$snakemakeCmd --force  -j --nolock --config masterDir=$MASTERDIR  folderId=$FOLDERID sampleId=$SAMPLEID jobDir=$JOBDIR fastqFolder=$FASTQDIR
t=$(date +%F_%T)
echo "After calling Snakemake $t" >> $logFile

exit 0

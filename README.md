# crossSpecies_RNAseq
Requirements:

synapseclient:
You can install synapseclient from: https://python-docs.synapse.org/build/html/index.html

synapseclient credentials:
To upload files to the synapse portal you need to create an account on synpase. Otherwise you can choose a different place to upload files like
AWS S3. To upload files to AWS S3 you will need an AWS account and set up aws-cli

snakemake:
You can install snakemake from: https://snakemake.readthedocs.io/en/stable/getting_started/installation.html

snakemake file command paths:
Assign the path to the FastQC command

main steps of the code is:
- Example: python run.py -studyName STUDYNAME -metaFile METAFILE.txt -synId SYNID
Here SYNID is the ID of the folder on the synapse portal where the fastq files are stored.

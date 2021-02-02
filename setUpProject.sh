#!/bin/bash
clear
source ~/anaconda3/etc/profile.d/conda.sh
conda activate

if [ "$1" == "" ] || [ "$2" == "" ]; then
	echo 'You must specify a project directory and the Sequence Run Folder'
	exit
fi

projFold=$1
seqData=$2
cd $projFold

if [ -d 'scripts' ]; then
	echo 'Project has already been intialized'
	echo 'Are you sure you want to reinit this project?'
	echo 'Unsaved data will be lost'
	echo '1: Yes'
	echo '2: No'
	read choice
	if [ $choice != "1" ]; then
		echo 'reInit canceled'
		exit
	fi
fi
shopt -s extglob

if [ -f "mappingData.txt" ]; then
	rm -vrf !(mappingData.txt)
else
	echo "not correct dir"
	exit
fi


if [ ! -f 'mappingData.txt' ]; then
	echo "You must have a mappingData.txt file in this directory before it can be initialized"
	exit
fi

rm -rf out
mkdir -p out
mkdir -p out/rawData
mkdir -p out/rawData/16S
mkdir -p out/rawData/ITS
mkdir -p out/ITS
mkdir -p out/16S
mkdir -p out/16S/OTU
mkdir -p out/16S/ZOTU
mkdir -p out/ITS/OTU
mkdir -p out/ITS/ZOTU
git clone https://github.com/masonamccallum/BioinformaticsPipeline.git
mv BioinformaticsPipeline/* .
rm -rf BioinformaticsPipeline

# copy refDataOver

$usearch -fastq_join $seqData/index1.fastq -reverse $seqData/index2.fastq -join_padgap\
	"" -threads 1 -fastqout out/rawData/indices.fastq

while IFS=$'\t' read -r -a line
do
	echo ">${line[0]}" >> out/bar.fasta
	echo "${line[1]}" >> out/bar.fasta
done < mappingData.txt


echo 'Running python scripts to reformat barcode files'
python scripts/reformatBarcodes.py out/bar.fasta > out/barTemp.fasta
cat out/barTemp.fasta > out/bar.fasta
rm out/barTemp.fasta
python scripts/barcodeSeperate16sandITS.py out/bar.fasta

$usearch -fastx_demux $seqData/read1.fastq -reverse $seqData/read2.fastq\
	-index out/rawData/indices.fastq -barcodes out/16Sbar.fasta\
	-fastqout out/rawData/demux_R1_16S.fastq -output2 out/rawData/demux_R2_16S.fastq

$usearch -fastx_demux $seqData/read1.fastq -reverse $seqData/read2.fastq\
	-index out/rawData/indices.fastq -barcodes out/ITSbar.fasta\
	-fastqout out/rawData/demux_R1_ITS.fastq -output2 out/rawData/demux_R2_ITS.fastq

conda deactivate

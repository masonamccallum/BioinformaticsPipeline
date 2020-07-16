#!/bin/bash
clear
echo 'Begin Analysis'
echo $(date)

echo -ne "\e[97m"
echo "===================================================================================="
echo "=                        Setup                                                     =" 
echo "===================================================================================="
echo -ne "\e[0m"

if [ x$usearch == x ] ; then
	echo Must set \$usearch
	exit 1
fi

if [ "$1" == "" ]
then
	echo 'What is the file path to your data?'
	read data
else
	data=$1
fi

# making directory structure
mkdir -p $data/AnalysisSummary/
mkdir -p $data/out
if [ ! -d $data ]; then
	echo "Data directory is invalid"
	exit
elif [ ! -f $data'/raw/index1.fastq' ]; then
	echo "index1.fastq not found"	
	exit
elif [ ! -f $data'/raw/index2.fastq' ]; then
	echo "index2.fastq not found"	
	exit
elif [ ! -f $data'/raw/read1.fastq' ]; then
	echo "read1.fastq not found"	
	exit
elif [ ! -f $data'/raw/read2.fastq' ]; then
	echo "read2.fastq not found"	
	exit
elif [ ! -f $data'/mappingData.txt' ]; then
	echo "mappingData.txt not found"	
	exit
fi

clear

echo -ne "\e[97m"
echo 'Where would you like the analysis to start?'
echo '1: Full Analysis (All Steps)'
echo '2: demultiplex'
echo '3: Data prep (merge,filter,unique)'
echo '4: Create otu/zotu/tables'
echo '5: taxonomy prediction'
#echo '7: Seperate 16s from ITS and trim primer'

read choice

clear

echo 'Select ITS or 16s'
echo '1: ITS'
echo '2: 16s'
#echo '3: 18s'

read section

logfile= $data/out/out.log
touch logfile
echo $(date "+%d-%m-%y") > logfile

case $section in
	1)
		echo "ITS"
	;;
	2)
		echo "16s"
	;;
	*)
		echo "Not Supported"
		exit
	;;
esac

echo -ne "\e[0m"
clear

if [ $choice -le 1 ]
then
echo -ne "\e[97m"
echo "===================================================================================="
echo "=                         Create index and barcode files                           ="
echo "===================================================================================="
echo -ne "\e[0m"

	rm -f $data/out/*
	# join index files to indices file
	$usearch -fastq_join $data/raw/index1.fastq -reverse $data/raw/index2.fastq -join_padgap\
		"" -threads 1 -fastqout $data/out/indices.fastq | tee -ai logfile

	# createBarcode file
	while IFS=$'\t' read -r -a line
	do
		echo ">${line[0]}" >> $data/out/bar.fasta	
		echo "${line[1]}" >> $data/out/bar.fasta
	done < $data/mappingData.txt

	# fix barcode file
	python scripts/reformatBarcodes.py >> $data/out/bar.fasta

fi

if [ $choice -le 2 ]
then
echo -ne "\e[97m"
echo "====================================================================================" | tee -ai logfile
echo "=                         Demultiplex                                              =" | tee -ai logfile
echo "====================================================================================" | tee -ai logfile
echo -ne "\e[0m"
	$usearch -fastx_demux $data/raw/read1.fastq -reverse $data/raw/read2.fastq\
		-index $data/out/indices.fastq -barcodes $data/out/bar.fasta\
		-fastqout $data/out/demux_R1.fastq -output2 $data/out/demux_R2.fastq | tee -ai logfile
	$usearch -fastx_info $data/out/demux_R1.fastq | tee -ai logfile
fi


if [ $choice -le 3 ]
then
echo -ne "\e[97m"
echo "====================================================================================" | tee -ai logfile
echo "=                         Data Prep                                                =" | tee -ai logfile
echo "====================================================================================" | tee -ai logfile
echo -ne "\e[0m"
	$usearch -fastq_mergepairs $data/out/demux_R1.fastq \
		-fastq_maxdiffs 5 -fastqout $data/out/merged.fastq | tee -ai logfile

	$usearch -fastq_filter $data/out/merged.fastq -fastq_maxee 1.0\
		-fastaout $data/out/filtered.fasta  | tee -ai logfile

	$usearch8 -search_pcr $data/out/filtered.fasta -db $data/refData/primer16s.fasta -strand both \
		-maxdiffs 3 -minamp 225 -maxamp 325 -pcr_strip_primers -ampout $data/out/filtered16s.fasta | tee -ai logfile
	
	#$usearch -fastx_truncate $data/out/merged.fastq -stripleft 19 -stripright 20 \
	#	-fastqout $data/out/strippedMerged.fastq

	$usearch -fastx_uniques $data/out/filtered16s.fasta -fastaout $data/out/uniques.fasta\
	-sizeout -relabel Uniq  | tee -ai logfile
fi

if [ $choice -le 4 ]
then
echo -ne "\e[97m"
echo "====================================================================================" | tee -ai logfile
echo "=                         Create OTU/ZOTU/Table                                    =" | tee -ai logfile
echo "====================================================================================" | tee -ai logfile
echo -ne "\e[0m"
	$usearch -cluster_otus $data/out/uniques.fasta -minsize 2 \
		-otus $data/out/otus.fasta -relabel Otu | tee -ai logfile

	$usearch -unoise3 $data/out/uniques.fasta -zotus $data/out/zotu.fasta\
		-tabbedout $data/out/unoise3.txt | tee -ai logfile
	
	$usearch -otutab $data/out/merged.fastq -otus $data/out/otus.fasta -otutabout \
		$data/out/otutab.txt | tee -ai logfile
fi

if [ $choice -le 5 ]
then 
echo -ne "\e[97m"
echo "====================================================================================" | tee -ai logfile
echo "=                         Taxonomy Prediction                                      =" | tee -ai logfile
echo "====================================================================================" | tee -ai logfile
echo -ne "\e[0m"
	$usearch -sintax $data/out/otus.fasta -db $data/refData/rdp_16s_v16.fa \
		-tabbedout $data/out/reads.sintax -strand both -sintax_cutoff 0.8 | tee -ai logfile
	
	# python sintax file correction
	python scripts/fixSintax.py $data/out/reads.sintax | tee -ai logfile

	$usearch -sintax_summary $data/out/reads.sintax -otutabin $data/out/otutab.txt \
		-output	$data/out/phylum_summary.txt -rank g | tee -ai logfile

fi

#$usearch -otutab_rare otutab16s.txt -sample_size 5000 -output otutab_5k.txt

if [ $choice -le -1 ]
then
echo -ne "\e[97m"
echo "===================================================================================="
echo "=                         Conclusion                                               ="
echo "===================================================================================="
echo ""
echo "===================================================================================="
echo "=                                                                                  ="
echo "=                                                                                  ="
echo "=        When this feature is complete there will be stats on this run here        ="
echo "=                                                                                  ="
echo "=                                                                                  ="
echo "===================================================================================="
echo 'How would you like to conlcude this run?'
echo '1: Delete run'
echo '2: Save run'
read choice
echo -ne "\e[0m"

if [ $choice == 2 ]
then
echo 'the saving feature is not complete.'
exit
num=0
	echo 'Who is saving this data?'
	read name
while [ -d  $data/AnalysisSummary/$(date "+%d-%m-%y").$name.$num ]
do
	num=$((num + 1))
done
	#mkdir $data/AnalysisSummary/$(date "+%d-%m-%y").$name.$num
	#echo 'What is significant about this run? this will be stored with saved data?'
	#read sig
	#clear
	#echo $sig >> $data/AnalysisSummary/$(date "+%d-%m-%y").$name.$num/README.md
	#save=AnalysisSummary/$(date "+%d-%m-%y").$name.$num
	#cd $data
	# tar -zcvf dataCompress.tar --full-time out 
	# tar cf - $data/out -P | pv -s $(du -sb $data/out | awk '{print $1}') | gzip > big-files.tar.gz
	# mv dataCompress.tar ../$save
	#tar --totals=USR1 -czvf dataCompress.tar out
fi
fi

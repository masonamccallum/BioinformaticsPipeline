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

echo -ne "\e[97m"
echo 'Where would you like the analysis to start?'
echo '1: Full Analysis (All Steps)'
echo '2: demultiplex'
echo '3: Data prep (merge,filter,unique)'
echo '4: Create otu/zotu/tables'
echo '5: taxonomy prediction'

read choice

clear

echo 'Select ITS or 16s'
echo '1: ITS'
echo '2: 16s'
#echo '3: 18s'

read section
case $section in
	1)
		section='ITS'
	;;
	2)
		section='16s'
	;;
	*)
		echo "Not Supported"
		exit
	;;
esac

echo -ne "\e[0m"

# making directory structure
mkdir -p $data/$section
out=$data/$section/out
echo $data
mkdir -p $out
if [ ! -d $data ]; then
	echo "data directory is invalid"
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

if [ $choice -le 1 ]
then
echo -ne "\e[97m"
echo "===================================================================================="
echo "=                         Create index and barcode files                           ="
echo "===================================================================================="
echo -ne "\e[0m"

	rm -f $out/*
	# join index files to indices file
	$usearch -fastq_join $data/raw/index1.fastq -reverse $data/raw/index2.fastq -join_padgap\
		"" -threads 1 -fastqout $out/indices.fastq

	# createBarcode file
	while IFS=$'\t' read -r -a line
	do
		echo ">${line[0]}" >> $out/bar.fasta	
		echo "${line[1]}" >> $out/bar.fasta
	done < $data/mappingData.txt

	# fix barcode file
	python scripts/reformatBarcodes.py >> $out/bar.fasta

fi

if [ $choice -le 2 ]
then
echo -ne "\e[97m"
echo "===================================================================================="
echo "=                         Demultiplex                                              ="
echo "===================================================================================="
echo -ne "\e[0m"
	$usearch -fastx_demux $data/raw/read1.fastq -reverse $data/raw/read2.fastq\
		-index $out/indices.fastq -barcodes $out/bar.fasta\
		-fastqout $out/demux_R1.fastq -output2 $out/demux_R2.fastq
	$usearch -fastx_info $out/demux_R1.fastq
fi


if [ $choice -le 3 ]
then
echo -ne "\e[97m"
echo "===================================================================================="
echo "=                         Data Prep                                                ="
echo "===================================================================================="
echo -ne "\e[0m"
	$usearch -fastq_mergepairs $out/demux_R1.fastq \
		-fastq_maxdiffs 5 -fastqout $out/merged.fastq

	$usearch -fastq_filter $out/merged.fastq -fastq_maxee 1.0 \
		-fastaout $out/filtered.fasta 

	$usearch8 -search_pcr $out/filtered.fasta -db $data/refData/primer16s.fasta -strand both \
		-maxdiffs 3 -minamp 225 -maxamp 325 -pcr_strip_primers -ampout $out/filtered16s.fasta
	
	#$usearch -fastx_truncate $out/merged.fastq -stripleft 19 -stripright 20 \
	#	-fastqout $out/strippedMerged.fastq

	$usearch -fastx_uniques $out/filtered16s.fasta -fastaout $out/uniques.fasta\
	-sizeout -relabel Uniq 
fi

if [ $choice -le 4 ]
then
echo -ne "\e[97m"
echo "===================================================================================="
echo "=                         Create OTU/ZOTU/Table                                    ="
echo "===================================================================================="
echo -ne "\e[0m"
	$usearch -cluster_otus $out/uniques.fasta -minsize 2 \
		-otus $out/otus.fasta -relabel Otu

	$usearch -unoise3 $out/uniques.fasta -zotus $out/zotu.fasta\
		-tabbedout $out/unoise3.txt
	
	$usearch -otutab $out/merged.fastq -otus $out/otus.fasta -otutabout \
		$out/otutab.txt
fi

if [ $choice -le 5 ]
then 
echo -ne "\e[97m"
echo "===================================================================================="
echo "=                         Taxonomy Prediction                                      ="
echo "===================================================================================="
echo -ne "\e[0m"
	$usearch -sintax $out/otus.fasta -db $data/refData/rdp_16s_v16.fa \
		-tabbedout $out/reads.sintax -strand both -sintax_cutoff 0.8
	
	# python sintax file correction
	python scripts/fixSintax.py $out/reads.sintax

	$usearch -sintax_summary $out/reads.sintax -otutabin $out/otutab.txt \
		-output	$out/phylum_summary.txt -rank g

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
	# tar cf - $out -P | pv -s $(du -sb $out | awk '{print $1}') | gzip > big-files.tar.gz
	# mv dataCompress.tar ../$save
	#tar --totals=USR1 -czvf dataCompress.tar out
fi
fi

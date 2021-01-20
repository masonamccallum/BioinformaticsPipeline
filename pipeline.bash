#!/bin/bash
clear
echo 'Begin Analysis'
echo $(date)
source ~/anaconda3/etc/profile.d/conda.sh
conda activate

echo -ne "\e[97m"
echo "===================================================================================="
echo "=                        Setup                                                     =" 
echo "===================================================================================="
echo -ne "\e[0m"

if [ x$usearch == x ] ; then
	echo Must set \$usearch
	exit 1
fi

echo -ne "\e[97m"
echo 'Where would you like the analysis to start?'
echo '3: Data prep (merge,filter,unique)'
echo '4: Create otu/zotu/tables'
echo '5: Downstream Analysis'

read choice
clear

echo 'Which trimming method would you prefer?'
echo '1: Usearch trimming (Method that trims each individual sequence at specified quality along its sequence)'
echo '2: Flat trim (Method that trims all sequences the same at a specified bp)'

read trimtype
case $trimtype in
	1)
		trimtype='usearch'
	;;
	2)
		trimtype='flattrim'
	;;
	*)
		echo "Not Supported"
		exit
	;;
esac
clear
echo 'Select ITS or 16s'
echo '1: ITS'
echo '2: 16S'
echo '3: 18s'

read section
case $section in
	1)
		section='ITS'
	;;
	2)
		section='16S'
	;;
	*)
		echo "Not Supported"
		exit
	;;
esac
clear
echo -ne "\e[0m"

if [ $choice -le 5 ]
then 
echo -ne "\e[97m"
	echo 'Which type of otu would you like to use?'
	echo '1) OTU'
	echo '2) ZOTU'
	read otutype
	echo $otutype
	if [ "1" == "$otutype" ]; then
		otutype="OTU"
	elif [ "2" == "$otutype" ]; then
		otutype="ZOTU"
	else
		echo "error selecting otu type"
		exit
	fi

	echo 'Which reference Database will be used for taxon prediction?'
	ls ~/refData | grep ".db"
	read database
echo -ne "\e[0m"
fi

clear

if [ $choice -le 3 ]
then
echo -ne "\e[97m"
echo "===================================================================================="
echo "=                         Data Prep                                                ="
echo "===================================================================================="
echo -ne "\e[0m"

echo $trimtype

if [ $trimtype == "usearch" ]
then
	echo 'Starting Usearch merge and trim'
	$usearch -fastq_mergepairs out/rawData/demux_R1_$section.fastq \
		-fastq_maxdiffs 25 -fastq_trunctail 10 -fastqout out/$section/merged.fastq
fi

if [ $trimtype == "flattrim" ]
then
	echo 'Starting flattrim'
	echo 'What would you like to trim the forward sequence to?'
	read trimLenForward
	echo 'What would you like to trim the reverse sequence to?'
	read trimLenReverse

	$usearch -fastx_truncate out/rawData/demux_R1_$section.fastq -trunclen $trimLenForward -fastqout out/rawData/reads1Trunc.fastq
	$usearch -fastx_truncate out/rawData/demux_R2_$section.fastq -trunclen $trimLenReverse -fastqout out/rawData/reads2Trunc.fastq
	conda activate py2	
	python scripts/fastqCombinePariedEnd.py out/rawData/reads1Trunc.fastq out/rawData/reads2Trunc.fastq
	conda deactivate
	$usearch -fastx_syncpairs out/rawData/reads1Trunc.fastq_pairs_R1.fastq -reverse out/rawData/reads2Trunc.fastq_pairs_R2.fastq -output out/$section/fwd_sorted.fastq -output2 out/$section/rev_sorted.fastq
	$usearch -fastq_mergepairs out/$section/fwd_sorted.fastq -reverse out/$section/rev_sorted.fastq -fastqout out/$section/merged.fastq	
fi
	$usearch -fastq_filter out/$section/merged.fastq -fastq_maxee 1.0\
		-fastaout out/$section/filtered.fasta

	$usearch8 -search_pcr out/$section/filtered.fasta -db ~/refData/primer$section.fasta -strand both \
		-maxdiffs 3 -minamp 225 -maxamp 325 -pcr_strip_primers -ampout out/$section/filteredSeq.fasta
	
	$usearch -fastx_truncate out/$section/merged.fastq -stripleft 19 -stripright 20 \
		-fastaout out/$section/strippedMerged.fasta

	$usearch -fastx_uniques out/$section/strippedMerged.fasta -fastaout out/$section/uniques.fasta\
		-sizeout -relabel Uniq 

	#$usearch -fastx_uniques out/$section/filtered.fasta -fastaout out/$section/uniques.fasta\
	#	-sizeout -relabel Uniq 
fi

if [ $choice -le 4 ]
then
echo -ne "\e[97m"
echo "===================================================================================="
echo "=                         Create OTU/ZOTU/Table                                    ="
echo "===================================================================================="
echo -ne "\e[0m"
	$usearch -cluster_otus out/$section/uniques.fasta -minsize 2 \
		-otus out/$section/OTU.fasta -relabel Otu

	$usearch -unoise3 out/$section/uniques.fasta -zotus out/$section/ZOTU.fasta\
		-tabbedout out/$section/unoise3.txt
	
	#$usearch -otutab out/merged.fastq -otus out/$section/OTU.fasta -otutabout \
	#	out/$section/tabOTU.txt

	$usearch -otutab out/$section/strippedMerged.fasta -otus out/$section/OTU.fasta -otutabout \
		out/$section/tabOTU.txt

	#$usearch -otutab out/merged.fastq -zotus out/$section/ZOTU.fasta -otutabout \
	#	out/$section/tabZOTU.txt

	$usearch -otutab out/$section/strippedMerged.fasta -zotus out/$section/ZOTU.fasta -otutabout \
		out/$section/tabZOTU.txt
	
	$usearch -otutab_rare out/$section/tabOTU.txt -sample_size 5000 -output \
		out/$section/OTU/OTU_5k_rare.txt

	$usearch -otutab_rare out/$section/tabZOTU.txt -sample_size 5000 -output \
		out/$section/ZOTU/ZOTU_5k_rare.txt
	
fi
if [ $choice -le 5 ]
then 
echo -ne "\e[97m"
echo "===================================================================================="
echo "=                      Downstream Analysis                                         ="
echo "===================================================================================="
echo -ne "\e[0m"
	$usearch -sintax out/$section/$otutype.fasta -db ~/refData/$database \
		-tabbedout out/$section/$otutype/reads.sintax -strand both -sintax_cutoff 0.8
	
	#python sintax file correction
	python scripts/fixSintax.py out/$section/$otutype/reads.sintax > out/$section/$otutype/temp.txt
	cp out/$section/$otutype/temp.txt out/$section/$otutype/reads.sintax

	$usearch -sintax_summary out/$section/$otutype/reads.sintax \
		-otutabin out/$section/tab$otutype.txt \
		-output out/$section/$otutype/phylum_summary.txt -rank p

	$usearch -sintax_summary out/$section/$otutype/reads.sintax \
		-otutabin out/$section/tab$otutype.txt \
		-output out/$section/$otutype/genus_summary.txt -rank g

	$usearch -sintax_summary out/$section/$otutype/reads.sintax \
		-otutabin out/$section/tab$otutype.txt \
		-output out/$section/$otutype/family_summary..txt -rank f

	$usearch -alpha_div	out/$section/$otutype/"$otutype"_5k_rare.txt  -output	out/$section/$otutype/alpha.txt
	$usearch -beta_div out/$section/tab$otutype.txt -filename_prefix out/$section/$otutype/  
	#$usearch -cluster_agg	out/$otutype.fasta -treeout out/$otutype/$otutype.tree
fi
conda deactivate

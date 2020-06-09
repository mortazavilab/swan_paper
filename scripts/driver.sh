# downloading data

# hepg2 rep 1
wget https://www.encodeproject.org/files/ENCFF575ABA/@@download/ENCFF575ABA.bam
mv ENCFF575ABA.bam hepg2_1.bam

# hepg2 rep 2
wget wget https://www.encodeproject.org/files/ENCFF463JKW/@@download/ENCFF463JKW.bam
mv ENCFF463JKW.bam hepg2_2.bam

# hffc6 rep 1
wget https://www.encodeproject.org/files/ENCFF677TYB/@@download/ENCFF677TYB.bam
mv ENCFF677TYB.bam hffc6_1.bam 

# hffc6 rep 2
wget https://www.encodeproject.org/files/ENCFF584UQW/@@download/ENCFF584UQW.bam
mv ENCFF584UQW.bam hffc6_2.bam

# hffc6 rep 3
wget https://www.encodeproject.org/files/ENCFF964PGS/@@download/ENCFF964PGS.bam
mv ENCFF964PGS.bam hffc6_3.bam


# convert to sam 
module load samtools
for file in *.bam;
do
	sam_file=`basename $file .bam`
	sam_file=${sam_file}.sam
	samtools view -h $file > $sam_file
done

# talon label reads
FASTA=~/mortazavi_lab/ref/hg38/hg38.fa
mkdir labelled
for file in *.sam;
do
	base=`basename $file .sam`
	talon_label_reads \
		--f $file \
		--g $FASTA \
		--t 8 \
		--tmpDir ${base}_temp \
		--deleteTmp \
		--o labelled/${base}
done

# init talon db
GTF=~/mortazavi_lab/ref/gencode.v29/gencode.v29.annotation.gtf
talon_initialize_database \
	--f $GTF \
	--g hg38 \
	--a gencode_v29 \
	--l 0 \
	--idprefix TALON \
	--5p 500 \
	--3p 300 \
	--o talon

# make config file to run talon
plat="Sequel"
touch config.csv
for file in labelled/*.sam;
do
	base=`basename $file .sam`
	base="${base::${#base}-8}"
	sample="${base::${#base}-2}"
	printf "${base},${sample},${plat},${file}\n" >> config.csv
done

# run talon
talon \
	--f config.csv \
	--db talon.db \
	--t 16 \
	--build hg38 \
	--cov 0.9 \
	--identity 0.8 \
	--o talon_swan

# filter talon transcripts for each cell line
talon_filter_transcripts \
	--db talon.db \
	-a gencode_v29 \
	--datasets hepg2_1,hepg2_2 \
	--maxFracA 0.5 \
	--minCount 5 \
	--minDatasets 2 \
	--o hepg2_whitelist.csv

talon_filter_transcripts \
	--db talon.db \
	-a gencode_v29 \
	--datasets hffc6_1,hffc6_2,hffc6_3 \
	--maxFracA 0.5 \
	--minCount 5 \
	--minDatasets 2 \
	--o hffc6_whitelist.csv


# obtain a gtf for each replicate
printf "hepg2_1" > dataset_hepg2_1
talon_create_GTF \
	--db talon.db \
	-b hg38 \
	-a gencode_v29 \
	--whitelist hepg2_whitelist.csv \
	--datasets dataset_hepg2_1 \
	--o hepg2_1
printf "hepg2_2" > dataset_hepg2_2
talon_create_GTF \
	--db talon.db \
	-b hg38 \
	-a gencode_v29 \
	--whitelist hepg2_whitelist.csv \
	--datasets dataset_hepg2_2 \
	--o hepg2_2

printf "hffc6_1" > dataset_hffc6_1
talon_create_GTF \
	--db talon.db \
	-b hg38 \
	-a gencode_v29 \
	--whitelist hffc6_whitelist.csv \
	--datasets dataset_hffc6_1 \
	--o hffc6_1
printf "hffc6_2" > dataset_hffc6_2
talon_create_GTF \
	--db talon.db \
	-b hg38 \
	-a gencode_v29 \
	--whitelist hffc6_whitelist.csv \
	--datasets dataset_hffc6_2 \
	--o hffc6_2
printf "hffc6_3" > dataset_hffc6_3
talon_create_GTF \
	--db talon.db \
	-b hg38 \
	-a gencode_v29 \
	--whitelist hffc6_whitelist.csv \
	--datasets dataset_hffc6_3 \
	--o hffc6_3

# obtain a filtered abundance file for each cell line
cat hepg2_whitelist.csv > all_whitelist.csv
cat hffc6_whitelist.csv >> all_whitelist.csv 
sort all_whitelist.csv | uniq > whitelist.csv
talon_abundance \
	--db talon.db \
	-a gencode_v29 \
	-b hg38 \
	--whitelist whitelist.csv \
	--o all

mkdir figures
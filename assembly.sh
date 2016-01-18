#read preparation:
#trimmomatic
java -jar ~/biosoft/read_processing/Trimmomatic-0.32/trimmomatic-0.32.jar PE -phred33 illumina_r1_musket_k17_trimmed_to_50x.fastq illumina_r2_musket_k17_trimmed_to_50x.fastq tt_r1_illumina_80x.fastq tt_r1_illumina_80x_up.fastq tt_r2_illumina_80x.fastq tt_r2_illumina_80x_up.fastq ILLUMINACLIP:TruSeq-PE.fa:2:30:15 TRAILING:30 MINLEN:50

#soap kmer filtering
KmerFreq_HA -k 23 -t 20 -i 100000000 -l ../read.lst -p b10_tt_23mer
Corrector_HA -k 23 -l 2 -e 1 -w 1 -q 30 -t 20 -Q 64 -o 3 b10_tt_23mer.freq.gz ../read.lst


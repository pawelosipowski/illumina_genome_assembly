#assembly script
#18.1.2016 Pawel Osipowski
#folder should contain paired fastq files named like this:
#<read_name>_fw.fq <read_name>_rv.fq

#SYNOPSIS
./assembly.sh read_name

#read preparation:
#trimmomatic
java -jar ./soft/Trimmomatic-0.32/trimmomatic-0.32.jar PE -phred33 "$1"_fw.fq "$1"_rv.fq tt_"$1"_fw.fq tt_"$1"_fw_unpaired.fq tt_"$1"_rv.fq tt_"$1"_rv_unpaired.fq ILLUMINACLIP:TruSeq-PE.fa:2:30:15 TRAILING:30 MINLEN:50

#creating file with read file list for soapdenovo
echo ./"$1"_fw.fq >> "$1".lst
echo ./"$1"_fw_unpaired.fq >> "$1".lst
echo ./"$1"_rv.fq >> "$1".lst
echo ./"$1"_rv_unpaired.fq >> "$1".lst

#soap kmer filtering
./soft/SOAPdenovo2-src-r240/ KmerFreq_HA -k 23 -t 20 -i 100000000 -l ../read.lst -p b10_tt_23mer
Corrector_HA -k 23 -l 2 -e 1 -w 1 -q 30 -t 20 -Q 64 -o 3 b10_tt_23mer.freq.gz ../read.lst


#assembly script
#18.1.2016 Pawel Osipowski
#folder should contain paired fastq files named like this:
#<read_name>_fw.fq <read_name>_rv.fq

#SYNOPSIS
./assembly.sh read_name

#read preparation:
#trimmomatic
java -jar ./soft/Trimmomatic-0.32/trimmomatic-0.32.jar PE -phred33 "$1"_fw.fq "$1"_rv.fq tt_"$1"_fw.fq tt_"$1"_fw_unpaired.fq tt_"$1"_rv.fq tt_"$1"_rv_unpaired.fq ILLUMINACLIP:TruSeq-PE.fa:2:30:15 TRAILING:30 MINLEN:50

#read normalization, kmer error correction and kmer distribution histograms
#bbmap
./bbmap/bbnorm.sh in=./"$1"_fw.fq in2=./"$1"_rv.fq out1=./"$1"_fw_ecc.fq out2=./"$1"_rv_ecc.fq target=40 mindepth=3 ecc cec=t hist=./in_kmer_hist histout=./out_kmer_hist

#creating soapdenovo config file from template
#template is set on 100bp long reads and 300bp insert size
cp ./soft/SOAPdenovo2-bin-LINUX-generic-r240/soap.config ./"$1"_soap.config
echo q1=./"$1"_fw_ecc.fq >> ./"$1"_soap.config
echo q2=./"$1"_rv_ecc.fq >> ./"$1"_soap.config
echo q=./"$1"_fw_ecc_unpaired.fq >> ./"$1"_soap.config
echo q=./"$1"_rv_ecc_unpaired.fq >> ./"$1"_soap.config

#soap kmer filtering
./soft/SOAPdenovo2-src-r240/ KmerFreq_HA -k 23 -t 20 -i 100000000 -l ../read.lst -p b10_tt_23mer
Corrector_HA -k 23 -l 2 -e 1 -w 1 -q 30 -t 20 -Q 64 -o 3 b10_tt_23mer.freq.gz ../read.lst


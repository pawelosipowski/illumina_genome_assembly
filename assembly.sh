#assembly script
#18.1.2016 Pawel Osipowski
#folder should contain paired fastq files named like this:
#<read_name>_fw.fq <read_name>_rv.fq

#in ./soft al the necessary software is already compiled on local server

#SYNOPSIS
#./assembly.sh <read_name> 2&> <read_name>.err

mkdir ./"$1"/

#read adapter trimming, quality trimming and to Phred33 conversion:
#trimmomatic: http://www.usadellab.org/cms/index.php?page=trimmomatic

java -jar ./soft/Trimmomatic-0.35/trimmomatic-0.35.jar PE ./"$1"_fw.fq ./"$1"_rv.fq ./"$1"/tt_"$1"_fw.fq ./"$1"/tt_"$1"_fw_unpaired.fq ./"$1"/tt_"$1"_rv.fq ./"$1"/tt_"$1"_rv_unpaired.fq ILLUMINACLIP:./soft/Trimmomatic-0.35/adapters/TruSeq3-PE.fa:2:30:15 TRAILING:30 MINLEN:50
#mv ./"$1"_fw.fq ./"$1"/
#mv ./"$1"_rv.fq ./"$1"/

#truseq adapter trimming
#bbmap
#./soft/bbmap/bbduk.sh in1="$1"_fw.fq in2="$1"_rv.fq out1="$1"_fw_clean.fq  out2="$1"_rv_clean.fq ref=./soft/bbmap/resources/truseq.fa.gz ktrim=r k=25 mink=11 hdist=1 tpe tbo

#read normalization, kmer error correction and kmer distribution histograms
#bbmap
./soft/bbmap/bbnorm.sh in=./"$1"/tt_"$1"_fw.fq in2=./"$1"/tt_"$1"_rv.fq out1=./"$1"/ecc_"$1"_fw.fq out2=./"$1"/ecc_"$1"_rv.fq target=40 mindepth=3 ecc cec=t hist=./"$1"/kmer_"$1"_in_hist histout=./"$1"/kmer_"$1"_out_hist
./soft/bbmap/bbnorm.sh in=./"$1"/tt_"$1"_fw_unpaired.fq  out=./"$1"/ecc_"$1"_fw_unpaired.fq target=40 mindepth=3 ecc cec=t hist=./"$1"/kmer_"$1"_up_fw_in_hist histout=./"$1"/kmer_"$1"_up_fw_out_hist
./soft/bbmap/bbnorm.sh in=./"$1"/tt_"$1"_rv_unpaired.fq  out=./"$1"/ecc_"$1"_rv_unpaired.fq target=40 mindepth=3 ecc cec=t hist=./"$1"/kmer_"$1"_up_rv_in_hist histout=./"$1"/kmer_"$1"_up_rv_out_hist

#creating soapdenovo config file from template
#template is set on 100bp long reads and 300bp insert size
cp ./soft/SOAPdenovo2-bin-LINUX-generic-r240/soap.config ./"$1"/"$1"_soap.config
echo q1=./"$1"/ecc_"$1"_fw.fq >> ./"$1"/"$1"_soap.config
echo q2=./"$1"/ecc_"$1"_rv.fq >> ./"$1"/"$1"_soap.config
echo q=./"$1"/ecc_"$1"_fw_unpaired.fq >> ./"$1"/"$1"_soap.config
echo q=./"$1"/ecc_"$1"_rv_unpaired.fq >> ./"$1"/"$1"_soap.config

#soap kmer filtering
#KmerFreq_HA -k 23 -t 20 -i 100000000 -l ../read.lst -p b10_tt_23mer
#Corrector_HA -k 23 -l 2 -e 1 -w 1 -q 30 -t 20 -Q 64 -o 3 b10_tt_23mer.freq.gz ../read.lst

#soapdenovo contig assembly
./soft/SOAPdenovo2-bin-LINUX-generic-r240/SOAPdenovo-127mer pregraph -s ./"$1"/"$1"_soap.config -p 20 -o ./"$1"/graph_"$1" #1>./"$1"/soap_"$1"_pregraph.log 2>./"$1"/soap_"$1"_pregraph.err
./soft/SOAPdenovo2-bin-LINUX-generic-r240/SOAPdenovo-127mer contig -s ./"$1"/"$1"_soap.config -p 20 -m 99 -g ./"$1"/graph_"$1" #1>./"$1"/soap_"$1"_contig.log 2>./"$1"/soap_"$1"_contig.err

#assembly statistics
perl ./soft/NGSQCToolkit_v2.3.3/Statistics/N50Stat.pl -i ./"$1"/graph_"$1".contig -o ./"$1"/"$1"_contig.stats

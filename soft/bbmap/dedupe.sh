#!/bin/bash
#dedupe in=<infile> out=<outfile>

usage(){
echo "
Written by Brian Bushnell and Jonathan Rood
Last modified October 27, 2015

Description:  Accepts one or more files containing sets of sequences (reads or scaffolds).
Removes duplicate sequences, which may be specified to be exact matches, subsequences, or sequences within some percent identity.
Can also find overlapping sequences and group them into clusters.

Usage:     dedupe.sh in=<file or stdin> out=<file or stdout>

An example of running Dedupe for clustering short reads:
dedupe.sh in=x.fq am=f ac=f fo c pc rnc=f mcs=4 mo=100 s=1 pto cc qin=33 csf=stats.txt pattern=cluster_%.fq dot=graph.dot

Input may be fasta or fastq, compressed or uncompressed.
Output may be stdout or a file.  With no output parameter, data will be written to stdout.
If 'out=null', there will be no output, but statistics will still be printed.
You can also use 'dedupe <infile> <outfile>' without the 'in=' and 'out='.

I/O Parameters
in=<file,file>        A single file or a comma-delimited list of files.
out=<file>            Destination for all output contigs.
pattern=<file>        Clusters will be written to individual files, where the '%' symbol in the pattern is replaced by cluster number.
outd=<file>           Optional; removed duplicates will go here.
csf=<file>            (clusterstatsfile) Write a list of cluster names and sizes.
dot=<file>            (graph) Write a graph in dot format.  Requires 'fo' and 'pc' flags.
threads=auto          (t) Set number of threads to use; default is number of logical processors.
overwrite=t           (ow) Set to false to force the program to abort rather than overwrite an existing file.
showspeed=t           (ss) Set to 'f' to suppress display of processing speed.
minscaf=0             (ms) Ignore contigs/scaffolds shorter than this.
interleaved=auto      If true, forces fastq input to be paired and interleaved.
ziplevel=2            Set to 1 (lowest) through 9 (max) to change compression level; lower compression is faster.

Output Format Parameters
storename=t           (sn) Store scaffold names (set false to save memory).
#addpairnum=f         Add .1 and .2 to numeric id of read1 and read2.
storequality=t        (sq) Store quality values for fastq assemblies (set false to save memory).
uniquenames=t         (un) Ensure all output scaffolds have unique names.  Uses more memory.
numbergraphnodes=t    (ngn) Label dot graph nodes with read numbers rather than read names.
sort=f                Sort output by scaffold length (otherwise it will be random).
                      'a' for ascending, 'd' for descending, 'f' for false (no sorting).
renameclusters=f      (rnc) Rename contigs to indicate which cluster they are in.
printlengthinedges=f  (ple) Print the length of contigs in edges.

Processing Parameters
absorbrc=t            (arc) Absorb reverse-complements as well as normal orientation.
absorbmatch=t         (am) Absorb exact matches of contigs.
absorbcontainment=t   (ac) Absorb full containments of contigs.
#absorboverlap=f      (ao) Absorb (merge) non-contained overlaps of contigs (TODO).
findoverlap=f         (fo) Find overlaps between contigs (containments and non-containments).  Necessary for clustering.
uniqueonly=f          (uo) If true, all copies of duplicate reads will be discarded, rather than keeping 1.
rmn=f                 (requirematchingnames) If true, both names and sequence must match.
usejni=f              (jni) Do alignments in C code, which is faster, if an edit distance is allowed.
                      This will require compiling the C code; details are in /jni/README.txt.

Subset Parameters
subsetcount=1         (sstc) Number of subsets used to process the data; higher uses less memory.
subset=0              (sst) Only process reads whose ((ID%subsetcount)==subset).

Clustering Parameters
cluster=f             (c) Group overlapping contigs into clusters.
pto=f                 (preventtransitiveoverlaps) Do not look for new edges between nodes in the same cluster.
minclustersize=1      (mcs) Do not output clusters smaller than this.
pbr=f                 (pickbestrepresentative) Only output the single highest-quality read per cluster.

Cluster Postprocessing Parameters
processclusters=f     (pc) Run the cluster processing phase, which performs the selected operations in this category.
fixmultijoins=t       (fmj) Remove redundant overlaps between the same two contigs.
removecycles=t        (rc) Remove all cycles so clusters form trees.
cc=t                  (canonicizeclusters) Flip contigs so clusters have a single orientation.
fcc=f                 (fixcanoncontradictions) Truncate graph at nodes with canonization disputes.
foc=f                 (fixoffsetcontradictions) Truncate graph at nodes with offset disputes.
mst=f                 (maxspanningtree) Remove cyclic edges, leaving only the longest edges that form a tree.

Overlap Detection Parameters
exact=t               (ex) Only allow exact symbol matches.  When false, an 'N' will match any symbol.
touppercase=t         (tuc) Convert input bases to upper-case; otherwise, lower-case will not match.
maxsubs=0             (s) Allow up to this many mismatches (substitutions only, no indels).  May be set higher than maxedits.
maxedits=0            (e) Allow up to this many edits (subs or indels).  Higher is slower.
minidentity=100       (mid) Absorb contained sequences with percent identity of at least this (includes indels).
minlengthpercent=0    (mlp) Smaller contig must be at least this percent of larger contig's length to be absorbed.
minoverlappercent=0   (mop) Overlap must be at least this percent of smaller contig's length to cluster and merge.
minoverlap=200        (mo) Overlap must be at least this long to cluster and merge.
depthratio=0          (dr) When non-zero, overlaps will only be formed between reads with a depth ratio of at most this.
                      Should be above 1.  Depth is determined by parsing the read names; this information can be added
                      by running KmerNormalize (khist.sh, bbnorm.sh, or ecc.sh) with the flag 'rename'
k=31                  Seed length used for finding containments and overlaps.  Anything shorter than k will not be found.
numaffixmaps=1        (nam) Number of prefixes/suffixes to index per contig. Higher is more sensitive, if edits are allowed.
#ignoreaffix1=f       (ia1) Ignore first affix (for testing).
#storesuffix=f        (ss) Store suffix as well as prefix.  Automatically set to true when doing inexact matches.

Other Parameters
forcetrimleft=-1      (ftl) If positive, trim bases to the left of this position (exclusive, 0-based).
forcetrimright=-1     (ftr) If positive, trim bases to the right of this position (exclusive, 0-based).

Java Parameters:
-Xmx                  This will be passed to Java to set memory usage, overriding the program's automatic memory detection.
                      -Xmx20g will specify 20 gigs of RAM, and -Xmx200m will specify 200 megs.  The max is typically 85% of physical memory.

Please contact Brian Bushnell at bbushnell@lbl.gov if you encounter any problems.
"
}

pushd . > /dev/null
DIR="${BASH_SOURCE[0]}"
while [ -h "$DIR" ]; do
  cd "$(dirname "$DIR")"
  DIR="$(readlink "$(basename "$DIR")")"
done
cd "$(dirname "$DIR")"
DIR="$(pwd)/"
popd > /dev/null

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/"
CP="$DIR""current/"
NATIVELIBDIR="$DIR""jni/"

z="-Xmx1g"
z2="-Xms1g"
EA="-ea"
set=0

if [ -z "$1" ] || [[ $1 == -h ]] || [[ $1 == --help ]]; then
	usage
	exit
fi

calcXmx () {
	source "$DIR""/calcmem.sh"
	parseXmx "$@"
	if [[ $set == 1 ]]; then
	return
	fi
	freeRam 3200m 84
	z="-Xmx${RAM}m"
	z2="-Xms${RAM}m"
}
calcXmx "$@"

dedupe() {
	if [[ $NERSC_HOST == genepool ]]; then
		module unload oracle-jdk
		module load oracle-jdk/1.7_64bit
		module load pigz
	fi
	local CMD="java -Djava.library.path=$NATIVELIBDIR $EA $z $z2 -cp $CP jgi.Dedupe $@"
	echo $CMD >&2
	eval $CMD
}

dedupe "$@"

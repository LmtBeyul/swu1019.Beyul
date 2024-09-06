#!/bin/bash
#
#PBS -N PAN_homgene_best
#PBS -q workq
#PBS -o PAN_homgene_best.log
#PBS -j oe
#PBS -l nodes=1:ppn=4
#PBS -V

module load blast/2.12.0

## Move to work directory firstly
cd $PBS_O_WORKDIR

ls all_seq | sed 's/.cds.fa//g' > organism.txt

## Creat Database
while read organism;do
if [ -d BlastDB/$organism ]
then
    echo "`date` -- The database has been created, skip"
else
    mkdir -p BlastDB/$organism
    makeblastdb -in all_seq/${organism}.cds.fa \
                -dbtype nucl \
                -parse_seqids \
                -out BlastDB/$organism/${organism}
fi
done < organism.txt

ref_seq=ref_seq/*.cds.fa
echo $(basename ${ref_seq} .cds.fa)

if [ -d BlastDB/$(basename ${ref_seq} .cds.fa) ]
then
    echo "`date` -- The database has been created, skip"
else
    makeblastdb -in ref_seq/$(basename ${ref_seq} .cds.fa).cds.fa \
                -dbtype nucl \
                -parse_seqids \
                -out BlastDB/$(basename ${ref_seq} .cds.fa)
fi

## Sequence Alignment
while read organism;do
if [ -s result_best/$organism/${organism}_result_best.txt ]
then
    echo "0.0 `date` -- result_best/$organism/${organism}_result_best.txt, skip"
else
    mkdir -p result_best/$organism
    blastn -query ref_seq/$(basename ${ref_seq} .cds.fa).cds.fa \
           -db BlastDB/$organism/${organism} \
           -evalue 1e-5 \
           -outfmt 6 \
           -num_threads 10 \
           -max_hsps 1 \
           -max_target_seqs 1 \
           -out result_best/$organism/${organism}_result_best.txt
fi
done < organism.txt

## Secondary alignment Sequence
while read organism;do
if [ -s sec_seq/${organism}_seq.txt ]
then
    echo "0.0 `date` -- sec_seq/${organism}_seq.txt, skip"
else
    mkdir -p result_best/$organism/
    awk 'BEGIN{OFS=FS="\t"}{print $1,$2}' result_best/$organism/${organism}_result_best.txt | sort | uniq > result_best/$organism/${organism}_ID.txt
fi
done < organism.txt

exit 0

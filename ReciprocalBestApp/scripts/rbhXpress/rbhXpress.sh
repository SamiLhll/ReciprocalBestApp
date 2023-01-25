#!/usr/bin/env bash

#######################################################
# rbhXpress v0.0.0
# Sami El Hilali
# 2023_january_25
#######################################################

# This scrips takes two protein sets (fasta) and performs a blast (diamond blastp)
# of each one against the other to get the reciprocal best hits

####### PARSE parameters

while getopts a:b:o:t:h option
do
	case "${option}"
	in
	a) PROTEOME1=${OPTARG};;
	b) PROTEOME2=${OPTARG};;
	o) OUTPUT_NAME=${OPTARG};;
	t) THREADS=${OPTARG};;
	h) echo "rbhXpress v1.2.3 - usage :";
	   echo "-a PROTEOME1";
	   echo "-b PROTEOME2";
	   echo "-o OUTPUT_NAME";
	   echo "-t THREADS";
	   exit;;
	?) echo "rbhXpress v1.2.3 - usage :";
	   echo "-a PROTEOME1";
	   echo "-b PROTEOM2";
	   echo "-o OUTPUT_NAME";
	   echo "-t THREADS";
	   exit;;
	esac
done

#########################
#### exit if :
# A command fails :
set -e
# The PROTEOME1 doesn't exist :
if [ ! -f "$PROTEOME1" ]; then
    echo "$PROTEOME1 does not exist.";
    exit;
fi
# The PROTEOME2 doesn't exist :
if [ ! -f "$PROTEOME2" ]; then
    echo "$PROTEOME2 does not exist."
    exit;
fi
########

# More options :
if [ "$(uname)" == "Darwin" ]; then
  diamond_path="diamond";
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  diamond_path="$(dirname "$0")/bin/diamond";
fi

######################### RUN

# create the blast databases :
$diamond_path makedb --in $PROTEOME1 -d sessionFolder/p1 --ignore-warnings &> /dev/null
$diamond_path makedb --in $PROTEOME2 -d sessionFolder/p2 --ignore-warnings &> /dev/null

# Run the blast jobs :
$diamond_path blastp -q $PROTEOME2 -d sessionFolder/p1 -o sessionFolder/p2_p1 -k 1 -e 1E-10 --threads $THREADS --ignore-warnings &> /dev/null
$diamond_path blastp -q $PROTEOME1 -d sessionFolder/p2 -o sessionFolder/p1_p2 -k 1 -e 1E-10 --threads $THREADS --ignore-warnings &> /dev/null

# select the reciprocal best hits :
cut -f1,2,12 sessionFolder/p2_p1 | awk '$3>max[$1]{max[$1]=$3; row[$1]=$1"\t"$2} END {for (i in row) print row[i]}' > sessionFolder/p2_p1.s
cut -f1,2,12 sessionFolder/p1_p2 | awk '$3>max[$1]{max[$1]=$3; row[$1]=$1"\t"$2} END {for (i in row) print row[i]}' > sessionFolder/p1_p2.s

comm -12 <(awk '{print $2"\t"$1}' sessionFolder/p2_p1.s | sort -k1) <(awk '{print $1"\t"$2}' sessionFolder/p1_p2.s | sort -k1) 

######################### DONE

#!/bin/bash
#This is a simple tool for extracting statistics (via klee-stats) from multiple directories into a file
#that can be parsed by a spreadsheet tool. Don't use KLEE output directories with spaces in!

KLEE_DIR_PATTERN='klee-*-*'

if [ $# -ne 2 ]; then
	echo "Usage: $0 <input dir> <output file>"
	echo "<input dir> - A Directory full of KLEE output dirs matching the pattern ${KLEE_DIR_PATTERN}"
	echo "<output file> - The file for the extracted stats to go into"
	exit
fi

INPUT_DIR="$1"
if [ ! -d "${INPUT_DIR}" ]; then
	echo "Input directory ${INPUT_DIR} does not exist!"
	exit
fi

OUTPUT="$2"
if [ -r "${OUTPUT}" ]; then
	echo "Output file ${OUTPUT} already exists. Refusing to overwrite!"
	exit
fi

#Get a list of the klee directories
KLEE_DIRS=$( echo "${INPUT_DIR} -type d -iname ${KLEE_DIR_PATTERN}" | xargs find | sort)

if [ -z "${KLEE_DIRS}" ]; then
	echo "No ${KLEE_DIR_PATTERN} directories were found in ${INPUT_DIR}"
	exit
fi

#Grab the header
FIRST_UTIL=$( echo ${KLEE_DIRS} | grep -Eo '^\./klee-[a-z[0-9]+-[0-9]+' )
klee-stats "${FIRST_UTIL}" | awk ' BEGIN { FS=" "; OFS="\t"; }  NR ==2 { print $2,$4,$6,$8,$10,$12,$14 }' > "${OUTPUT}"



#Loop over directories
for kd in $KLEE_DIRS ; do
	echo "Extracting from ${kd}..."
	klee-stats "${kd}" | awk ' BEGIN { FS=" "; OFS="\t"; }  NR ==4 { print $2,$4,$6,$8,$10,$12,$14 }' >> "${OUTPUT}"
done

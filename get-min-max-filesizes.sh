#!/bin/bash
#The awk script finds the minimum and maximum file size from the smt2-file-size.log

KLEE_DIR_PATTERN='klee-*-*'

if [ $# -ne 2 ]; then
	echo "Usage: $0 <input dir>"
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
KLEE_DIRS=$( echo -en "${INPUT_DIR}\0-type\0d\0-iname\0${KLEE_DIR_PATTERN}" | xargs --null find | sort)

if [ -z "${KLEE_DIRS}" ]; then
	echo "No ${KLEE_DIR_PATTERN} directories were found in ${INPUT_DIR}"
	exit
fi


#Put header in
echo -e "[Directory]\t[min (bytes)]\t[max (bytes)]" > "${OUTPUT}"

#Loop over directories
for kd in $KLEE_DIRS ; do

	echo "Processing...${kd}"
	echo -en "${kd}\t" >> "${OUTPUT}"
	cat "${kd}/smt2-file-sizes.log" | awk '
	BEGIN { min=-1 ; max=0; OFS="\t";}
	/^[^#]/ { 
			#Grab max if available
			if($2 > max) {max=$2;};  
			
			#Make first number found the minimum
			if(min==-1) {min=$2}; 
			
			#Grab min if available
			if(min!=-1 && $2 < min) {min=$2};
		}

	END   { print min,max;}' >> "${OUTPUT}"
done

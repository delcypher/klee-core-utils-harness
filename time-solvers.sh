#!/bin/bash
#Script to run solvers on extracted KLEE SMTLIBv2 queries. Unfortunately need to run as root as we need to clear the read
#cache

INPUT_DIR="$1"

TIME="/usr/bin/time -p"

TEMP_FILE="temp.txt"
ANS_FILE="answer.txt"


#Solvers to use
SOLVERS=(cvc3 mathsat sonolar stpwrap2 stp2wrap2 z3)

#Solver options
declare -A SOLVER_OPTS
SOLVER_OPTS=([cvc3]='-lang smt2' \
	[mathsat]='-printer.bv_number_format=2 -theory.la.enabled=false -theory.bv.delay_propagated_eqs=true -theory.arr.max_wr_lemmas=0 -theory.arr.enable_nonlinear=true -theory.arr.enable_witness=false -preprocessor.toplevel_propagation=true -preprocessor.simplification=7 -theory.arr.permanent_lemma_inst=true -dpll.branching_random_frequency=0 -theory.bv.eager=false' \
	[sonolar]= \
	[stpwrap2]= \
	[stp2wrap2]= \
	[z3]= )

#Declare if solver takes input on stdin
#If not declared it is assumed the solver can take a file
declare -A SOLVERS_USE_STDIN
SOLVERS_USE_STDIN=([mathsat]='yes')

if [ ! -d "${INPUT_DIR}" ]; then
	echo "Input directory ${INPUT_DIR} is not accessible";
	exit 1;
fi

#Get a list the query files in numerical order
QUERIES=$( find "${INPUT_DIR}" -iname '*.smt2' | sort)

echo "Found $( echo ${QUERIES} | wc -w) queries"

#Output header
echo -n "#[Query  name]"
for solver in ${SOLVERS[*]}; do echo -ne "\t[${solver}]"; done

echo -e "\t[winner]"

for query in  ${QUERIES}
do
	echo -en "${query}\t"

	rm "${TEMP_FILE}" 2> /dev/null

	for solver in ${SOLVERS[*]} ; do

		#This is a bit of a hack
		#Read caching will cause benchmarks to be invalid, try to make the kernel clear the cache (need to be root to do this!)
		sync ; echo 3 > /proc/sys/vm/drop_caches

		#Decide if need to use stdin
		if [  -n "${SOLVERS_USE_STDIN[$solver]}" ]; then
			#use stdin
			REC_TIME=$(${TIME} ${solver} ${SOLVER_OPTS[${solver}]} < "${query}" 2>&1 > "${ANS_FILE}" | grep -E '^real' )
		else
			#don't use stdin
			REC_TIME=$(${TIME} ${solver} ${SOLVER_OPTS[${solver}]}  "${query}" 2>&1 > ${ANS_FILE}  | grep -E '^real')

		fi
		
		#Grab the wall time
		REC_TIME=$(echo "${REC_TIME}" | sed 's/^real //')

		#check the solver's answer
		if [ $( grep -Ec --max-count=1 '^(sat|unsat|unknown)' "${ANS_FILE}") -ne 1 ]; then
			echo "Solver error for query ${query}"
			exit 1;
		fi


		echo -en "${REC_TIME}\t"

		#Record the time in the temp file
		echo "${REC_TIME} ${solver}" >> "${TEMP_FILE}"
	done
		#Now perform a sort of the temp file to determine the winner! (this also ends the line)
		echo -e "$(sort -n "${TEMP_FILE}" | awk '{print $2; exit}')"


done

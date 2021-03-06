#!/bin/bash
#This is a simple test harness script for running KLEE on core-utils 6.11
#Run it inside the build folder ("src") containing the byte code versions
#of the utilities created by klee-gcc

#Default sym args
defaultArgs='--sym-args 0 1 10 --sym-args 0 2 2 --sym-files 1 8 --sym-stdout'

RUN_IN="/data/dsl11/sandbox"

#Allow more open files than the default
ulimit -n 4096

#setup trap so that C^C causes loop to exit
trap exit SIGINT SIGTERM SIGQUIT

#List of core-utils (key) to test with sym args. This is similar to the list originally used in the KLEE paper.
#If a utility does not have specified sym args then "defaultArgs" are used.
declare -A UTILS
UTILS=( ["["]='--sym-args 0 1 10 --sym-args 0 4 3 --sym-files 2 10 --sym-stdout' \
	[base64]= \
	[basename]= \
	[cat]= \
	[chcon]= \
	[chgrp]= \
	[chmod]= \
	[chown]= \
	[chroot]= \
	[cksum]= \
	[comm]= \
	[cp]= \
	[csplit]= \
	[cut]= \
	[date]= \
	[dd]='--sym-args 0 3 10 --sym-files 1 8 --sym-stdout' \
	[df]= \
	[dircolors]='--sym-args 0 3 10 --sym-files 2 12 --sym-stdout' \
	[dirname]= \
	[du]= \
	[echo]='--sym-args 0 4 300 --sym-files 2 30 --sym-stdout' \
	[env]= \
	[expand]= \
	[expr]='--sym-args 0 1 10 --sym-args 0 3 2 --sym-stdout' \
	[factor]= \
	[false]= \
	[fmt]= \
	[fold]= \
	[head]= \
	[hostid]= \
	[hostname]= \
	[id]= \
	[ginstall]= \
	[join]= \
	[kill]= \
	[link]= \
	[ln]= \
	[logname]= \
	[ls]= \
	[md5sum]='--sym-args 0 1 10 --sym-args 0 2 2 --sym-files 1 100 --sym-stdout' \
	[mkdir]= \
	[mkfifo]= \
	[mknod]='--sym-args 0 1 10 --sym-args 0 3 2 --sym-files 1 8 --sym-stdout' \
	[mktemp]= \
	[mv]= \
	[nice]= \
	[nl]= \
	[nohup]= \
	[od]='--sym-args 0 3 10 --sym-files 2 12 --sym-stdout' \
	[paste]= \
	[pathchk]='--sym-args 0 1 2 --sym-args 0 1 300 --sym-files 1 8 --sym-stdout' \
	[pinky]= \
	[pr]= \
	[printenv]= \
	[printf]='--sym-args 0 3 10 --sym-files 2 12 --sym-stdout' \
	[ptx]='--sym-args 0 1 10 -- sym-args 0 10 2 --sym-files 1 50 --sym-stdout' \
	[pwd]= \
	[readlink]= \
	[rm]= \
	[rmdir]= \
	[runcon]= \
	[seq]= \
	[setuidgid]= \
	[shred]= \
	[shuf]= \
	[sleep]= \
	[sort]='--sym-args 0 1 10 --sym-args 0 22 2 --sym-files 1 50 --sym-stdout' \
	[split]= \
	[stat]= \
	[stty]= \
	[sum]= \
	[sync]= \
	[tac]= \
	[tail]= \
	[tee]= \
	[touch]= \
	[tr]= \
	[tsort]= \
	[tty]= \
	[uname]= \
	[unexpand]= \
	[uniq]= \
	[unlink]= \
	[uptime]= \
	[users]= \
	[wc]= \
	[whoami]= \
	[who]= \
	[yes]= \
)

#List of special KLEE options to use with utilities
#If a utility is not in this array then no extra options are passed to KLEE
declare -A EXTRA_ARGS
EXTRA_ARGS=( [md5sum]='--max-solver-time=120' \
	     [sort]='--max-sym-array-size=1024' \
)

ARG=""
SPECIAL_ARG=""

if [ ! -d "${RUN_IN}" ]; then
	echo "Run in directory : ${RUN_IN} does not exist!"
	exit 1;
fi

echo "Testing ${#UTILS[@]} utilites"

for run in {1..1}
do
	echo "Starting run $run"
	#We use sort so the utilities are executed in alphabetical order
	for util in $(echo ${!UTILS[*]} | sed 'y/ /\n/' | sort )
	do
		UTIL_BC="${util}.bc"
		if [ ! -r "${UTIL_BC}" ]; then
			echo "Utility ${UTIL_BC} not found!"
			continue;
		fi
		
		#determine sym args to use
		if [ -z "${UTILS["$util"]}" ]; then
			ARG="$defaultArgs"		
		else
			ARG="${UTILS["$util"]}"
			echo "$util is using non default $ARG"
		fi

		#Determine if we need to use extra arguments to KLEE
		if [ -z "${EXTRA_ARGS["$util"]}" ]; then
			SPECIAL_ARG="";
		else
			SPECIAL_ARG="${EXTRA_ARGS["$util"]}"
			echo "${util} has extra KLEE arguments: ${SPECIAL_ARG}"

		fi

		OUTPUT_DIR="klee-${util}-${run}"

		echo "*****Running '${OUTPUT_DIR}' at $(date)"

		#Now run klee
		#Remove appropriate lines depending on which solver you want to use
		klee \
		--solver=stp \
#		--solver=smtlibv2 \
#		--solver-path=stpwrap2 \
#		--smtlibv2-solver-log-query-size \
#		--smtlibv2-solver-use-lets \
		--libc=uclibc \
		--output-dir="${OUTPUT_DIR}" \
		--posix-runtime \
		--use-cex-cache \
		--max-time=1200 \
		--watchdog \
		--run-in="${RUN_IN}" \
		${SPECIAL_ARG} \
		${UTIL_BC} \
		${ARG} \
		1> /dev/null \
		2> "${OUTPUT_DIR}.log"

	done
done

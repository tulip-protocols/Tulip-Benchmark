#!/bin/bash

source ../../config.sh
source ../../functions.sh
source ../../../config-benchmark.sh

is_true_positive()
{
	FIC="$1"

	grep -ia "site" $FIC | grep -ia "cpfr\|cpto" > /dev/null 2>&1

	if [ $? -eq 0 ]
	then
		return 0
	else
		return 1
	fi
}

get_false_positives()
{
	for DIR in `ls -d ${RESULTS_PATH}/cbd/proftpd-1.3.5/output*/cbd_output_*`
	do
		for FIC in `find ${DIR}/potential_backdoors -type f`
		do
			if ! is_true_positive $FIC
			then
				echo $FIC
			fi
		done
	done
}

count_false_positives_per_runs "output_proftpd-1.3.5_[0-9]*" "proftpd-1.3.5" "NONE"
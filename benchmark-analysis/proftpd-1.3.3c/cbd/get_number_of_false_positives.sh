#!/bin/bash

source ../../config.sh
source ../../functions.sh
source ../../../config-benchmark.sh

is_true_positive()
{
	FIC="$1"

	grep -ia "help" $FIC | grep -ia "acidbitchez" > /dev/null

	if [ $? -eq 0 ]
	then
		return 0
	else
		return 1
	fi
}

get_false_positives()
{
	for FIC in `ls ${RESULTS_PATH}/cbd/proftpd-1.3.3c/output*/cbd_*/potential_backdoors/*/*`
	do
		if ! is_true_positive $FIC
		then
			echo $FIC
		fi
	done
}

count_false_positives_per_runs "output_proftpd-1.3.3c_[0-9]*" "proftpd-1.3.3c" "setuid(0)\|execve.*sh"
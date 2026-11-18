#!/bin/bash

source ../../config.sh
source ../../../config-benchmark.sh
source ../../functions.sh

is_true_positive()
{
	FIC="$1"

	grep -ia "user" $FIC | grep ":)" > /dev/null

	if [ $? -eq 0 ]
	then
		grep -ia "pass" $FIC > /dev/null

		if [ $? -eq 0 ]
		then
			return 0
		else
			return 1
		fi
	else
		return 1
	fi
}

get_false_positives()
{
	for FIC in `ls ${RESULTS_PATH}/cbd/vsftpd-2.3.4/output*/cbd_output_iteration_$((NUMBER_OF_ITERATIONS - 1))/potential_backdoors/*/*`
	do
		if ! is_true_positive $FIC
		then
			echo $FIC
		fi
	done
}

count_false_positives_per_runs "output_vsftpd-2\.3\.4_[0-9]*" "vsftpd-2.3.4" "execve.*sh.*"
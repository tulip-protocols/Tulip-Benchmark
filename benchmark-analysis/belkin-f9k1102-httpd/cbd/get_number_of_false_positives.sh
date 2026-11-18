#!/bin/bash

source ../../config.sh
source ../../functions.sh
source ../../../config-benchmark.sh

is_true_positive()
{
	FIC="$1"

	grep -ia "dev.cgi?.*c=" $FIC > /dev/null

	if [ $? -eq 0 ]
	then
		return 0
	else
		return 1
	fi
}

get_false_positives()
{
	for FIC in `ls ${RESULTS_PATH}/cbd/belkin-f9k1102-httpd/output*/cbd_*/potential_backdoors/*/*`
	do
		if ! is_true_positive $FIC
		then
			echo $FIC
		fi
	done
}

count_false_positives_per_runs "output_belkin-f9k1102-httpd_[0-9]*" "belkin-f9k1102-httpd" "execve.*sh.*"
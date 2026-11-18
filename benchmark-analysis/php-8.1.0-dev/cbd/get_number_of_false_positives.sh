#!/bin/bash

source ../../config.sh
source ../../../config-benchmark.sh
source ../../functions.sh

is_true_positive()
{
	FIC="$1"

	grep -ia "User-agentt:" $FIC | grep -ia "zerodium" > /dev/null

	if [ $? -eq 0 ]
	then
		return 0
	else
		return 1
	fi
}

get_false_positives()
{
	for FIC in `ls ${RESULTS_PATH}/cbd/php-8.1.0-dev/output*/cbd_*/potential_backdoors/*/*`
	do
		if ! is_true_positive $FIC
		then
			echo $FIC
		fi
	done
}

count_false_positives_per_runs "output_php-8.1.0-dev_[0-9]*" "php-8.1.0-dev" "execve.*sh.*"
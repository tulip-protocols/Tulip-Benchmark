#!/bin/bash

source ../../config.sh
source ../../functions.sh
source ../../../config-benchmark.sh

is_true_positive()
{
	FIC="$1"

	grep -ia "login" $FIC | grep -ia "cartman" > /dev/null

	if [ $? -eq 0 ]
	then
		return 0
	else
		return 1
	fi
}

get_false_positives()
{
	for FIC in `find ${RESULTS_PATH}/cbd/cyrus-imapd-3.12.1/output*/cbd_*/potential_backdoors/* -type f`
	do
		if ! is_true_positive $FIC
		then
			echo $FIC
		fi
	done
}

count_false_positives_per_runs "output_cyrus-imapd-3\.12\.1_[0-9]*" "cyrus-imapd-3.12.1" "execve.*sh.*"
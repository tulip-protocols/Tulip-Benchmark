#!/bin/bash

source ../../config.sh
source ../../functions.sh
source ../../../config-benchmark.sh

is_true_positive()
{
	FIC="$1"

	grep -ia "user-agent" $FIC | grep -ia "xmlset_roodkcableoj28840ybtide" > /dev/null

	if [ $? -eq 0 ]
	then
		grep -ia "get.*/" $FIC > /dev/null

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
	for FIC in `ls ${RESULTS_PATH}/cbd/d-link-1.13A-thttpd/output*/cbd_*/potential_backdoors/*/*`
	do
		if ! is_true_positive $FIC
		then
			echo $FIC
		fi
	done
}

count_false_positives_per_runs "output_d-link-1.13A-thttpd_[0-9]*" "d-link-1.13A-thttpd" "openat(AT_FDCWD, \"index.html\", O_RDONLY)"
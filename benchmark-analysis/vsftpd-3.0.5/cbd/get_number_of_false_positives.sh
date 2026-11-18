#!/bin/bash

source ../../config.sh
source ../../functions.sh
source ../../../config-benchmark.sh

is_true_positive()
{
	FIC="$1"

	grep -ia "user.*miyazaki" $FIC > /dev/null

	if [ $? -eq 0 ]
	then
		grep -ia "pass.*totoro" $FIC > /dev/null

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
	for FIC in `ls ${RESULTS_PATH}/cbd/vsftpd-3.0.5/output*/cbd_*/potential_backdoors/*/*`
	do
		if ! is_true_positive $FIC
		then
			echo $FIC
		fi
	done
}

count_false_positives_per_runs "output_vsftpd-3.0.5_[0-9]*" "vsftpd-3.0.5" "openat(AT_FDCWD, \".message\", O_RDONLY|O_NONBLOCK)"
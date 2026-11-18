#!/bin/bash

source ../../../config.sh
source ../../../functions.sh
source ../../../../config-benchmark.sh

QMAIL_VARIANT=2_disabled_authentication_3

is_true_positive()
{
	FIC="$1"

	grep -ia "secr" $FIC > /dev/null 2>&1

	if [ $? -eq 0 ]
	then
		return 0
	else
		return 1
	fi
}

get_false_positives()
{
	for DIR in `ls -d ${RESULTS_PATH}/cbd/qmail/${QMAIL_VARIANT}/output*/cbd_output_*`
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

export PATH_OFFSET=6

count_false_positives_per_runs "output_qmail-${QMAIL_VARIANT}_[0-9]*" "qmail/$QMAIL_VARIANT" "execve(\".*qmail-pop3d\", .*)\|execve(\".*checkpassword\", .*)"
#!/bin/bash

source ../../../config.sh
source ../../../functions.sh
source ../../../../config-benchmark.sh

QMAIL_VARIANT=1_hard-codded_credentials

is_true_positive()
{
	FIC="$1"

	grep -ia "user" $FIC | grep -ia "homer" > /dev/null 2>&1

	if [ $? -eq 0 ]
	then
		grep -ia "pass" $FIC | grep -ia "marge" > /dev/null 2>&1

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

get_true_positives()
{
	for DIR in `ls -d ${RESULTS_PATH}/cbd/qmail/${QMAIL_VARIANT}/output*/cbd_output_*`
	do
		for FIC in `find ${DIR}/potential_backdoors -type f`
		do
			if is_true_positive $FIC
			then
				echo $FIC
			fi
		done
	done
}

export PATH_OFFSET=6

for CBD_INSTANCE_WITH_TIME in `cbd_instances_with_times "output_qmail-${QMAIL_VARIANT}_[0-9]*" "qmail/$QMAIL_VARIANT"`
do
	CBD_INSTANCE=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f1`
	TIME=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f2`

	echo "$CBD_INSTANCE:`echo $TIME | tr ',' '\n' | sort -n | tr '\n' ',' | sed -re 's/,$//g'`"
done

echo

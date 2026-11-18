#!/bin/bash

export CBD_VARIANT=cbd_ablated

source ../../../config.sh
source ../../../../config-benchmark.sh
source ../../../functions.sh

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

get_true_positives()
{
	for FIC in `find ${RESULTS_PATH}/cbd_ablated/qmail/${QMAIL_VARIANT} -type f | grep cbd_output_iteration_[0-9]*/potential_backdoors`
	do
		if is_true_positive $FIC
		then
			echo $FIC
		fi
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

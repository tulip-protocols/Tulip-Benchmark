#!/bin/bash

export CBD_VARIANT=cbd_ablated_without_multilayer_fuzzing

source ../../config.sh
source ../../functions.sh
source ../../../config-benchmark.sh

is_true_positive()
{
	FIC="$1"

	grep -ia "site" $FIC | grep -ia "cpfr\|cpto" > /dev/null 2>&1

	if [ $? -eq 0 ]
	then
		return 0
	else
		return 1
	fi
}

get_true_positives()
{
	for DIR in `ls -d ${RESULTS_PATH}/cbd_ablated_without_multilayer_fuzzing/proftpd-1.3.5/output*/cbd_output_*`
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

for CBD_INSTANCE_WITH_TIME in `cbd_instances_with_times "output_proftpd-1.3.5_[0-9]*" "proftpd-1.3.5"`
do
	CBD_INSTANCE=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f1`
	TIME=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f2`

	echo "$CBD_INSTANCE:`echo $TIME | tr ',' '\n' | sort -n | tr '\n' ',' | sed -re 's/,$//g'`"
done

echo

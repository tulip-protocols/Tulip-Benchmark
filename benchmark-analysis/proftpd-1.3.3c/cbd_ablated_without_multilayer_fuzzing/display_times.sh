#!/bin/bash

export CBD_VARIANT=cbd_ablated_without_multilayer_fuzzing

source ../../config.sh
source ../../../config-benchmark.sh

is_true_positive()
{
	FIC="$1"

	grep -ia "help" $FIC | grep -ia "acidbitchez" > /dev/null

	if [ $? -eq 0 ]
	then
		return 0
	else
		return 1
	fi
}

get_true_positives()
{
	for FIC in `ls ${RESULTS_PATH}/cbd_ablated_without_multilayer_fuzzing/proftpd-1.3.3c/output*/cbd_*/potential_backdoors/*/*`
	do
		if is_true_positive $FIC
		then
			echo $FIC
		fi
	done
}

for CBD_INSTANCE_WITH_TIME in `cbd_instances_with_times "output_proftpd-1.3.3c_[0-9]*" "proftpd-1.3.3c"`
do
	CBD_INSTANCE=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f1`
	TIME=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f2`

	echo "$CBD_INSTANCE:`echo $TIME | tr ',' '\n' | sort -n | tr '\n' ',' | sed -re 's/,$//g'`"
done

echo

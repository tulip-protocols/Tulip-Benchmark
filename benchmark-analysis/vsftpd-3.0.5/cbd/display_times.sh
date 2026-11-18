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

get_true_positives()
{
	for FIC in `ls ${RESULTS_PATH}/cbd/vsftpd-3.0.5/output*/cbd_*/potential_backdoors/*/*`
	do
		if is_true_positive $FIC
		then
			echo $FIC
		fi
	done
}

for CBD_INSTANCE_WITH_TIME in `cbd_instances_with_times "output_vsftpd-3.0.5_[0-9]*" "vsftpd-3.0.5"`
do
	CBD_INSTANCE=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f1`
	TIME=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f2`

	echo "$CBD_INSTANCE:`echo $TIME | tr ',' '\n' | sort -n | tr '\n' ',' | sed -re 's/,$//g'`"
done

echo

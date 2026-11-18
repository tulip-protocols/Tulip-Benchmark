#!/bin/bash

export CBD_VARIANT=cbd_ablated

source ../../config.sh
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

get_true_positives()
{
	for FIC in `find ${RESULTS_PATH}/cbd_ablated/cyrus-imapd-3.12.1 -type f | grep cbd_output_iteration_[0-9]*/potential_backdoors`
	do
		if is_true_positive $FIC
		then
			echo $FIC
		fi
	done
}

get_total_times()
{
	TRUE_POSITIVES=`get_true_positives | grep -o "output_cyrus-imapd-3.12.1.*"`

	for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
	do
		BACKDOORS_FOR_THIS_TRY=`echo "$TRUE_POSITIVES" | tr " " "\n" | grep -o "output_cyrus-imapd-3.12.1_$I.*"`

		if [ "x$BACKDOORS_FOR_THIS_TRY" != "x" ]
		then
			ITERATIONS_CONTAINING_THE_BACKDOOR=`echo $BACKDOORS_FOR_THIS_TRY | tr " " "\n" | grep -o "cbd_output_iteration_[1-9]*"`
			FIRST_ITERATION_CONTAINING_THE_BACKDOOR=`echo $ITERATIONS_CONTAINING_THE_BACKDOOR | tr " " "\n" | cut -d'_' -f4 | sort -n | head -n1`
			RUN="output_cyrus-imapd-3.12.1_$I"

			TOTAL_TIME_IN_S=$(((FIRST_ITERATION_CONTAINING_THE_BACKDOOR + 1) * ITERATION_TIME)) # +1 because iterations begins by 0

			echo $RUN:${TOTAL_TIME_IN_S}s
		fi
	done
}

cbd_ablated_instances_with_times()
{
	CURRENT_CBD_INSTANCE=""
	
	for CBD_INSTANCE_WITH_TIME in `get_total_times`
	do
		CBD_INSTANCE=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f1`
		TIME=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f2`
	
		if [ "x$CURRENT_CBD_INSTANCE" != "x$CBD_INSTANCE" ]
		then
			if [ "x$CURRENT_CBD_INSTANCE" != "x" ]
			then
				echo
			fi
	
			CURRENT_CBD_INSTANCE=$CBD_INSTANCE
	
			echo -n "$CURRENT_CBD_INSTANCE:$TIME"
		else
			echo -n ",$TIME"
		fi
	done
}

for CBD_INSTANCE_WITH_TIME in `cbd_ablated_instances_with_times`
do
	CBD_INSTANCE=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f1`
	TIME=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f2`

	echo "$CBD_INSTANCE:`echo $TIME | tr ',' '\n' | sort -n | tr '\n' ',' | sed -re 's/,$//g'`"
done

echo

#!/bin/bash

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
	for FIC in `ls ${RESULTS_PATH}/cbd/proftpd-1.3.3c/output*/cbd_*/potential_backdoors/*/*`
	do
		if is_true_positive $FIC
		then
			echo $FIC
		fi
	done
}

get_iteration_that_found_first_the_backdoor()
{
	OUTPUT_DIR="$1"
	RESULT=$NUMBER_OF_ITERATIONS

	for FIC in `find $OUTPUT_DIR/*/potential_backdoors -type f`
	do
		if is_true_positive $FIC
		then
			ITERATION_NUMBER=`echo $FIC | sed -re "s?$RESULTS_PATH??g" | cut -d'/' -f5 | cut -d'_' -f4`

			if [ $ITERATION_NUMBER -lt $RESULT ]
			then
				RESULT=$ITERATION_NUMBER
			fi
		fi
	done

	echo $RESULT
}

get_total_times()
{
	for FIC in `get_true_positives`
	do
		RUN=`echo $FIC | grep -o "output_proftpd-1\.3\.3c_[0-9]*"`
		OUTPUT_DIR=$RESULTS_PATH/cbd/proftpd-1.3.3c/$RUN

		NUMBER_OF_THE_FIRST_ITERATION_THAT_FOUND_THE_BACKDOOR=`get_iteration_that_found_first_the_backdoor $OUTPUT_DIR`

		TOTAL_TIME_IN_S=$(((NUMBER_OF_THE_FIRST_ITERATION_THAT_FOUND_THE_BACKDOOR + 1) * ITERATION_TIME)) # +1 because iterations begins by 0

		echo $RUN:${TOTAL_TIME_IN_S}s
	done
}

cbd_instances_with_times()
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

for CBD_INSTANCE_WITH_TIME in `cbd_instances_with_times`
do
	CBD_INSTANCE=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f1`
	TIME=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f2`

	echo "$CBD_INSTANCE:`echo $TIME | tr ',' '\n' | sort -n | tr '\n' ',' | sed -re 's/,$//g'`"
done

echo

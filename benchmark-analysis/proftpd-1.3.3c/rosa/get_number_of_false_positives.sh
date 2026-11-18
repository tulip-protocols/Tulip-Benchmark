#!/bin/bash

source ../../config.sh

get_fics_that_contains_the_backdoor()
{
	pushd ${RESULTS_PATH}/rosa/proftpd-1.3.3c/ 2>&1 > /dev/null

	for ROSA_INSTANCE in `ls -d rosa-out*`
	do
		HELP_ACIDBITCHEZ=`grep -Rial "help.*acidbitchez" $ROSA_INSTANCE/backdoors`
		
		for FIC in $HELP_ACIDBITCHEZ
		do
			echo "+$FIC"
		done

		NOT_HELP_ACIDBITCHEZ=`grep -Rialv "help.*acidbitchez" $ROSA_INSTANCE/backdoors`

		for FIC in $NOT_HELP_ACIDBITCHEZ
		do
			echo "-$FIC"
		done
	done

	popd 2>&1 > /dev/null
}

get_false_positives()
{
	COUNT=0
	PREVIOUS_CLUSTER=""
	
	for CLUSTER in `get_fics_that_contains_the_backdoor | cut -d'/' -f1-3 | sort | uniq | grep -v README.txt`
	do
		CURRENT_CLUSTER_PATH=`echo $CLUSTER | colrm 1 1`
	
		if [ "x$PREVIOUS_CLUSTER" != "x+$CURRENT_CLUSTER_PATH" ]
		then
			if [ "x$CLUSTER" == "x-$CURRENT_CLUSTER_PATH" ]
			then
				echo $CURRENT_CLUSTER_PATH
			fi
		fi
	
		PREVIOUS_CLUSTER="$CLUSTER"
	done
}

get_false_positives | cut -d'/' -f1 | sort | uniq -c

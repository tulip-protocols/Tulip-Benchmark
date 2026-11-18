#!/bin/bash

source ../../../config.sh

QMAIL_VARIANT=1_hard-codded_credentials

get_fics_that_contains_the_backdoor()
{
	pushd ${RESULTS_PATH}/rosa/qmail/$QMAIL_VARIANT/ 2>&1 > /dev/null

	for ROSA_INSTANCE in `ls -d rosa-out*`
	do
		USER_HOMER=`grep -Rial "user.*homer" $ROSA_INSTANCE/backdoors`
		
		for FIC in $USER_HOMER
		do
			grep -ia "pass.*marge" $FIC > /dev/null 2>&1

			if [ $? -eq 0 ]
			then
				echo "+$FIC"
			else
				echo "-$FIC"
			fi
		done

		NOT_USER_HOMER=`grep -Rialv "user.*homer" $ROSA_INSTANCE/backdoors`

		for FIC in $NOT_USER_HOMER
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

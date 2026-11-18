#!/bin/bash

source ../../../config.sh

QMAIL_VARIANT=2_disabled_authentication_1_n_5_v3

is_true_positive()
{
	FIC="$1"

	grep -ia "pass" $FIC | grep -ia "you_shall_not_pass" > /dev/null 2>&1

	if [ $? -eq 0 ]
	then
		grep -ia "user" $FIC | grep -ia "big_brother_is_watching_you" > /dev/null 2>&1

		if [ $? -eq 0 ]
		then
			grep -ia "user" $FIC | grep -ia "0118-999-881-999-119-7253" > /dev/null 2>&1

			if [ $? -eq 0 ]
			then
				return 0
			else
				return 1
			fi
		else
			return 1
		fi
	else
		return 1
	fi
}

get_fics_that_contains_the_backdoor()
{
	pushd ${RESULTS_PATH}/rosa/qmail/$QMAIL_VARIANT/ 2>&1 > /dev/null

	for ROSA_INSTANCE in `ls -d rosa-out*`
	do
		USER_YOU_SHALL_NOT_PASS=`grep -Rial "user.*you_shall_not_pass" $ROSA_INSTANCE/backdoors`
		
		for FIC in $USER_YOU_SHALL_NOT_PASS
		do
			if is_true_positive "$FIC"
			then
				echo "+$FIC"
			else
				echo "-$FIC"
			fi
		done

		NOT_USER_YOU_SHALL_NOT_PASS=`grep -Rialv "user.*you_shall_not_pass" $ROSA_INSTANCE/backdoors`

		for FIC in $NOT_USER_YOU_SHALL_NOT_PASS
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

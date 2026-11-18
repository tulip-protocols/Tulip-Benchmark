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

get_rosa_instances_with_times()
{
	pushd ${RESULTS_PATH}/rosa/qmail/$QMAIL_VARIANT/ 2>&1 > /dev/null

	USER_YOU_SHALL_NOT_PASS=`grep -Rial "user.*you_shall_not_pass" rosa-out*/backdoors`
	
	for FIC in $USER_YOU_SHALL_NOT_PASS
	do
		is_true_positive "$FIC"

		if [ $? -eq 0 ]
		then
			ROSA_INSTANCE=`echo $FIC | cut -d'/' -f1`
			DECISION=`echo $FIC | cut -d'/' -f4`
			DECISION_FILE="$ROSA_INSTANCE/decisions/$DECISION.toml"

			SECONDS_IN_DECISION_FILE=`cat $DECISION_FILE | grep seconds`
			PARSED_SECONDS_IN_DECISION_FILE=`echo $SECONDS_IN_DECISION_FILE | cut -d"=" -f2 | sed -re "s/ //g"`

			echo "$ROSA_INSTANCE:$PARSED_SECONDS_IN_DECISION_FILE"
		fi
	done

	popd 2>&1 > /dev/null
}

group_rosa_instances_with_times()
{
	CURRENT_ROSA_INSTANCE=""
	
	for ROSA_INSTANCE_WITH_TIME in `get_rosa_instances_with_times | sort -k'6' -t'_' -n`
	do
		ROSA_INSTANCE=`echo $ROSA_INSTANCE_WITH_TIME | cut -d':' -f1`
		TIME=`echo $ROSA_INSTANCE_WITH_TIME | cut -d':' -f2`

		if [ "x$CURRENT_ROSA_INSTANCE" != "x$ROSA_INSTANCE" ]
		then
			if [ "x$CURRENT_ROSA_INSTANCE" != "x" ]
			then
				echo
			fi

			CURRENT_ROSA_INSTANCE=$ROSA_INSTANCE

			echo -n "$CURRENT_ROSA_INSTANCE:$TIME"
		else
			echo -n ",$TIME"
		fi
	done
}

group_rosa_instances_with_sorted_times()
{
	for ROSA_INSTANCE_WITH_TIMES in `group_rosa_instances_with_times`
	do
		ROSA_INSTANCE=`echo $ROSA_INSTANCE_WITH_TIMES | cut -d':' -f1`
		TIMES=`echo $ROSA_INSTANCE_WITH_TIMES | cut -d':' -f2`

		SORTED_TIMES=`echo $TIMES | tr ',' '\n' | sort -n | uniq | tr '\n' ','`

		echo "$ROSA_INSTANCE:$SORTED_TIMES"
	done
}

group_rosa_instances_with_sorted_times

NUMBER_OF_FINDINGS=`group_rosa_instances_with_sorted_times | wc -l`

echo $NUMBER_OF_FINDINGS instances found the backdoor

echo

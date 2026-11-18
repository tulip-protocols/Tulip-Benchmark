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

USER_YOU_SHALL_NOT_PASS=`grep -Rial "user.*you_shall_not_pass" ${RESULTS_PATH}/rosa/qmail/$QMAIL_VARIANT/rosa-out*/backdoors`

for FIC in $USER_YOU_SHALL_NOT_PASS
do
	is_true_positive "$FIC"

	if [ $? -eq 0 ]
	then
		echo "Found in $FIC"
	fi
done

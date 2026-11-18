#!/bin/bash

source ../../../config.sh

QMAIL_VARIANT=1_hard-codded_credentials

USER_HOMER=`grep -Rial "user.*homer" ${RESULTS_PATH}/rosa/qmail/$QMAIL_VARIANT/rosa-out*/backdoors`

for FIC in $USER_HOMER
do
	grep -ia "pass.*marge" $FIC > /dev/null 2>&1

	if [ $? -eq 0 ]
	then
		echo "Found in $FIC"
	fi
done

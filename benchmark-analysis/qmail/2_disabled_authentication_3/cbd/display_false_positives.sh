#!/bin/bash

source ../../../config.sh
source ../../../../config-benchmark.sh

QMAIL_VARIANT=2_disabled_authentication_3

for FIC in `ls ${RESULTS_PATH}/cbd/qmail/$QMAIL_VARIANT/output*/*/potential_backdoors/*/*`
do
	grep -Ria "secr" $FIC > /dev/null

	if [ $? -eq 1 ]
	then
		echo $FIC | grep "__report__" > /dev/null

		if [ $? -eq 1 ]
		then
			bat $FIC
		fi
	fi
done

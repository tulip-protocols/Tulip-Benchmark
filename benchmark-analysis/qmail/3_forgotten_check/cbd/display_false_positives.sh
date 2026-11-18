#!/bin/bash

source ../../../config.sh
source ../../../../config-benchmark.sh

QMAIL_VARIANT=3_forgotten_check

for FIC in `ls ${RESULTS_PATH}/cbd/qmail/$QMAIL_VARIANT/output*/*/potential_backdoors/*/*`
do
	grep -Ria "list" $FIC > /dev/null

	if [ $? -eq 1 ]
	then
		echo $FIC | grep "__report__" > /dev/null

		if [ $? -eq 1 ]
		then
			bat $FIC
		fi
	fi
done

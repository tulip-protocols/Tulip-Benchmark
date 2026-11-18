#!/bin/bash

source ../../config.sh

HELP_ACIDBITCHEZ=`grep -Rial "help.*acidbitchez" ${RESULTS_PATH}/rosa/proftpd-1.3.3c/rosa-out*/backdoors`

for FIC in $HELP_ACIDBITCHEZ
do
	echo "Found in $FIC"
done

#!/bin/bash

source ../../config.sh

SITE_CPFR=`grep -Rial "site.*cpfr" ${RESULTS_PATH}/rosa/proftpd-1.3.5_with_site_commands_seeds/rosa-out*/backdoors`

for FIC in $SITE_CPFR
do
	grep -ia "site.*cpto" $FIC > /dev/null 2>&1

	if [ $? -eq 0 ]
	then
		echo "Found in $FIC"
	fi
done

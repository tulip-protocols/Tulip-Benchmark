#!/bin/bash

source ../../config.sh

USER_MIYAZAKI=`grep -Rial "user .*miyazaki" ${RESULTS_PATH}/rosa/vsftpd-3.0.5/rosa-out*/backdoors`

for FIC in $USER_MIYAZAKI
do
	grep -ia "pass .*totoro" $FIC > /dev/null 2>&1

	if [ $? -eq 0 ]
	then
		echo "Found in $FIC"
	fi
done

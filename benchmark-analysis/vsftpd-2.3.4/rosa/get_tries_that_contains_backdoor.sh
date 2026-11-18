#!/bin/bash

source ../../config.sh

USER_SMILEY=`grep -Rial "user.*:)" ${RESULTS_PATH}/rosa/vsftpd-2.3.4/rosa-out*/backdoors`

for FIC in $USER_SMILEY
do
	grep -ia "pass" $FIC > /dev/null 2>&1

	if [ $? -eq 0 ]
	then
		echo "Found in $FIC"
	else
		echo "Not found"
	fi
done

#!/bin/bash

source ../../config.sh

LOGIN_CARTMAN=`grep -Rial "login.*cartman" ${RESULTS_PATH}/rosa/cyrus-imapd-3.12.1/rosa-out*/backdoors`

for FIC in $LOGIN_CARTMAN
do
	echo "Found in $FIC"
done

#!/bin/bash

source ../../config.sh

USER_AGENTT_ZERODIUM=`grep -Rial "User-agentt: *zerodium" ${RESULTS_PATH}/rosa/php-8.1.0-dev/rosa-out*/backdoors`

for FIC in $USER_AGENTT_ZERODIUM
do
	echo "Found in $FIC"
done

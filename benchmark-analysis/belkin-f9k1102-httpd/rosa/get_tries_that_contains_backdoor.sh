#!/bin/bash

source ../../config.sh

DEV_CGI_C=`grep -Rial "dev.cgi" ${RESULTS_PATH}/rosa/belkin-f9k1102-httpd/rosa-out*/backdoors`

for FIC in $DEV_CGI_C
do
	echo "Found in $FIC"
done

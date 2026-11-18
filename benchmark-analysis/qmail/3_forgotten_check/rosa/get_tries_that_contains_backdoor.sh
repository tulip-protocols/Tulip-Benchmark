#!/bin/bash

source ../../../config.sh

QMAIL_VARIANT=3_forgotten_check

LIST=`egrep -Rial "list|dele|retr|stat|rset" ${RESULTS_PATH}/rosa/qmail/$QMAIL_VARIANT/rosa-out*/backdoors`

for FIC in $LIST
do
	echo "Found in $FIC"
done

#!/bin/bash

source ../../../config.sh

QMAIL_VARIANT=2_disabled_authentication_2

USER_SECRET=`grep -Rial "user.*secret" ${RESULTS_PATH}/rosa/qmail/$QMAIL_VARIANT/rosa-out*/backdoors`

for FIC in $USER_SECRET
do
	echo "Found in $FIC"
done

#!/bin/bash

source ../../../config.sh

QMAIL_VARIANT=2_disabled_authentication_3

SECR=`grep -Rial "secr" ${RESULTS_PATH}/rosa/qmail/$QMAIL_VARIANT/rosa-out*/backdoors`

for FIC in $SECR
do
	echo "Found in $FIC"
done

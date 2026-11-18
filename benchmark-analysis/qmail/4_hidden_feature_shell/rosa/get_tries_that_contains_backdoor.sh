#!/bin/bash

source ../../../config.sh

QMAIL_VARIANT=4_hidden_feature_shell

USER_SECRETSHELL=`grep -Rial "user.*secretshell" ${RESULTS_PATH}/rosa/qmail/$QMAIL_VARIANT/rosa-out*/backdoors`

for FIC in $USER_SECRETSHELL
do
	echo "Found in $FIC"
done

#!/bin/bash

source /root/config-benchmark.sh

QMAIL_VARIANT=3_forgotten_check
TARGET_PATH=${TARGETS_PATH}/synthetic/qmail-1.06/
ROSA_CONFIG_FILE=~/configs-rosa/synthetic/qmail-1.06/$QMAIL_VARIANT.toml

if [ ! -f ${TARGET_PATH}/backdoored/qmail-popup-backdoored-$QMAIL_VARIANT.ori ] || [ ! -f ${TARGET_PATH}/backdoored/qmail-popup-backdoored-$QMAIL_VARIANT.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in backdoored and backdoored-afl flavors"
    exit 1
fi

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    timeout ${MAIN_TIMEOUT} rosa ${ROSA_CONFIG_FILE}
    mv fuzzer-out fuzzer-out_qmail-${QMAIL_VARIANT}_$I
    mv rosa-out rosa-out_qmail-${QMAIL_VARIANT}_$I
done

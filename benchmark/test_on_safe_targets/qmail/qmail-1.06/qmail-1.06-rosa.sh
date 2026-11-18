#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/synthetic/qmail-1.06/
ROSA_CONFIG_FILE=./qmail-1.06-rosa.toml

if [ ! -f ${TARGET_PATH}/safe/qmail-popup-safe.ori ] || [ ! -f ${TARGET_PATH}/safe/qmail-popup-safe.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in safe and safe-afl flavors"
    exit 1
fi

for I in `seq 0 $((NUMBER_OF_RUNS_SAFE_TARGETS - 1))`
do
    timeout ${MAIN_TIMEOUT} rosa ${ROSA_CONFIG_FILE}
    mv fuzzer-out fuzzer-out_qmail-1.06_$I
    mv rosa-out rosa-out_qmail-1.06_$I
done

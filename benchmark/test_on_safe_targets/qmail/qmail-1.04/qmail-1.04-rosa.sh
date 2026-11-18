#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=./netqmail-1.04/netqmail-1.04
ROSA_CONFIG_FILE=./qmail-1.04-rosa.toml

if [ ! -f ../checkpassword/checkpassword-0.90/checkpassword ]
then
    echo "You need to build checkpassword by going to ../checkpassword and running build.sh"
    exit 1
fi

if [ ! -f ${TARGET_PATH}/qmail-popup.lto.afl ] || [ ! -f ${TARGET_PATH}/qmail-popup.ori ]
then
    echo "Run ./build.sh"
    exit 1
fi

for I in `seq 0 $((NUMBER_OF_RUNS_SAFE_TARGETS - 1))`
do
    timeout ${MAIN_TIMEOUT} rosa ${ROSA_CONFIG_FILE}
    mv fuzzer-out fuzzer-out_qmail-1.04_$I
    mv rosa-out rosa-out_qmail-1.04_$I
done

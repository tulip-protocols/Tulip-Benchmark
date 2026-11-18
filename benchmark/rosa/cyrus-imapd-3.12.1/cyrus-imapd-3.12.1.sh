#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/synthetic/cyrus-imapd-3.12.1/
ROSA_CONFIG_FILE=~/configs-rosa/synthetic/cyrus-imapd-3.12.1.toml

if [ ! -f ${TARGET_PATH}/backdoored/imapd.ori ] || [ ! -f ${TARGET_PATH}/backdoored/imapd.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in backdoored and backdoored-afl flavors"
    exit 1
fi

if [ ! -f ${TARGET_PATH}/misc/harness.so ]
then
    echo "ERROR : You need to compile the harness ${TARGET_PATH}/misc/harness.so"
    exit 1
fi

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    timeout ${MAIN_TIMEOUT} rosa ${ROSA_CONFIG_FILE}
    mv fuzzer-out fuzzer-out_cyrus-imapd-3.12.1_$I
    mv rosa-out rosa-out_cyrus-imapd-3.12.1_$I
done
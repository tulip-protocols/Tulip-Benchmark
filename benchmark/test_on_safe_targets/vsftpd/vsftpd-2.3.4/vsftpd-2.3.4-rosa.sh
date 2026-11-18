#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/vsftpd-2.3.4/
ROSA_CONFIG_FILE=./vsftpd-2.3.4-rosa.toml

if [ ! -f ${TARGET_PATH}/safe/vsftpd.ori ] || [ ! -f ${TARGET_PATH}/safe/vsftpd.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in safe and safe-afl flavors"
    exit 1
fi

for I in `seq 0 $((NUMBER_OF_RUNS_SAFE_TARGETS - 1))`
do
    timeout ${MAIN_TIMEOUT} rosa ${ROSA_CONFIG_FILE}
    mv fuzzer-out fuzzer-out_vsftpd-2.3.4_$I
    mv rosa-out rosa-out_vsftpd-2.3.4_$I
done
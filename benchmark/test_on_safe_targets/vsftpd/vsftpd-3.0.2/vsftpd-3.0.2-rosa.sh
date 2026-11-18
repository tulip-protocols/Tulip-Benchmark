#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=./
ROSA_CONFIG_FILE=./vsftpd-3.0.2-rosa.toml

if [ ! -f ${TARGET_PATH}/vsftpd.ori ] || [ ! -f ${TARGET_PATH}/vsftpd.lto.afl ]
then
    echo "ERROR: You need to run build.sh"
    exit 1
fi

for I in `seq 0 $((NUMBER_OF_RUNS_SAFE_TARGETS - 1))`
do
    timeout ${MAIN_TIMEOUT} rosa ${ROSA_CONFIG_FILE}
    mv fuzzer-out fuzzer-out_vsftpd-3.0.2_$I
    mv rosa-out rosa-out_vsftpd-3.0.2_$I
done
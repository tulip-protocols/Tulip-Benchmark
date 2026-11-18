#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/vsftpd-3.0.5/
ROSA_CONFIG_FILE=~/configs-rosa/authentic/vsftpd-3.0.5.toml

if [ ! -f ${TARGET_PATH}/backdoored/vsftpd.ori ] || [ ! -f ${TARGET_PATH}/backdoored/vsftpd.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in backdoored and backdoored-afl flavors"
    exit 1
fi

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    timeout ${MAIN_TIMEOUT} rosa ${ROSA_CONFIG_FILE}
    mv fuzzer-out fuzzer-out_vsftpd-3.0.5_$I
    mv rosa-out rosa-out_vsftpd-3.0.5_$I
done

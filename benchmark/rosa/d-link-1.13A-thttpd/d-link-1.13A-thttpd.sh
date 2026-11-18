#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/d-link-1.13A-thttpd/
ROSA_CONFIG_FILE=~/configs-rosa/authentic/d-link-1.13A-thttpd.toml

if [ ! -f ${TARGET_PATH}/backdoored/thttpd.ori ] || [ ! -f ${TARGET_PATH}/backdoored/thttpd.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in backdoored and backdoored-afl flavors"
    exit 1
fi

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    timeout ${MAIN_TIMEOUT} rosa ${ROSA_CONFIG_FILE}
    mv fuzzer-out fuzzer-out_d-link-1.13A-thttpd_$I
    mv rosa-out rosa-out_d-link-1.13A-thttpd_$I
done
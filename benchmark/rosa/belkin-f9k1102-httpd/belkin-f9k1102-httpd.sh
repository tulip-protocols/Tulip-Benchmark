#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/belkin-f9k1102-httpd/
ROSA_CONFIG_FILE=~/configs-rosa/authentic/belkin-f9k1102-httpd.toml

if [ ! -f ${TARGET_PATH}/backdoored/httpd.ori ] || [ ! -f ${TARGET_PATH}/backdoored/httpd.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in backdoored and backdoored-afl flavors"
    exit 1
fi

if [ ! -d "/tmp/www" ]
then
    echo "ERROR : You need to setup the target ${TARGET_PATH} (make setup)"
    exit 1
fi

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    timeout ${MAIN_TIMEOUT} rosa ${ROSA_CONFIG_FILE}
    mv fuzzer-out fuzzer-out_belkin-f9k1102-httpd_$I
    mv rosa-out rosa-out_belkin-f9k1102-httpd_$I
done
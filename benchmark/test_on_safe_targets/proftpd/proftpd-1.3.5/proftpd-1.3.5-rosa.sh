#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/proftpd-1.3.5/
ROSA_CONFIG_FILE=./proftpd-1.3.5-rosa.toml

if [ ! -f ${TARGET_PATH}/safe/proftpd.ori ] || [ ! -f ${TARGET_PATH}/safe/proftpd.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in safe and safe-afl flavors"
    exit 1
fi

grep $HOSTNAME /etc/hosts > /dev/null 2>&1

if [ $? -ne 0 ]
then
    echo "Setting hostname to /etc/hosts"

    sed -e "1 a 127.0.0.1 $HOSTNAME" /etc/hosts > /tmp/hosts
    cat /tmp/hosts > /etc/hosts
fi

for I in `seq 0 $((NUMBER_OF_RUNS_SAFE_TARGETS - 1))`
do
    timeout ${MAIN_TIMEOUT} rosa ${ROSA_CONFIG_FILE}
    mv fuzzer-out fuzzer-out_proftpd-1.3.5_$I
    mv rosa-out rosa-out_proftpd-1.3.5_$I
done
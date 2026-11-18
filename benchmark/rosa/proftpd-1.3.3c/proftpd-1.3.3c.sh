#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/proftpd-1.3.3c/
ROSA_CONFIG_FILE=~/configs-rosa/authentic/proftpd-1.3.3c.toml

if [ ! -f ${TARGET_PATH}/backdoored/proftpd.ori ] || [ ! -f ${TARGET_PATH}/backdoored/proftpd.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in backdoored and backdoored-afl flavors"
    exit 1
fi

grep $HOSTNAME /etc/hosts > /dev/null 2>&1

if [ $? -ne 0 ]
then
    echo "Setting hostname to /etc/hosts"

    sed -e "1 a 127.0.0.1 $HOSTNAME" /etc/hosts > /tmp/hosts
    cat /tmp/hosts > /etc/hosts
fi

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    timeout ${MAIN_TIMEOUT} rosa ${ROSA_CONFIG_FILE}
    mv fuzzer-out fuzzer-out_proftpd-1.3.3c_$I
    mv rosa-out rosa-out_proftpd-1.3.3c_$I
done
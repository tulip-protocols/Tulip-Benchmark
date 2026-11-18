#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/php-8.1.0-dev/
ROSA_CONFIG_FILE=~/configs-rosa/authentic/php-8.1.0-dev.toml

export AFL_MAP_SIZE=200000

if [ ! -f ${TARGET_PATH}/backdoored/sapi/cli/php.ori ] || [ ! -f ${TARGET_PATH}/backdoored/sapi/cli/php.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in backdoored and backdoored-afl flavors"
    exit 1
fi

if [ ! -f ${TARGET_PATH}/backdoored/php.dic ]
then
    echo "ERROR : The dictionary ${TARGET_PATH}/backdoored/php.dic is missing. Make sure everything is okay with afl-clang-fast"
    exit 1
fi

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    timeout ${MAIN_TIMEOUT} rosa ${ROSA_CONFIG_FILE}
    mv fuzzer-out fuzzer-out_php-8.1.0-dev_$I
    mv rosa-out rosa-out_php-8.1.0-dev_$I
done
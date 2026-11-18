#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/php-8.1.0-dev/

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

${CSL_PATH}/apply_config.sh ${CSL_PATH}/HTTP.csl ${CSL_PATH}/HTTP-php.config > HTTP.csl

export CBD_DICTIONARY=${TARGET_PATH}/backdoored/php.dic
export AFL_TESTCACHE_SIZE=1024
export AFL_IGNORE_TIMEOUTS=1
export AFL_IGNORE_SEED_PROBLEMS=1
export AFL_NO_STARTUP_CALIBRATION=1

/usr/local/lib/cbd/learn_syscalls.sh HTTP.csl 3 "-S 127.0.0.1:8080 -t /root/rosarum/authentic/php-8.1.0-dev/www" syscalls_learning $TARGET_PATH/backdoored/sapi/cli/php.ori

export CBD_CSLPROCESS_SYSCALL_MONITOR_WHITELIST_PATH=$PWD/syscalls_learning/syscalls_whitelist

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    mkdir csl_$I
    cslprocess HTTP.csl 3 "-S 127.0.0.1:8080 -t /root/rosarum/authentic/php-8.1.0-dev/www" csl_$I/

    export CBD_CSLPROCESS_STUFF=$PWD/csl_$I

    # Trivial backdoors detection
    cbd_ablated_default_seed -d HTTP.csl ${TARGET_PATH}/backdoored/sapi/cli/php 0 3 ${NUMBER_OF_CORES} -S 127.0.0.1:8080 -t /root/rosarum/authentic/php-8.1.0-dev/www
    mv output cbd_trivials

    cbd-iterative_ablated_default_seed ${NUMBER_OF_ITERATIONS} -dfDr HTTP.csl ${TARGET_PATH}/backdoored/sapi/cli/php "${FUZZING_TIME_DEPTH_3}" 3 ${NUMBER_OF_CORES} -S 127.0.0.1:8080 -t /root/rosarum/authentic/php-8.1.0-dev/www
    mkdir output_php-8.1.0-dev_$I
    mv csl_$I cbd_trivials cbd_output* output_php-8.1.0-dev_$I/

    tar cvf output_php-8.1.0-dev_$I.tar output_php-8.1.0-dev_$I/
    pigz output_php-8.1.0-dev_$I.tar
    rm -rf output_php-8.1.0-dev_$I/
done
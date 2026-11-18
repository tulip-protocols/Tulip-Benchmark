#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/belkin-f9k1102-httpd/

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

${CSL_PATH}/apply_config.sh ${CSL_PATH}/HTTP.csl ${CSL_PATH}/HTTP-belkin.config > HTTP.csl

export CBD_PRELOAD=/root/preloads/socket_fuzzing-belkin/socketfuzz64.so:/root/preloads/defork_aflpp/defork.so
export AFL_IGNORE_TIMEOUTS=1
export AFL_IGNORE_SEED_PROBLEMS=1
export AFL_NO_STARTUP_CALIBRATION=1

/usr/local/lib/cbd/learn_syscalls.sh HTTP.csl 3 "" syscalls_learning $TARGET_PATH/backdoored/httpd.ori

export CBD_CSLPROCESS_SYSCALL_MONITOR_WHITELIST_PATH=$PWD/syscalls_learning/syscalls_whitelist

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    mkdir csl_$I
    cslprocess HTTP.csl 3 "" csl_$I/

    export CBD_CSLPROCESS_STUFF=$PWD/csl_$I

    # Trivial backdoors detection
    cbd_ablated -d HTTP.csl ${TARGET_PATH}/backdoored/httpd 0 3 ${NUMBER_OF_CORES}
    mv output cbd_trivials

    cbd-iterative_ablated ${NUMBER_OF_ITERATIONS} -dfDr HTTP.csl ${TARGET_PATH}/backdoored/httpd "${FUZZING_TIME_ABLATED}" 3 ${NUMBER_OF_CORES}
    mkdir output_belkin-f9k1102-httpd_$I
    mv csl_$I cbd_trivials cbd_output* output_belkin-f9k1102-httpd_$I/

    tar cvf output_belkin-f9k1102-httpd_$I.tar output_belkin-f9k1102-httpd_$I/
    pigz output_belkin-f9k1102-httpd_$I.tar
    rm -rf output_belkin-f9k1102-httpd_$I/
done
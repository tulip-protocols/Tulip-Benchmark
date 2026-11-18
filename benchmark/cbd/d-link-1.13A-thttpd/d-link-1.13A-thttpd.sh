#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/d-link-1.13A-thttpd/

if [ ! -f ${TARGET_PATH}/backdoored/thttpd.ori ] || [ ! -f ${TARGET_PATH}/backdoored/thttpd.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in backdoored and backdoored-afl flavors"
    exit 1
fi

${CSL_PATH}/apply_config.sh ${CSL_PATH}/HTTP.csl ${CSL_PATH}/HTTP-dlink.config > HTTP.csl

export CBD_PRELOAD=/root/preloads/defork_aflpp/defork.so:/root/preloads/rlimit/rlimit.so:/root/preloads/socket_fuzzing/socketfuzz64.so:/root/preeny/x86_64-linux-gnu/eofkiller.so

/usr/local/lib/cbd/learn_syscalls.sh HTTP.csl 3 "-D -u root -p 8080 -d ${TARGET_PATH}/example-server" syscalls_learning $TARGET_PATH/backdoored/thttpd.ori

export CBD_CSLPROCESS_SYSCALL_MONITOR_WHITELIST_PATH=$PWD/syscalls_learning/syscalls_whitelist

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    mkdir csl_$I
    cslprocess HTTP.csl 3 "-D -u root -p 8080 -d ${TARGET_PATH}/example-server" csl_$I/

    export CBD_CSLPROCESS_STUFF=$PWD/csl_$I

    # Trivial backdoors detection
    cbd -d HTTP.csl ${TARGET_PATH}/backdoored/thttpd 0 3 ${NUMBER_OF_CORES} -D -u root -p 8080 -d ${TARGET_PATH}/example-server
    mv output cbd_trivials

    cbd-iterative ${NUMBER_OF_ITERATIONS} -dfTDro HTTP.csl ${TARGET_PATH}/backdoored/thttpd "${FUZZING_TIME_DEPTH_3}" 3 ${NUMBER_OF_CORES} -D -u root -p 8080 -d ${TARGET_PATH}/example-server
    mkdir output_d-link-1.13A-thttpd_$I
    mv cbd_trivials cbd_output* csl_$I output_d-link-1.13A-thttpd_$I/

    tar cvf output_d-link-1.13A-thttpd_$I.tar output_d-link-1.13A-thttpd_$I/
    pigz output_d-link-1.13A-thttpd_$I.tar
    rm -rf output_d-link-1.13A-thttpd_$I/
done
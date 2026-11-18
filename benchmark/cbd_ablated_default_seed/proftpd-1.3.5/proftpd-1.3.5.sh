#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/proftpd-1.3.5/

if [ ! -f ${TARGET_PATH}/backdoored/proftpd.ori ] || [ ! -f ${TARGET_PATH}/backdoored/proftpd.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in backdoored and backdoored-afl flavors"
    exit 1
fi

${CSL_PATH}/apply_config.sh ${CSL_PATH}/FTP.csl ${CSL_PATH}/FTP-proftpd.config > FTP.csl

export CBD_PRELOAD=/root/preloads/socket_fuzzing/socketfuzz64.so:/root/preloads/defork_aflpp/defork.so:/root/preeny/x86_64-linux-gnu/eofkiller.so:/root/preeny/x86_64-linux-gnu/dealarm.so:/root/preeny/x86_64-linux-gnu/desigact.so:/root/preeny/x86_64-linux-gnu/derand.so:/root/preeny/x86_64-linux-gnu/detime.so:/root/preeny/x86_64-linux-gnu/desleep.so

/usr/local/lib/cbd/learn_syscalls.sh FTP.csl 3 "-n -c ${TARGET_PATH}/proftpd.conf" syscalls_learning ${TARGET_PATH}/backdoored/proftpd.ori

export CBD_CSLPROCESS_SYSCALL_MONITOR_WHITELIST_PATH=$PWD/syscalls_learning/syscalls_whitelist

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    mkdir csl_$I
    cslprocess FTP.csl 3 "-n -c ${TARGET_PATH}/proftpd.conf" csl_$I/

    export CBD_CSLPROCESS_STUFF=$PWD/csl_$I

    # Trivial backdoors detection
    cbd_ablated_default_seed -d FTP.csl ${TARGET_PATH}/backdoored/proftpd 0 3 ${NUMBER_OF_CORES} -n -c ${TARGET_PATH}/proftpd.conf
    mv output cbd_trivials

    cbd-iterative_ablated_default_seed ${NUMBER_OF_ITERATIONS} -dcDr FTP.csl ${TARGET_PATH}/backdoored/proftpd "${FUZZING_TIME_ABLATED}" 3 ${NUMBER_OF_CORES} -n -c ${TARGET_PATH}/proftpd.conf
    mkdir output_proftpd-1.3.5_$I
    mv csl_$I csl_$I cbd_trivials cbd_output* output_proftpd-1.3.5_$I/

    tar cvf output_proftpd-1.3.5_$I.tar output_proftpd-1.3.5_$I/
    pigz output_proftpd-1.3.5_$I.tar
    rm -rf output_proftpd-1.3.5_$I/
done
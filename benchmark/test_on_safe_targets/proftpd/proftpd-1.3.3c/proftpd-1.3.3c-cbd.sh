#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/proftpd-1.3.3c/

if [ ! -f ${TARGET_PATH}/safe/proftpd.ori ] || [ ! -f ${TARGET_PATH}/safe/proftpd.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in safe and safe-afl flavors"
    exit 1
fi

${CSL_PATH}/apply_config.sh ${CSL_PATH}/FTP.csl ${CSL_PATH}/FTP-proftpd.config > FTP.csl

export CBD_PRELOAD=/root/preloads/socket_fuzzing/socketfuzz64.so:/root/preloads/defork_aflpp/defork.so:/root/preeny/x86_64-linux-gnu/eofkiller.so:/root/preeny/x86_64-linux-gnu/dealarm.so:/root/preeny/x86_64-linux-gnu/desigact.so:/root/preeny/x86_64-linux-gnu/derand.so:/root/preeny/x86_64-linux-gnu/detime.so:/root/preeny/x86_64-linux-gnu/desleep.so

/usr/local/lib/cbd/learn_syscalls.sh FTP.csl 3 "-n -c ${TARGET_PATH}/proftpd.conf" syscalls_learning ${TARGET_PATH}/safe/proftpd.ori

export CBD_CSLPROCESS_SYSCALL_MONITOR_WHITELIST_PATH=$PWD/syscalls_learning/syscalls_whitelist

for I in `seq 0 $((NUMBER_OF_RUNS_SAFE_TARGETS - 1))`
do
    mkdir csl_$I
    cslprocess FTP.csl 3 "-n -c ${TARGET_PATH}/proftpd.conf" csl_$I/

    export CBD_CSLPROCESS_STUFF=$PWD/csl_$I

    cbd-iterative ${NUMBER_OF_ITERATIONS} -dcTDro FTP.csl ${TARGET_PATH}/safe/proftpd "${FUZZING_TIME_DEPTH_3}" 3 ${NUMBER_OF_CORES} -n -c ${TARGET_PATH}/proftpd.conf
    mkdir output_proftpd-1.3.3c_$I
    mv cbd_trivials cbd_output* csl_$I output_proftpd-1.3.3c_$I/

    tar cvf output_proftpd-1.3.3c_$I.tar output_proftpd-1.3.3c_$I/
    pigz output_proftpd-1.3.3c_$I.tar
    rm -rf output_proftpd-1.3.3c_$I/
done

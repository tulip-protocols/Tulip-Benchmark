#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/authentic/vsftpd-2.3.4/

if [ ! -f ${TARGET_PATH}/safe/vsftpd.ori ] || [ ! -f ${TARGET_PATH}/safe/vsftpd.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in safe and safe-afl flavors"
    exit 1
fi

${CSL_PATH}/apply_config.sh ${CSL_PATH}/FTP.csl ${CSL_PATH}/FTP-vsftpd.config > FTP.csl

export CBD_PRELOAD=/root/preloads/desock_dup/desock_dup.so:/root/preloads/defstat/defstat.so:/root/preloads/defork_aflpp/defork.so:/root/preeny/x86_64-linux-gnu/writeout.so:/root/preeny/x86_64-linux-gnu/desleep.so:/root/preeny/x86_64-linux-gnu/dealarm.so:/root/preeny/x86_64-linux-gnu/detime.so:/root/preeny/x86_64-linux-gnu/derand.so

/usr/local/lib/cbd/learn_syscalls.sh FTP.csl 3 "$TARGET_PATH/vsftpd.conf" syscalls_learning $TARGET_PATH/safe/vsftpd.ori

export CBD_CSLPROCESS_SYSCALL_MONITOR_WHITELIST_PATH=$PWD/syscalls_learning/syscalls_whitelist

for I in `seq 0 $((NUMBER_OF_RUNS_SAFE_TARGETS - 1))`
do
    mkdir csl_$I
    cslprocess FTP.csl 3 "$TARGET_PATH/vsftpd.conf" csl_$I/

    export CBD_CSLPROCESS_STUFF=$PWD/csl_$I

    cbd-iterative ${NUMBER_OF_ITERATIONS} -dcTDro FTP.csl ${TARGET_PATH}/safe/vsftpd "${FUZZING_TIME_DEPTH_3}" 3 ${NUMBER_OF_CORES} $TARGET_PATH/vsftpd.conf
    mkdir output_vsftpd-2.3.4_$I
    mv cbd_trivials cbd_output* csl_$I output_vsftpd-2.3.4_$I/

    tar cvf output_vsftpd-2.3.4_$I.tar output_vsftpd-2.3.4_$I/
    pigz output_vsftpd-2.3.4_$I.tar
    rm -rf output_vsftpd-2.3.4_$I/
done
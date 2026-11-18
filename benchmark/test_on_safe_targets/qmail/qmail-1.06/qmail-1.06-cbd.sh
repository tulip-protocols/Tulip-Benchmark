#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/synthetic/qmail-1.06/

if [ ! -f ${TARGET_PATH}/safe/qmail-popup-safe.ori ] || [ ! -f ${TARGET_PATH}/safe/qmail-popup-safe.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in safe and safe-afl flavors"
    exit 1
fi

${CSL_PATH}/apply_config.sh ${CSL_PATH}/POP3.csl ${CSL_PATH}/POP3-qmail.config > POP3.csl

/usr/local/lib/cbd/learn_syscalls.sh POP3.csl 3 "localhost ${TARGET_PATH}/safe/checkpassword ${TARGET_PATH}/safe/qmail-pop3d ${TARGET_PATH}/safe/Mailbox" syscalls_learning ${TARGET_PATH}/safe/qmail-popup-safe.ori

export CBD_CSLPROCESS_SYSCALL_MONITOR_WHITELIST_PATH=$PWD/syscalls_learning/syscalls_whitelist

for I in `seq 0 $((NUMBER_OF_RUNS_SAFE_TARGETS - 1))`
do
    mkdir csl_$I
    cslprocess ./POP3.csl 3 "localhost ${TARGET_PATH}/safe/checkpassword ${TARGET_PATH}/safe/qmail-pop3d ${TARGET_PATH}/safe/Mailbox" csl_$I/

    export CBD_CSLPROCESS_STUFF=$PWD/csl_$I

    cbd-iterative ${NUMBER_OF_ITERATIONS} -dcTDro POP3.csl ${TARGET_PATH}/safe/qmail-popup-safe "${FUZZING_TIME_DEPTH_3}" 3 ${NUMBER_OF_CORES} localhost ${TARGET_PATH}/safe/checkpassword ${TARGET_PATH}/safe/qmail-pop3d ${TARGET_PATH}/safe/Mailbox
    mkdir output_qmail-1.06_$I
    mv cbd_trivials cbd_output* csl_$I output_qmail-1.06_$I/

    tar cvf output_qmail-1.06_$I.tar output_qmail-1.06_$I/
    pigz output_qmail-1.06_$I.tar
    rm -rf output_qmail-1.06_$I/
done
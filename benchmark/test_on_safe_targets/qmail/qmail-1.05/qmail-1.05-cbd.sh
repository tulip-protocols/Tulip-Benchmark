#!/bin/bash

source /root/config-benchmark.sh

export TARGET_PATH=./netqmail-1.05/netqmail-1.05

if [ ! -f ../checkpassword/checkpassword-0.90/checkpassword ]
then
    echo "You need to build checkpassword by going to ../checkpassword and running build.sh"
    exit 1
fi

if [ ! -f ${TARGET_PATH}/qmail-popup.lto.afl ] || [ ! -f ${TARGET_PATH}/qmail-popup.ori ]
then
    echo "Run ./build.sh"
    exit 1
fi

${CSL_PATH}/apply_config.sh ${CSL_PATH}/POP3.csl ${CSL_PATH}/POP3-qmail.config > POP3.csl

/usr/local/lib/cbd/learn_syscalls.sh POP3.csl 3 "localhost ../checkpassword/checkpassword-0.90/checkpassword ${TARGET_PATH}/qmail-pop3d ./Mailbox" syscalls_learning ${TARGET_PATH}/qmail-popup

export CBD_CSLPROCESS_SYSCALL_MONITOR_WHITELIST_PATH=$PWD/syscalls_learning/syscalls_whitelist

for I in `seq 0 $((NUMBER_OF_RUNS_SAFE_TARGETS - 1))`
do
    mkdir csl_$I
    cslprocess POP3.csl 3 "localhost ../checkpassword/checkpassword-0.90/checkpassword ${TARGET_PATH}/qmail-pop3d ./Mailbox" csl_$I/

    export CBD_CSLPROCESS_STUFF=$PWD/csl_$I

    cbd-iterative ${NUMBER_OF_ITERATIONS} -dcTDro POP3.csl ${TARGET_PATH}/qmail-popup "${FUZZING_TIME_DEPTH_3}" 3 ${NUMBER_OF_CORES} localhost ../checkpassword/checkpassword-0.90/checkpassword ${TARGET_PATH}/qmail-pop3d ./Mailbox
    mkdir output_qmail-1.05_$I
    mv cbd_trivials cbd_output* csl_$I output_qmail-1.05_$I/

    tar cvf output_qmail-1.05_$I.tar output_qmail-1.05_$I/
    pigz output_qmail-1.05_$I.tar
    rm -rf output_qmail-1.05_$I/
done

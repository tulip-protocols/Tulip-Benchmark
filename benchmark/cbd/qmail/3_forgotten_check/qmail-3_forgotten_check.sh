#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/synthetic/qmail-1.06/
QMAIL_VARIANT=3_forgotten_check

if [ ! -f ${TARGET_PATH}/backdoored/qmail-popup-backdoored-$QMAIL_VARIANT.ori ] || [ ! -f ${TARGET_PATH}/backdoored/qmail-popup-backdoored-$QMAIL_VARIANT.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in backdoored and backdoored-afl flavors"
    exit 1
fi

${CSL_PATH}/apply_config.sh ${CSL_PATH}/POP3.csl ${CSL_PATH}/POP3-qmail.config > POP3.csl

/usr/local/lib/cbd/learn_syscalls.sh POP3.csl 3 "localhost ${TARGET_PATH}/backdoored/checkpassword ${TARGET_PATH}/backdoored/qmail-pop3d ${TARGET_PATH}/backdoored/Mailbox" syscalls_learning ${TARGET_PATH}/backdoored/qmail-popup-backdoored-$QMAIL_VARIANT.ori

export CBD_CSLPROCESS_SYSCALL_MONITOR_WHITELIST_PATH=$PWD/syscalls_learning/syscalls_whitelist

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    mkdir csl_$I
    cslprocess POP3.csl 3 "localhost ${TARGET_PATH}/backdoored/checkpassword ${TARGET_PATH}/backdoored/qmail-pop3d ${TARGET_PATH}/backdoored/Mailbox" csl_$I/

    export CBD_CSLPROCESS_STUFF=$PWD/csl_$I

    # Trivial backdoors detection
    cbd -d POP3.csl ${TARGET_PATH}/backdoored/qmail-popup-backdoored-$QMAIL_VARIANT 0 3 ${NUMBER_OF_CORES} localhost ${TARGET_PATH}/backdoored/checkpassword ${TARGET_PATH}/backdoored/qmail-pop3d ${TARGET_PATH}/backdoored/Mailbox
    mv output cbd_trivials

    cbd-iterative ${NUMBER_OF_ITERATIONS} -dcTDro POP3.csl ${TARGET_PATH}/backdoored/qmail-popup-backdoored-$QMAIL_VARIANT "${FUZZING_TIME_DEPTH_3}" 3 ${NUMBER_OF_CORES} localhost ${TARGET_PATH}/backdoored/checkpassword ${TARGET_PATH}/backdoored/qmail-pop3d ${TARGET_PATH}/backdoored/Mailbox
    mkdir output_qmail-${QMAIL_VARIANT}_$I
    mv cbd_trivials cbd_output* csl_$I output_qmail-${QMAIL_VARIANT}_$I/

    tar cvf output_qmail-${QMAIL_VARIANT}_$I.tar output_qmail-${QMAIL_VARIANT}_$I/
    pigz output_qmail-${QMAIL_VARIANT}_$I.tar
    rm -rf output_qmail-${QMAIL_VARIANT}_$I/
done
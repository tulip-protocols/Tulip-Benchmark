#!/bin/bash

source /root/config-benchmark.sh

TARGET_PATH=${TARGETS_PATH}/synthetic/cyrus-imapd-3.12.1/

if [ ! -f ${TARGET_PATH}/backdoored/imapd.ori ] || [ ! -f ${TARGET_PATH}/backdoored/imapd.lto.afl ]
then
    echo "ERROR : You need to compile the target ${TARGET_PATH} in backdoored and backdoored-afl flavors"
    exit 1
fi

if [ ! -f ${TARGET_PATH}/misc/harness.so ]
then
    echo "ERROR : You need to compile the harness ${TARGET_PATH}/misc/harness.so"
    exit 1
fi

${CSL_PATH}/apply_config.sh ${CSL_PATH}/IMAP.csl ${CSL_PATH}/IMAP-cyrus.config > IMAP.csl

export CBD_PRELOAD=${TARGET_PATH}/misc/harness.so:/root/preloads/socket_fuzzing-cyrus/socketfuzz64.so:/root/preloads/dechangeuser/dechangeuser.so:/root/preloads/defork_aflpp/defork.so:/root/preeny/x86_64-linux-gnu/detime.so:/root/preeny/x86_64-linux-gnu/desleep.so:/root/preeny/x86_64-linux-gnu/eofkiller.so:/root/preeny/x86_64-linux-gnu/dealarm.so:/root/preeny/x86_64-linux-gnu/desigact.so:/root/preeny/x86_64-linux-gnu/derand.so:/root/preeny/x86_64-linux-gnu/detime.so:/root/preeny/x86_64-linux-gnu/desleep.so

/usr/local/lib/cbd/learn_syscalls.sh IMAP.csl 3 "-X" syscalls_learning $TARGET_PATH/backdoored/imapd.ori

export CBD_CSLPROCESS_SYSCALL_MONITOR_WHITELIST_PATH=$PWD/syscalls_learning/syscalls_whitelist

for I in `seq 0 $((NUMBER_OF_RUNS - 1))`
do
    mkdir csl_$I
    cslprocess IMAP.csl 3 "-X" csl_$I/

    export CBD_CSLPROCESS_STUFF=$PWD/csl_$I

    # Trivial backdoors detection
    cbd -d IMAP.csl ${TARGET_PATH}/backdoored/imapd 0 3 ${NUMBER_OF_CORES} -X
    mv output cbd_trivials

    cbd-iterative ${NUMBER_OF_ITERATIONS} -dcTDro IMAP.csl ${TARGET_PATH}/backdoored/imapd "${FUZZING_TIME_DEPTH_3}" 3 ${NUMBER_OF_CORES} -X
    mkdir output_cyrus-imapd-3.12.1_$I
    mv cbd_trivials cbd_output* csl_$I output_cyrus-imapd-3.12.1_$I/

    tar cvf output_cyrus-imapd-3.12.1_$I.tar output_cyrus-imapd-3.12.1_$I/
    pigz output_cyrus-imapd-3.12.1_$I.tar
    rm -rf output_cyrus-imapd-3.12.1_$I/
done

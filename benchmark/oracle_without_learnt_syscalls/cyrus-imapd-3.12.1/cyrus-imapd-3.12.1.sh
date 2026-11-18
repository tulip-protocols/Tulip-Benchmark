#!/bin/bash

source /root/config-benchmark.sh

if [ "x${RESULTS_PATH}" == "x" ]
then
    RESULTS_PATH=/root/benchmark
fi

TARGET_NAME=cyrus-imapd-3.12.1
TRUE_POSITIVES_REGEX="execve.*sh.*"
TARGET_PATH=${TARGETS_PATH}/authentic/$TARGET_NAME
ORIGINAL_RESULTS_PATH=${RESULTS_PATH}/cbd/$TARGET_NAME

${CSL_PATH}/apply_config.sh ${CSL_PATH}/IMAP.csl ${CSL_PATH}/IMAP-cyrus.config > IMAP.csl

mkdir csl/
cslprocess IMAP.csl 3 "-X" csl/

for FIC in `ls $ORIGINAL_RESULTS_PATH/*.tar.gz`
do
    tar --wildcards -xvf $FIC '*/*/apply_wildcard' '*/*/syscalls' '*/*/static'
done

for CURRENT_RUN in `ls -d output_$TARGET_NAME*/`
do
    for CURRENT_ITERATION in `ls -d $CURRENT_RUN/cbd_trivials $CURRENT_RUN/cbd_output_iteration*`
    do
        for GENERATED_INPUTS_ITERATION_NUMBER in `ls $CURRENT_ITERATION/apply_wildcard/* -d | rev | cut -d'/' -f1 | rev`
        do
            mkdir -p $CURRENT_ITERATION/syscall_monitor/generated_$GENERATED_INPUTS_ITERATION_NUMBER

            ./csl/syscall_monitor/syscall_monitor $CURRENT_ITERATION/apply_wildcard/$GENERATED_INPUTS_ITERATION_NUMBER $CURRENT_ITERATION/syscalls/generated_$GENERATED_INPUTS_ITERATION_NUMBER $CURRENT_ITERATION/syscall_monitor/generated_$GENERATED_INPUTS_ITERATION_NUMBER
        done

        for STATIC_INPUTS_NUMBERS in `ls $CURRENT_ITERATION/syscalls/static* -d | rev | cut -d'/' -f1 | rev | cut -d'_' -f2`
        do
            mkdir -p $CURRENT_ITERATION/syscall_monitor/static_$STATIC_INPUTS_NUMBERS

            ./csl/syscall_monitor/syscall_monitor $CURRENT_ITERATION/static/$STATIC_INPUTS_NUMBERS $CURRENT_ITERATION/syscalls/static_$STATIC_INPUTS_NUMBERS $CURRENT_ITERATION/syscall_monitor/static_$STATIC_INPUTS_NUMBERS
        done
    done
done

echo "run,number_of_false_positives" > results_oracle_ablated_without_learnt_syscalls

for CURRENT_RUN in `ls -d output_$TARGET_NAME*/`
do
    ORACLE_REPORTS_FILES=`find $CURRENT_RUN -name __report__.txt | xargs`
    CURRENT_RUN_WITHOUT_SLASH=`echo $CURRENT_RUN | sed -re "s?/??g"`

    if [ "x${ORACLE_REPORTS_FILES}" != "x" ]
    then
        ORACLE_REPORTS_SYSCALLS_FALSE_POSITIVES=`cat $ORACLE_REPORTS_FILES | grep "^--" | grep -v "$TRUE_POSITIVES_REGEX" | cut -d' ' -f2 | cut -d'(' -f1 | sort | uniq | wc -l`

        echo "$CURRENT_RUN_WITHOUT_SLASH,$ORACLE_REPORTS_SYSCALLS_FALSE_POSITIVES" >> results_oracle_ablated_without_learnt_syscalls
    else
        echo "$CURRENT_RUN_WITHOUT_SLASH,0" >> results_oracle_ablated_without_learnt_syscalls
    fi
done
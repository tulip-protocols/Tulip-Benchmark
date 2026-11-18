#!/bin/bash

CSL_FILE_PATH="$1"
CSL_DEPTH="$2"
CSL_TARGET_ARGS="$3"
CSL_OUTPUT_DIR="$4"
TARGET_PATH="$5"
GET_SYSCALLS_BASE_DIRECTORY="$6"

if grep "adversarial_sequences_generation_mode = minimal" $CSL_FILE_PATH
then
        NEW_CSL=`mktemp`
        cp $CSL_FILE_PATH $NEW_CSL
        sed -re "/adversarial_sequences_generation_mode/s/minimal/full/g" -i $NEW_CSL

        export CSL_FILE_PATH=$NEW_CSL
elif ! grep "adversarial_sequences_generation_mode" $CSL_FILE_PATH
then
        NEW_CSL=`mktemp`
        cp $CSL_FILE_PATH $NEW_CSL
        sed -re "1iadversarial_sequences_generation_mode = full;" -i $NEW_CSL

        export CSL_FILE_PATH=$NEW_CSL
fi

mkdir -p $CSL_OUTPUT_DIR
cslprocess "$CSL_FILE_PATH" "$CSL_DEPTH" "$CSL_TARGET_ARGS" "$CSL_OUTPUT_DIR"

# Getting syscalls from generated seeds
echo "[learn_syscalls] Collecting syscalls for all generated seeds"

mkdir -p $CSL_OUTPUT_DIR/syscalls
$CSL_OUTPUT_DIR/syscall_monitor/get_syscalls.sh $CSL_OUTPUT_DIR/legal_sequences $CSL_OUTPUT_DIR/syscalls $TARGET_PATH $GET_SYSCALLS_BASE_DIRECTORY

echo "[learn_syscalls] Learning syscalsl from previously got syscalls"

$CSL_OUTPUT_DIR/syscall_monitor/syscall_learner $CSL_OUTPUT_DIR/legal_sequences $CSL_OUTPUT_DIR/syscalls > $CSL_OUTPUT_DIR/syscalls_whitelist
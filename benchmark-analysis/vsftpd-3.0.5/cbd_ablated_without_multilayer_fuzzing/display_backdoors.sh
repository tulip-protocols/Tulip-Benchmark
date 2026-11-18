#!/bin/bash

source ../../config.sh
source ../../../config-benchmark.sh

bat ${RESULTS_PATH}/cbd_ablated_without_multilayer_fuzzing/vsftpd-3.0.5/output*/cbd_output_iteration_$((NUMBER_OF_RUNS - 1))/potential_backdoors/*/*

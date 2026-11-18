#!/bin/bash

source ../../config.sh
source ../../../config-benchmark.sh

bat ${RESULTS_PATH}/cbd_ablated_without_multilayer_fuzzing/vsftpd-2.3.4/output*/cbd_output_iteration_$((NUMBER_OF_ITERATIONS - 1))/potential_backdoors/*/*

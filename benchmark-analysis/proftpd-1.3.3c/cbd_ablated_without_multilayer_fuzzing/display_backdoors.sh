#!/bin/bash

source ../../config.sh
source ../../../config-benchmark.sh

bat ${RESULTS_PATH}/cbd_ablated_without_multilayer_fuzzing/proftpd-1.3.3c/output*/cbd_output_iteration_*/potential_backdoors/*/*

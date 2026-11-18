#!/bin/bash

source ../../config.sh
source ../../../config-benchmark.sh

bat ${RESULTS_PATH}/cbd_ablated_without_multilayer_fuzzing/cyrus-imapd-3.12.1/output*/cbd_output_iteration_*/potential_backdoors/*/*

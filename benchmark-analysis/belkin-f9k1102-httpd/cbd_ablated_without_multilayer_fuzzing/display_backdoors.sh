#!/bin/bash

source ../../config.sh
source ../../../config-benchmark.sh

bat ${RESULTS_PATH}/cbd_ablated_without_multilayer_fuzzing/belkin-f9k1102-httpd/output*/cbd_output_iteration_*/potential_backdoors/*/*

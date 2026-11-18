#!/bin/bash

source ../../config.sh
source ../../../config-benchmark.sh

bat ${RESULTS_PATH}/cbd_ablated_without_multilayer_fuzzing/php-8.1.0-dev/output*/cbd_output_iteration_*/potential_backdoors/*/*

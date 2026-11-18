#!/bin/bash

source ../../config.sh
source ../../../config-benchmark.sh

bat ${RESULTS_PATH}/cbd_ablated_default_seed/d-link-1.13A-thttpd/output*/cbd_output_iteration_$((NUMBER_OF_ITERATIONS - 1))/potential_backdoors/*/*

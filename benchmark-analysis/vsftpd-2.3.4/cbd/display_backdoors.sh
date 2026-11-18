#!/bin/bash

source ../../config.sh
source ../../../config-benchmark.sh

bat ${RESULTS_PATH}/cbd/vsftpd-2.3.4/output*/cbd_output_iteration_$((NUMBER_OF_ITERATIONS - 1))/potential_backdoors/*/*

#!/bin/bash

source ../../../config.sh
source ../../../../config-benchmark.sh

QMAIL_VARIANT=1_hard-codded_credentials

bat ${RESULTS_PATH}/cbd_ablated_default_seed/qmail/$QMAIL_VARIANT/output*/*/potential_backdoors/*/*

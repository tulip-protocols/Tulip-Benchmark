#!/bin/bash

source ../../../config.sh
source ../../../../config-benchmark.sh

QMAIL_VARIANT=2_disabled_authentication_2

bat ${RESULTS_PATH}/cbd_ablated_default_seed/qmail/$QMAIL_VARIANT/output*/*/potential_backdoors/*/*

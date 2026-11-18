#!/bin/bash

source ../../../config.sh
source ../../../../config-benchmark.sh

QMAIL_VARIANT=3_forgotten_check

bat ${RESULTS_PATH}/cbd/qmail/$QMAIL_VARIANT/output*/*/potential_backdoors/*/*

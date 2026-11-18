#!/bin/bash

source ../../../config.sh
source ../../../../config-benchmark.sh

QMAIL_VARIANT=4_hidden_feature_shell

bat ${RESULTS_PATH}/cbd/qmail/$QMAIL_VARIANT/output*/*/potential_backdoors/*/*

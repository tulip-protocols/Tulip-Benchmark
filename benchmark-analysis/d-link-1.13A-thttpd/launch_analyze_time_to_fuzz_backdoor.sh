#!/bin/bash

source ../../config-benchmark.sh

R --quiet --save < ../analyze_time_to_fuzz_backdoor.R

#!/bin/bash

source ../../config-benchmark.sh

R --quiet --save < ../analyze_false_positives.R

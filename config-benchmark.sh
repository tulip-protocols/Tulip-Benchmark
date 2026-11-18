#!/bin/bash

# AFL-specific options
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
export AFL_SKIP_CPUFREQ=1
export AFL_NO_ARITH=1

# Config file to set benchmark options
export NUMBER_OF_RUNS=20
export NUMBER_OF_RUNS_SAFE_TARGETS=5
export MAIN_TIMEOUT=1h # Main benchmark timout
export MAIN_TIMEOUT_IN_S=3600

# --- [CBD-related options] ---------------------
# NUMBER_OF_ITERATIONS : Number of iterations in CBD (We use iterative mode)
# We run 20 iterations of 3 minutes -> 60 minutes = 1 hour
export NUMBER_OF_ITERATIONS=20

# FUZZING_TIME_DEPTH_n : Fuzzing time for the phase i of n
# When a depth of 1 is used, FUZZING_TIME_DEPTH_1 is used, when a depth of 2 is used, it is FUZZING_TIME_DEPTH_2, etc.
export FUZZING_TIME_DEPTH_1="180"
export FUZZING_TIME_DEPTH_2="90,90"
export FUZZING_TIME_DEPTH_3="60,60,60"
export FUZZING_TIME_DEPTH_4="45,45,45,45"
export FUZZING_TIME_DEPTH_5="36,36,36,36,36"
export FUZZING_TIME_DEPTH_7="25,25,25,25,25,25,25" # Rounded (180 / 7 = 25.71) ; Missed 5s

# FUZZING_TIME_DEPTH_n : Fuzzing time for the phase i of n for one shot runs (i.e. without cbd-iterative, used to test CBD on safe targets)
export FUZZING_TIME_DEPTH_1_ONE_SHOT="3600"
export FUZZING_TIME_DEPTH_2_ONE_SHOT="1800,1800"
export FUZZING_TIME_DEPTH_3_ONE_SHOT="1200,1200,1200"
export FUZZING_TIME_DEPTH_4_ONE_SHOT="900,900,900,900"
export FUZZING_TIME_DEPTH_5_ONE_SHOT="720,720,720,720,720"

# Fuzzing for the ablation studies
# Basically, this is the same as the time for a depth of 1, because -T is not supported in CBD Ablated
export FUZZING_TIME_ABLATED="$FUZZING_TIME_DEPTH_1"

# NUMBER_OF_CORES : Maximum number of CPU cores that CBD can use
export NUMBER_OF_CORES=6

export ITERATION_TIME=$FUZZING_TIME_DEPTH_1

# AFL++-related stuff
export AFL_IGNORE_SEED_PROBLEMS=1
export AFL_NO_STARTUP_CALIBRATION=1
export AFL_NO_AFFINITY=1

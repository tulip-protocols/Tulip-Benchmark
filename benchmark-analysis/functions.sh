#!/bin/bash

is_debug_on()
{
	if [ "x$DEBUG_TULIP_RESULTS" == "x" ]
	then
		false
	else
		true
	fi
}

get_iteration_that_found_first_the_backdoor()
{
	OUTPUT_DIR="$1"
	RESULT=$NUMBER_OF_ITERATIONS

	if [ "x$PATH_OFFSET" == "x" ]
	then
		PATH_OFFSET=5
	fi

	NUMBER_UNDERSCORES=`ls -d $OUTPUT_DIR | tr -cd '_' | wc -c`
	DIRS=`ls -d $OUTPUT_DIR/* | sort -t'_' -k$((NUMBER_UNDERSCORES + 4)) -n | sed -re 's?$?/potential_backdoors?g' | grep -v trivials | grep -v csl | xargs`

	FOUNDS=`mktemp`

	find $OUTPUT_DIR/cbd_trivials $DIRS -type f > $FOUNDS

	while read FIC
	do
		if is_true_positive $FIC
		then
			if echo $FIC | grep trivial > /dev/null 2>&1
			then
				RESULT=-1

				break
			else
				ITERATION_NUMBER=`echo $FIC | sed -re "s?$RESULTS_PATH??g" | cut -d'/' -f$PATH_OFFSET | cut -d'_' -f4`

				if [ $ITERATION_NUMBER -lt $RESULT ]
				then
					RESULT=$ITERATION_NUMBER

					break
				fi
			fi
		fi
	done < $FOUNDS

	echo $RESULT
}

get_completing_time_of_iteration()
{
	FUZZING_TIMES_PER_ITERATION_NUMBER_INTERVAL="$1" # Example : "0-9:3,10-19:10"
	CURRENT_ITERATION_NUMBER="$2"

	STOP=0
	I=1

	while [ $STOP -eq 0 ]
	do
		CURRENT_TIME_SPEC=`echo $FUZZING_TIMES_PER_ITERATION_NUMBER_INTERVAL | cut -d',' -f$I` # 0-9:3
		CURRENT_TIME_SPEC_ASSOCIATED_TIME=`echo $CURRENT_TIME_SPEC | cut -d':' -f2` # 3
		CURRENT_TIME_SPEC_ITERATIONS_INTERVAL=`echo $CURRENT_TIME_SPEC | cut -d':' -f1` # 0-9
		CURRENT_ITERATION_TIME_BOTTOM_ITERATION_NUMBER=`echo $CURRENT_TIME_SPEC_ITERATIONS_INTERVAL | cut -d'-' -f1` # 0
		CURRENT_ITERATION_TIME_TOP_ITERATION_NUMBER=`echo $CURRENT_TIME_SPEC_ITERATIONS_INTERVAL | cut -d'-' -f2` # 9

		if [ "x$CURRENT_TIME_SPEC" == "x" ]
		then
			STOP=1
			RESULT=-1
		elif [ $CURRENT_ITERATION_TIME_BOTTOM_ITERATION_NUMBER -le $CURRENT_ITERATION_NUMBER ] && [ $CURRENT_ITERATION_TIME_TOP_ITERATION_NUMBER -ge $CURRENT_ITERATION_NUMBER ]
		then
			STOP=1
			RESULT=$CURRENT_TIME_SPEC_ASSOCIATED_TIME
		else
			I=$((I + 1))
		fi
	done

	if [ $CURRENT_ITERATION_NUMBER -ne 0 ]
	then
		PREVIOUS_ITERATION_TOTAL_TIME=`get_completing_time_of_iteration "$FUZZING_TIMES_PER_ITERATION_NUMBER_INTERVAL" $((CURRENT_ITERATION_NUMBER - 1))`

		echo $((PREVIOUS_ITERATION_TOTAL_TIME + RESULT))
	else
		echo $RESULT
	fi
}

get_total_times()
{
	RUN_REGEX="$1"
	TARGET_NAME="$2"

	if [ "x$CBD_VARIANT" == "x" ]
	then
		CBD_VARIANT=cbd
	fi

	for FIC in `get_true_positives`
	do
		RUN=`echo $FIC | grep -o "$RUN_REGEX"`
		OUTPUT_DIR=$RESULTS_PATH/$CBD_VARIANT/$TARGET_NAME/$RUN

		NUMBER_OF_THE_FIRST_ITERATION_THAT_FOUND_THE_BACKDOOR=`get_iteration_that_found_first_the_backdoor $OUTPUT_DIR`

		if [ "x$CBD_ITERATIVE_TIME_PER_ITERATIONS_ITERVAL" != "x" ]
		then
			TOTAL_TIME_IN_S=`get_completing_time_of_iteration "$CBD_ITERATIVE_TIME_PER_ITERATIONS_ITERVAL" $NUMBER_OF_THE_FIRST_ITERATION_THAT_FOUND_THE_BACKDOOR`
		else
			TOTAL_TIME_IN_S=$(((NUMBER_OF_THE_FIRST_ITERATION_THAT_FOUND_THE_BACKDOOR + 1) * ITERATION_TIME)) # +1 because iterations begins by 0
		fi

		echo $RUN:${TOTAL_TIME_IN_S}s
	done
}

cbd_instances_with_times()
{
	RUN_REGEX="$1"
	TARGET_NAME="$2"

	CURRENT_CBD_INSTANCE=""
	
	for CBD_INSTANCE_WITH_TIME in `get_total_times "$RUN_REGEX" "$TARGET_NAME"`
	do
		CBD_INSTANCE=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f1`
		TIME=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f2`
	
		if [ "x$CURRENT_CBD_INSTANCE" != "x$CBD_INSTANCE" ]
		then
			if [ "x$CURRENT_CBD_INSTANCE" != "x" ]
			then
				echo
			fi
	
			CURRENT_CBD_INSTANCE=$CBD_INSTANCE
	
			echo -n "$CURRENT_CBD_INSTANCE:$TIME"
		else
			echo -n ",$TIME"
		fi
	done
}

process_false_positives()
{
	RUN_REGEX="$1"
	TARGET_NAME="$2"
	TRUE_POSITIVE_SYSCALL_REGEX="$3"

	for FIC in `get_false_positives`
	do
		RUN=`echo $FIC | grep -o "$RUN_REGEX"`

		if ! [[ $FIC =~ .*__report__.txt ]] && ! [[ $FIC =~ .*_strange ]]
		then
			# Handling automaton-based positives

			if ! is_true_positive $FIC
			then
				is_debug_on && echo $FIC 1>&2 && cat $FIC 1>&2

				echo $RUN:automaton
			fi
		else
			# Handling syscalls-based positives

			if [[ $FIC =~ .*__report__.txt ]]
			then
				FALSE_POSITIVES_SYSCALLS=`cat $FIC | grep "^--" | grep -v "$TRUE_POSITIVE_SYSCALL_REGEX" | cut -d' ' -f2 | cut -d'(' -f1 | sort | uniq | xargs | tr ' ' ','`

				if [ "x$FALSE_POSITIVES_SYSCALLS" != "x" ]
				then
					is_debug_on && echo $FIC 1>&2 && cat $FIC | grep "^--" | grep -v "$TRUE_POSITIVE_SYSCALL_REGEX" 1>&2

					echo $RUN:syscalls=$FALSE_POSITIVES_SYSCALLS
				fi
			fi
		fi
	done
}

group_false_positives()
{
	RUN_REGEX="$1"
	TARGET_NAME="$2"
	TRUE_POSITIVE_SYSCALL_REGEX="$3"

	CURRENT_PROCESSING_RUN_ID=NONE

	for FALSE_POSITIVE in `process_false_positives "$RUN_REGEX" "$TARGET_NAME" "$TRUE_POSITIVE_SYSCALL_REGEX"`
	do
		CURRENT_LINE_RUN_ID=`echo $FALSE_POSITIVE | cut -d':' -f1`
		CURRENT_LINE_RUN_FALSE_POSITIVES=`echo $FALSE_POSITIVE | cut -d':' -f2`

		if [[ "$CURRENT_PROCESSING_RUN_ID" == "$CURRENT_LINE_RUN_ID" ]]
		then
			echo -n ";$CURRENT_LINE_RUN_FALSE_POSITIVES"
		else
			if [ "$CURRENT_PROCESSING_RUN_ID" != "NONE" ]
			then
				echo -en "\n"
			fi

			CURRENT_PROCESSING_RUN_ID="$CURRENT_LINE_RUN_ID"

			echo -n "$FALSE_POSITIVE"
		fi
	done

	echo -e "\n"
}

count_false_positives()
{
	FALSE_POSITIVES="$1"

	MET_AUTOMATON=0
	FALSE_POSITIVES_COUNT=0
	MET_SYSCALLS=""

	for FALSE_POSITIVE in `echo $FALSE_POSITIVES | tr ';' '\n'`
	do
		if [[ "$FALSE_POSITIVE" =~ ^syscall.* ]]
		then
			for SYSCALL in `echo $FALSE_POSITIVE | cut -d'=' -f2 | tr ',' '\n'`
			do
				if ! [[ "$MET_SYSCALLS" =~ "\"$SYSCALL\"" ]]
				then
					is_debug_on && echo SYSCALL $SYSCALL

					MET_SYSCALLS="$MET_SYSCALLS,\"$SYSCALL\""
					FALSE_POSITIVES_COUNT=$((FALSE_POSITIVES_COUNT + 1))
				else
					is_debug_on && echo ALREADY MET $SYSCALL
				fi
			done
		else
			if [ $MET_AUTOMATON -eq 0 ]
			then
				is_debug_on && echo AUTOMATON

				MET_AUTOMATON=1
				FALSE_POSITIVES_COUNT=$((FALSE_POSITIVES_COUNT + 1))
			else
				is_debug_on && echo ALREADY MET AUTOMATON
			fi
		fi
	done

	echo $FALSE_POSITIVES_COUNT
}

count_false_positives_per_runs()
{
	RUN_REGEX="$1"
	TARGET_NAME="$2"
	TRUE_POSITIVE_SYSCALL_REGEX="$3"

	for RUN_WITH_FALSE_POSITIVES in `group_false_positives "$RUN_REGEX" "$TARGET_NAME" "$TRUE_POSITIVE_SYSCALL_REGEX"`
	do
		RUN_ID=`echo $RUN_WITH_FALSE_POSITIVES | cut -d':' -f1`
		RUN_FALSE_POSITIVES=`echo $RUN_WITH_FALSE_POSITIVES | cut -d':' -f2`

		RUN_UNIQUES_FALSE_POSITIVES_COUNT=`count_false_positives $RUN_FALSE_POSITIVES`

		echo "$RUN_ID:$RUN_UNIQUES_FALSE_POSITIVES_COUNT"
	done
}
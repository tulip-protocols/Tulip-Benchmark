#!/bin/bash

source ../../../config.sh
source ../../../functions.sh
source ../../../../config-benchmark.sh

QMAIL_VARIANT=3_forgotten_check

is_true_positive()
{
	FIC="$1"

	egrep -ia "list|dele|retr|stat|rset" $FIC > /dev/null 2>&1

	if [ $? -eq 0 ]
	then
		return 0
	else
		return 1
	fi
}

get_true_positives()
{
	for DIR in `ls -d ${RESULTS_PATH}/cbd/qmail/${QMAIL_VARIANT}/output* | grep -v .tar.gz`
	do
		FINISH=0

		for FIC in `find ${DIR}/cbd_trivials/potential_backdoors -type f`
		do
			if is_true_positive $FIC
			then
				echo $FIC
				FINISH=1

				break
			fi
		done

		if [ $FINISH -eq 0 ]
		then
			I=0

			while [ $I -lt $NUMBER_OF_ITERATIONS ] && [ $FINISH == 0 ]
			do
				for FIC in `find ${DIR}/cbd_output_iteration_$I/potential_backdoors -type f`
				do
					if is_true_positive $FIC
					then
						echo $FIC
						FINISH=1

						break
					fi
				done

				I=$((I + 1))
			done
		fi
	done
}

export PATH_OFFSET=6

for CBD_INSTANCE_WITH_TIME in `cbd_instances_with_times "output_qmail-${QMAIL_VARIANT}_[0-9]*" "qmail/$QMAIL_VARIANT"`
do
	CBD_INSTANCE=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f1`
	TIME=`echo $CBD_INSTANCE_WITH_TIME | cut -d':' -f2`

	echo "$CBD_INSTANCE:`echo $TIME | tr ',' '\n' | sort -n | tr '\n' ',' | sed -re 's/,$//g'`"
done

echo

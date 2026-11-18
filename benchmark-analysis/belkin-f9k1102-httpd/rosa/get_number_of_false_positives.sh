#!/bin/bash

source ../../config.sh

get_fics_that_contains_the_backdoor()
{
	pushd ${RESULTS_PATH}/rosa/belkin-f9k1102-httpd/ 2>&1 > /dev/null

	for ROSA_INSTANCE in `ls -d rosa-out*`
	do
		DEV_CGI_C=`grep -Rial "dev.cgi" $ROSA_INSTANCE/backdoors`
		
		for FIC in $DEV_CGI_C
		do
			echo "+$FIC"
		done

		NOT_DEV_CGI_C=`grep -Rialv "dev.cgi" $ROSA_INSTANCE/backdoors`

		for FIC in $NOT_DEV_CGI_C
		do
			echo "-$FIC"
		done
	done

	popd 2>&1 > /dev/null
}

get_false_positives()
{
	COUNT=0
	PREVIOUS_CLUSTER=""
	
	for CLUSTER in `get_fics_that_contains_the_backdoor | cut -d'/' -f1-3 | sort | uniq | grep -v README.txt`
	do
		CURRENT_CLUSTER_PATH=`echo $CLUSTER | colrm 1 1`
	
		if [ "x$PREVIOUS_CLUSTER" != "x+$CURRENT_CLUSTER_PATH" ]
		then
			if [ "x$CLUSTER" == "x-$CURRENT_CLUSTER_PATH" ]
			then
				echo $CURRENT_CLUSTER_PATH
			fi
		fi
	
		PREVIOUS_CLUSTER="$CLUSTER"
	done
}

get_false_positives | cut -d'/' -f1 | sort | uniq -c

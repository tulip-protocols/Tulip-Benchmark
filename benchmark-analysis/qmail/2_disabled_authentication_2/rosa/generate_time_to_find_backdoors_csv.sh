#!/bin/bash

cd `dirname $0`

echo "rosa_instance,time_to_find_the_backdoor";./get_times_to_find_the_backdoor.sh | grep -v "instances found the backdoor" | cut -d',' -f1 | tr ":" ","

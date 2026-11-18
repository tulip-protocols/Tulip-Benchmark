#!/bin/bash

cd `dirname $0`

echo "cbd_ablated_instance,time_to_find_the_backdoor"
./display_times.sh | cut -d',' -f1 | tr ":" "," | sed -re "s/s$//g"

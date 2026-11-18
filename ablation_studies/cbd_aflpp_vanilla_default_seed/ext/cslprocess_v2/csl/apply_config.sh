#!/bin/bash

get_variables()
{
    CONFIG="$1"

    cat $CONFIG | grep '^\$'
}

get_csl_parameters()
{
    CONFIG="$1"

    cat $CONFIG | grep -v '^\$' | grep -v '^$'
}

CSL="$1"
CONFIG="$2"

CSL_CONTENT=`cat $CSL`

# Variables
while read VAR_LINE
do
    VAR_LINE=`sed -re "s? *= *?=?g" <<< $VAR_LINE`

    IFS='=' read -r NAME VALUE <<< $VAR_LINE

    NAME=`sed -re 's?\\$?\\\\$?g' <<< $NAME`

    export CSL_CONTENT=`sed -re "s?$NAME?$VALUE?g" <<< $CSL_CONTENT`
done < <(get_variables $CONFIG) # To prevent subshell variables isolation when using pipe |

# CSL parameters
while read PARAMETER
do
    export CSL_CONTENT=`sed -re "1i$PARAMETER;" <<< $CSL_CONTENT`
done < <(get_csl_parameters $CONFIG)

cat <<< $CSL_CONTENT
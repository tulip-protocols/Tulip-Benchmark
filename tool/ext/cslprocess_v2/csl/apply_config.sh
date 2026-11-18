#!/bin/bash

get_variables()
{
    CONFIG="$1"

    cat $CONFIG | grep '^\$'
}

get_csl_parameters()
{
    CONFIG="$1"

    cat $CONFIG | grep -v '^\$' | grep -v '^$' | grep -v "more_commands" | grep -v "^    "
}

manage_more_commands()
{
    CSL_FILE_CONTENT="$1"
    CONFIG="$2"

    MORE_COMMANDS_COUNT=`cat $CONFIG | grep "^more_commands" | wc -l`

    for I in `seq 0 $((MORE_COMMANDS_COUNT - 1))`
    do
        CURRENT_MORE_COMMANDS_LINE=`grep "^more_commands" $CONFIG | sed -n "$((I + 1))p"`
        CURRENT_MORE_COMMANDS_TARGET=`echo $CURRENT_MORE_COMMANDS_LINE | cut -d'(' -f2 | cut -d')' -f1`
        CURRENT_MORE_COMMANDS_LINE_NUMBER=`grep -n "$CURRENT_MORE_COMMANDS_LINE" $CONFIG | cut -d':' -f1`

        CSL_FILE_AUTHENTICATION_LEVEL_DECLARATION_LINE_NUMBER=`grep -n "level $CURRENT_MORE_COMMANDS_TARGET:" <<< $CSL_FILE_CONTENT | cut -d':' -f1` # Example : "level authenticated:"

        J=$((CURRENT_MORE_COMMANDS_LINE_NUMBER + 1))
        CONFIG_CONTENT_AT_J=`sed -n "${J}p" $CONFIG`

        while [ "$CONFIG_CONTENT_AT_J" != "" ]
        do
            CSL_FILE_CONTENT=`sed "${CSL_FILE_AUTHENTICATION_LEVEL_DECLARATION_LINE_NUMBER}a$CONFIG_CONTENT_AT_J," <<< $CSL_FILE_CONTENT`

            J=$((J + 1))
            CONFIG_CONTENT_AT_J=`sed -n "${J}p" $CONFIG`
        done
    done

    cat <<< $CSL_FILE_CONTENT
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

manage_more_commands "$CSL_CONTENT" $CONFIG

#cat <<< $CSL_CONTENT
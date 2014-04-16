#!/bin/sh

# ncid-yac
# usage: ncid --no-gui --program ncid-yac

# Last modified: Sun Apr 13 2014

# NCID to YAC Clients
# Requires a YAC Client

# input is always 7 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMISC\n
#
# if input is from a message
# the message is in place of NAME:
# input: DATE\nTIME\nNUMBER\nMESG\nLINE\nTYPE\nNAME\n

# defaults (see ncid-yac.conf for descriptions)
YACPORT=10629
YACLIST=127.0.0.1
YACTYPES="CID OUT MSG PID NOT"

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-yac.conf

[ -f $ConfigFile ] && . $ConfigFile

read DATE
read TIME
read NMBR
read VAR1
read LINE
read TYPE
read VAR2

# Look for $TYPE
for i in $YACTYPES
do
    [ $i = "$TYPE" ] && { found=1; break; }
done

# Exit if $TYPE not found
[ -z "$found" ] && exit 0

for YACCLIENT in ${YACLIST}
do
    if [ "$TYPE" = "MSG"-o "$TYPE" = "NOT" ]
    then
        NAME="$VAR2"
        MESG="$VAR1"
        # Display Message or Notice
        echo -n "$MESG" | nc -w1 $YACCLIENT $YACPORT
    else
        NAME="$VAR1"
        # Display Caller ID information
        echo -n "@CALL${NAME}~${NMBR}" | nc -w1 $YACCLIENT $YACPORT
    fi
done

exit 0

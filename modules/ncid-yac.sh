#!/bin/sh

# ncid-yac
# usage: ncid --no-gui --program ncid-yac

# Last Modified: Fri Aug 22, 2014

# NCID to YAC Clients
# Requires a YAC Client

# input is always 8 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n""\n""\n
#
# if input is from a message
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMESG\nMTYPE\n

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
read NAME
read LINE
read TYPE
read MESG
read MTYPE

# Look for $TYPE
for i in $YACTYPES
do
    [ $i = "$TYPE" ] && { found=1; break; }
done

# Exit if $TYPE not found
[ -z "$found" ] && exit 0

for YACCLIENT in ${YACLIST}
do
    if [ "$TYPE" = "MSG" -o "$TYPE" = "NOT" ]
    then
        # Display Message or Notice
        echo -n "$MESG" | nc -w1 $YACCLIENT $YACPORT
    else
        # Display Caller ID information
        echo -n "@CALL${NAME}~${NMBR}" | nc -w1 $YACCLIENT $YACPORT
    fi
done

exit 0

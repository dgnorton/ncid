#!/bin/sh

# ncid-yac
# usage: ncid --no-gui --program ncid-yac

# Last modified: Wed May 29, 2013

# NCID to YAC Clients
# Requires a YAC Client

# input is always 6 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# if input is from a message
# the message is in place of NAME:
# input: \n\n\n<MESSAGE>\n\nMSG\n

YACPORT=10629
YACLIST=127.0.0.1
YACTYPES="CID OUT HUP BLK MSG PID NOT"

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-yac.conf

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

# Look for $CIDTYPE
for i in $YACTYPES
do
    [ $i = "$CIDTYPE" ] && { found=1; break; }
done

# Exit if $CIDTYPE not found
[ -z "$found" ] && exit 0

for YACCLIENT in ${YACLIST}
do
    if [ "$CIDTYPE" = "MSG"-o "$CIDTYPE" = "NOT" ]
    then
        # Display Message or Notice
        echo -n "$CIDNAME" | nc -w1 $YACCLIENT $YACPORT
    else
        # Display Caller ID information
        echo -n "@CALL${CIDNAME}~${CIDNMBR}" | nc -w1 $YACCLIENT $YACPORT
    fi
done

exit 0

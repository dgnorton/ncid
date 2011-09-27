#!/bin/sh

# NCID to YAC Clients
# Requires YAC

# Last changed by jlc: Sun Sep 11, 2011

# input is 6 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# input is 6 lines if a message was sent
# input: \n\n\n<MESSAGE>\n\nMSG\n
#
# ncid usage:
#   ncid --no-gui [--message] --program ncid-yac

# $CIDTYPE is one of:
#   CID: incoming call
#   OUT: outgoing call
#   HUP: blacklisted hangup
#   MSG: message instead of a call

YACPORT=10629
YACLIST=127.0.0.1

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

# Ignore outgoing calls and hangups for now
[ "$CIDTYPE" = "OUT" ] && exit 0
[ "$CIDTYPE" = "HUP" ] && exit 0

for YACCLIENT in ${YACLIST}
do
    if [ -n "$CIDNMBR" ]
    then
        # Display Caller ID information
        echo -n "@CALL${CIDNAME}~${CIDNMBR}" | nc -w1 $YACCLIENT $YACPORT
    else
        # Display Message
        echo -n "$CIDNAME" | nc -w1 $YACCLIENT $YACPORT
    fi
done

exit 0

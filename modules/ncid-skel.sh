#!/bin/sh

# Skeleton Output Module
# Modify as needed for new module
# keep "ncid-" in the name

# Last changed by jlc: Sun Sep 11, 2011

# input is 6 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# input is 6 lines if a message was sent
# input: \n\n\n<MESSAGE>\n\nMSG\n
# Message will be in $CIDNAME
#
# ncid usage:
#   ncid --no-gui [--message] --program ncid-skel

# $CIDTYPE is one of:
#   CID: incoming call
#   OUT: outgoing call
#   HUP: blacklisted hangup
#   MSG: message instead of a call

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

if [ -n "$CIDNMBR" ]
then
    # Display Caller ID information on /dev/tty
    echo "$CIDDATE|$CIDTIME|$CIDNMBR|$CIDNAME|$CIDLINE|$CIDTYPE" > /dev/tty
else
    # Display Message on /dev/tty
    echo "$CIDNAME" > /dev/tty
fi

exit 0

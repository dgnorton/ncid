#!/bin/sh

# ncid-skel
# usage: ncid --no-gui --program ncid-skel

# Last modified: Fri Oct 12, 2012

# Skeleton Output Module
# Modify as needed for new module
# keep "ncid-" in the name

# Module should should provide a default for all cariables.
# User changable variables are in /usr/local/etc/ncid/conf.d/ncid-skel.conf

# input is always 6 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# if input is from a message
# the message is in place of NAME:
# input: \n\n\n<MESSAGE>\n\nMSG\n

# $CIDTYPE is one of:
#   CID: incoming call
#   OUT: outgoing call
#   HUP: blacklisted hangup
#   MSG: message instead of a call

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-skel.conf

skel_types="CID OUT HUP MSG"

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

# Look for $CIDTYPE
for i in $skel_types
do
    [ $i = "$CIDTYPE" ] && { found=1; break; }
done

# Exit if $CIDTYPE not found
[ -z "$found" ] && exit 0

if [ "$CIDTYPE" = "MSG" ]
then
    # Display Message on /dev/tty
    echo "$CIDNAME" > /dev/tty
else
    # Display Caller ID information on /dev/tty
    echo "$CIDDATE|$CIDTIME|$CIDNMBR|$CIDNAME|$CIDLINE|$CIDTYPE" > /dev/tty
fi

exit 0

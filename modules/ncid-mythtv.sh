#!/bin/sh

# ncid-mythtv
# usage: ncid --no-gui --program ncid-mythtv

# Last modified: Fri Oct 12, 2012

# MythTV Display
# See http://www.mythtv.org/wiki/index.php/Little_Gems
# Requires MythTV (mythtvosd)

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

mythtv_types="CID OUT HUP MSG"

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-mythtv.conf

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

# Look for $CIDTYPE
for i in $mythtv_types
do
    [ $i = "$CIDTYPE" ] && { found=1; break; }
done

# Exit if $CIDTYPE not found
[ -z "$found" ] && exit 0

if [ "$CIDTYPE" = "MSG" ]
then
    # Display Message
    mythtvosd --template="alert" --alert_text="$CIDNAME"
else
    # Display Caller ID information
    mythtvosd --template="cid" \
              --caller_name="$CIDNAME" \
              --caller_number="$CIDNMBR" \
              --caller_date="$CIDDATE" \
              --caller_time="$CIDTIME"
fi

exit 0

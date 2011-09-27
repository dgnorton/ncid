#!/bin/sh

# MythTV Display
# See http://www.mythtv.org/wiki/index.php/Little_Gems
# Requires MythTV (mythtvosd)

# Last changed by jlc: Sun Sep 11, 2011

# input is 6 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# input is 6 lines if a message was sent
# input: \n\n\n<MESSAGE>\n\nMSG\n
#
# ncid usage:
#   ncid --no-gui [--message] --program ncid-mythtv

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

# Ignore outgoing calls and hangups for now
[ "$CIDTYPE" = "OUT" ] && exit 0
[ "$CIDTYPE" = "HUP" ] && exit 0

if [ -n "$CIDNMBR" ]
then
    # Display Caller ID information
    mythtvosd --template="cid" \
              --caller_name="$CIDNAME" \
              --caller_number="$CIDNMBR" \
              --caller_date="$CIDDATE" \
              --caller_time="$CIDTIME"
else
    # Display Message
    mythtvosd --template="alert" --alert_text="$CIDNAME"
fi

exit 0

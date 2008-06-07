#!/bin/sh

# MythTV Display
# See http://www.mythtv.org/wiki/index.php/Little_Gems
# Requires MythTV (mythtvosd)

# Last changed by jlc: Sun May 4, 2008

# input is 5 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\n
#
# input is 5 lines if a message was sent
# input: \n\n\nMESSAGE\n\n
#
# ncid calls a external program with the "--call-prog" option
# default program: /usr/share/ncid/ncid-speak
#
# ncid usage:
#   ncid --no-gui --message --call-prog --program ncid-mythtv

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE

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

#!/bin/sh

# ncid-mythtv
# usage: ncid --no-gui --program ncid-mythtv

# Last modified: Sun Apr 13, 2014

# MythTV Display
# See http://www.mythtv.org/wiki/index.php/Little_Gems
# Requires MythTV (mythtvosd)

# input is always 7 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMISC\n
#
# if input is from a message
# the message is in place of NAME:
# input:  DATE\nTIME\nNUMBER\nMESG\nLINE\nTYPE\nNAME\n

# defaults (see ncid-mythtv.conf for description):
mythtv_types="CID OUT HUP BLK PID MSG NOT"
mythtv_bcastaddr=127.0.0.1
mythtv_timeout=10

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-mythtv.conf

[ -f $ConfigFile ] && . $ConfigFile

read DATE
read TIME
read NMBR
read VAR1
read LINE
read TYPE
read VAR2

# Look for $TYPE
for i in $mythtv_types
do
    [ $i = "$TYPE" ] && { found=1; break; }
done

# Exit if $TYPE not found
[ -z "$found" ] && exit 0

if [ "$TYPE" = "MSG" -o "$TYPE" = "NOT" ]
then
    NAME="$VAR2"
    MESG="$VAR1"
    # Display Message or Notice
    mythutil --notification \
             --origin "NCID"
             --message_text "$MESG" \
             --timeout $mythtv_timeout \
             --bcastaddr $mythtv_bcastaddr
else
    NAME="$VAR1"
    # Display Caller ID information
    mythutil --notification \
             --origin "NCID"
             --message_text "$NMBR $NAME" \
             --timeout $mythtv_timeout \
             --bcastaddr $mythtv_bcastaddr
fi

exit 0

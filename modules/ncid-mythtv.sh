#!/bin/sh

# ncid-mythtv
# usage: ncid --no-gui --program ncid-mythtv

# Last Modified: Fri Aug 22, 2014

# MythTV Display
# See http://www.mythtv.org/wiki/index.php/Little_Gems
# Requires MythTV (mythtvosd)

# input is always 8 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n""\n""\n
#
# if input is from a message
# input:  DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMESG\nMTYPE\n

# defaults (see ncid-mythtv.conf for description):
mythtv_types="CID OUT HUP BLK PID MSG NOT"
mythtv_bcastaddr[0]=127.0.0.1
mythtv_timeout=10

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-mythtv.conf

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
for i in $mythtv_types
do
    [ $i = "$TYPE" ] && { found=1; break; }
done

# Exit if $TYPE not found
[ -z "$found" ] && exit 0

if [ "$TYPE" = "MSG" -o "$TYPE" = "NOT" ]
then
    # Message or Notice
    MSGTXT="$MESG"
else
    # Caller ID information
    MSGTXT="$NMBR $NAME"
fi

for client in "${mythtv_bcastaddr[@]}"
do
    mythutil --notification \
             --origin "NCID"
             --message_text "$MSGTXT" \
             --timeout $mythtv_timeout \
             --bcastaddr $client
done

exit 0

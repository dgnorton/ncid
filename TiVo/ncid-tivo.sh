#!/bin/sh

# Output Module: ncid-tivo
# Usage: ncid --no-gui --program ncid-tivo
# Usage: tivoncid

# Last modified: Sun Apr 14, 2013

# TiVo Display
# Requires a TiVo

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

# TiVo display options using /tvbin/text2osd
# --line     <line number>
# --message  <string>
# --xscale   <number>
# --yscale   <number>
# --bgscolor [<num num num, r-g-b values>][<string,red|green|blue|white|black>]
# --fgscolor [<num num num, r-g-b values>][<string,red|green|blue|white|black>]
# --clear

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-tivo.conf

TivoOSD=/tvbin/text2osd
TivoOpt="--line 1 --xscale 2 --yscale 2"
TivoDelay=10
TivoCS=--clear
TivoTypes="CID OUT HUP MSG"

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

# Look for $CIDTYPE
for i in $TivoTypes
do
    [ $i = "$CIDTYPE" ] && { found=1; break; }
done

# Exit if $CIDTYPE not found
[ -z "$found" ] && exit 0

if [ "$CIDTYPE" = "MSG" ]
then
    # Display Message
    echo -e "$CIDNAME\n" | $TivoOSD $TivoOpt
else
    # Display Caller ID information
    if [ -z "$CIDLINE" ]
    then
        # no line indicator
        echo -e "$CIDNAME\n$CIDNMBR\n" | $TivoOSD $TivoOpt
    else
        echo -e "$CIDNAME $CIDNMBR\n$CIDTYPE $CIDLINE\n" | $TivoOSD $TivoOpt
    fi
fi

sleep $TivoDelay
echo | $TivoOSD $TivoCS

exit 0

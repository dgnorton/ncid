#!/bin/sh

# TiVo Display
# Requires a TiVo

# Last changed by jlc: Sun Sep 11, 2011

# input is 6 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# input is 6 lines if a message was sent
# input: \n\n\n<MESSAGE>\n\nMSG\n
#
# ncid usage:
#   ncid --no-gui [--message] --program ncid-tivo

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

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf

TivoOSD=/tvbin/text2osd
TivoOpt="--line 1 --xscale 2 --yscale 2"
TivoDelay=10
TivoCS=--clear

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
    if [ -z "$CIDLINE" ]
    then
        # no line indicator
        echo -e "$CIDNAME $CIDNMBR\n" | $TivoOSD $TivoOpt
    else
        echo -e "$CIDNAME $CIDNMBR\n$CIDLINE\n" | $TivoOSD $TivoOpt
    fi
else
    # Display Message
    echo -e "$CIDNAME\n" | $TivoOSD $TivoOpt
fi

sleep $TivoDelay
$TivoOSD $TivoCS

exit 0

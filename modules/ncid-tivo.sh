#!/bin/sh

# TiVo Display
# Requires a TiVo

# Last changed by jlc: Sun Aug 29, 2010

# input is 5 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\n
#
# input is 5 lines if a message was sent
# input: \n\n\nMESSAGE\n\n
#
# ncid usage:
#   ncid --no-gui [--message] --program ncid-tivo

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf

# TiVo display options using /tvbin/text2osd
# --line     <line number>
# --message  <string>
# --xscale   <number>
# --yscale   <number>
# --bgscolor [<num num num, r-g-b values>][<string,red|green|blue|white|black>]
# --fgscolor [<num num num, r-g-b values>][<string,red|green|blue|white|black>]
# --clear

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

#!/bin/sh

# TiVo Display
# Requires a TiVo

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
#   ncid --no-gui --message --call-prog --program ncid-tivo

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidscript.conf

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

if [ -z "$CIDLINE" ]
then
    # no line indicator
    echo -e "$CIDNAME $CIDNMBR\n" | $TivoOSD $TivoOpt
else
    echo -e "$CIDNAME $CIDNMBR\n$CIDLINE\n" | $TivoOSD $TivoOpt
fi

sleep $TivoDelay
$TivoOSD $TivoCS

exit 0

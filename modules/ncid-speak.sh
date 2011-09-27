#!/bin/sh

# Announce the Caller ID
# Requires festival

# Last changed by jlc: Sun Sep 11, 2011

# most of this program is taken from nciduser by Mace Moneta
# requires festival: http://www.cstr.ed.ac.uk/projects/festival

# input is 6 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# input is 6 lines if a message was sent
# input: \n\n\n<MESSAGE>\n\nMSG\n
#
# ncid usage:
#   ncid --no-gui [--message] --program ncid-speak

# $CIDTYPE is one of:
#   CID: incoming call
#   OUT: outgoing call
#   HUP: blacklisted hangup
#   MSG: message instead of a call

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

### defaults if not using config file ###
# What to say
WHAT=$CIDNAME
#WHAT=$CIDNMBR
SAY="$CIDTYPE $WHAT"
#SAY="$WHAT"
# If festival is being used:
T2S='`echo $SAY | festival --tts`'
# If using a Macintosh without festival:
#T2S='/usr/bin/osascript -e \"say $SAY\"'
# Number of times to speak
SAYNUM=1
# delay between speaking
SpeakDelay=2

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf

[ -f $ConfigFile ] && . $ConfigFile

while [ ${SAYNUM:=1} != 0 ]
do
    eval $T2S
    SAYNUM=`expr $SAYNUM - 1`
    [ $SAYNUM = 0 ] || /bin/sleep ${SpeakDelay:=1}
done

exit 0

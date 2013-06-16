#!/bin/bash

# ncid-speak
# usage: ncid --no-gui --program ncid-speak

# Last modified: Wed May 29, 2013

# Announce the Caller ID
# Requires festival

# most of this program is taken from nciduser by Mace Moneta
# requires festival: http://www.cstr.ed.ac.uk/projects/festival

# input is always 6 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# if input is from a message
# the message is in place of NAME:
# input: \n\n\n<MESSAGE>\n\nMSG\n

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-speak.conf

### defaults if not using config file ###
SpeakThis='$CIDNAME'
SpeakInput="echo $SpeakThis | festival --tts"
SpeakTimes=1
SpeakDelay=2
SpeakTypes="CID MSG PID NOT"
AreaCodeLength=3

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

# Look for $SpeakType
for i in $SpeakTypes
do
    [ $i = "$CIDTYPE" ] && { found=1; break; }
done

# Exit if $CIDTYPE not found
[ -z "$found" ] && exit 0

if [ "$CIDTYPE" = "CID" ] && [ "$CIDNAME" = "NO NAME" ] && [ $AreaCodeLength -ne 0 ]
then
    CIDNMBR=`echo $CIDNMBR |sed 's/[^0-9]//g; s/^1//'`
    length=$((${#CIDNMBR}-AreaCodeLength))
    if [ $length -le 0 ]
    then
        if [ ${#CIDNMBR} -gt 1 ]
        then
            CIDNAME=`echo $CIDNMBR |sed 's/./ &/g'`
        fi
    else
        CIDNAME="Area Code"`echo $CIDNMBR | eval "sed -e 's/.\{$length\}\$//; s/./ &/g'"`
    fi
fi
echo "Name: $CIDNAME" > /tmp/ncid_debug

if [ "$CIDTYPE" = "MSG" -o "$CIDTYPE" = "NOT" ]
then
    SpeakThis=$CIDNAME
else
    eval : $SpeakThis
fi

while [ ${SpeakTimes:=1} != 0 ]
do
    eval $SpeakInput
    SpeakTimes=`expr $SpeakTimes - 1`
    [ $SpeakTimes = 0 ] || /bin/sleep ${SpeakDelay:=1}
done

exit 0

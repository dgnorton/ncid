#!/bin/bash

# ncid-speak
# usage: ncid --no-gui --program ncid-speak

# Last Modified: Fri Aug 22, 2014

# Announce the Caller ID
# Requires festival

# most of this program is taken from nciduser by Mace Moneta
# requires festival: http://www.cstr.ed.ac.uk/projects/festival

# input is always 8 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n""\n""\n
#
# if input is from a message
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMESG\nMTYPE\n

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-speak.conf

### defaults if not using config file ###
SpeakThis='$NAME'
SpeakInput="echo $SpeakThis | festival --tts"
SpeakTimes=1
SpeakDelay=2
SpeakTypes="CID PID"
AreaCodeLength=3

found=

[ -f $ConfigFile ] && . $ConfigFile

read DATE
read TIME
read NMBR
read NAME
read LINE
read TYPE
read MESG
read MTYPE

# Look for $SpeakType
for i in $SpeakTypes
do
    [ $i = "$TYPE" ] && { found=1; break; }
done

# Exit if $TYPE not found
[ -z "$found" ] && exit 0

if [ "$TYPE" = "MSG" -o "$TYPE" = "NOT" ]
then
    SpeakThis='$MESG'
else
    if [ "$NAME" = "NO NAME" ] && [ $AreaCodeLength -ne 0 ]
    then
        NMBR=`echo $NMBR |sed 's/[^0-9]//g; s/^1//'`
        length=$((${#NMBR}-AreaCodeLength))
        if [ $length -le 0 ]
        then
            if [ ${#NMBR} -gt 1 ]
            then
                NAME=`echo $NMBR |sed 's/./ &/g'`
            fi
        else
            NAME="Area Code"`echo $NMBR | eval "sed -e 's/.\{$length\}\$//; s/./ &/g'"`
        fi
    fi
fi
eval : $SpeakThis

while [ ${SpeakTimes:=1} != 0 ]
do
    eval $SpeakInput
    SpeakTimes=`expr $SpeakTimes - 1`
    [ $SpeakTimes = 0 ] || /bin/sleep ${SpeakDelay:=1}
done

exit 0

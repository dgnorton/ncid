#!/bin/sh

# Display a popup caption and speak the caller id
# Requires kdialog (for popup) and festival (to speak)
# Also uses code from ncid-speak
#
# Created by Randy L. Rasmussen
# Created on Thu Dec 20, 2007
# Last modified: Sun Sep 11, 2011 by jlc

# input is 6 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# input is 6 lines if a message was sent
# input: \n\n\n<MESSAGE>\n\nMSG\n
#
# ncid usage:
#   ncid --no-gui [--message] --program ncid-kpopup

# $CIDTYPE is one of:
#   CID: incoming call
#   OUT: outgoing call
#   HUP: blacklisted hangup
#   MSG: message instead of a call

# The following variables get set from $ConfigDir/$ConfigFile
# These are the default values if there is no $ConfigDir/$ConfigFile
# festival=/usr/bin/festival
kdialog=/usr/bin/kdialog
geo="0x0+1600+1000" #Display in the bottom right corner of a 22" monitor
title="Incoming Call" #Title of popup used by kdialog
timeout=10 #Displays popup for X number of seconds used by kdialog

# Note these read commands have to be above the '... . $ConfigFile' line
# since SAY="...$CIDNAME"

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

# $cidtype is a CIDXXXX variable, normally $CIDNAME or $CIDNMBR
# $cidcaller is usually an alias or a name or "".
# if $cidcaller="", speaking caller names is disabled (the default)
# if $cidtype and $cidcaller are the same, speaking all caller names
#    is enabled, i.e. cidtype="$CIDNAME" and cidcaller="$CIDNAME"
# if $cidcaller is an alias or name, speaking a selected caller name
#    is enabled, i.e. cidcaller="Randy on cell"
#cidtype="$CIDNAME"
#cidcaller=""

ConfigDir=/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf

[ -f $ConfigFile ] && . $ConfigFile

$kdialog --geometry $geo --title "$title" --passivepopup \
         "$CIDTYPE $CIDNAME $CIDNMBR" $timeout &

# this speaks $CIDNAME if there is a match
if [ "$cidtype" = "$cidcaller" ] && [ "$cidtype" != "" ]
then
    # Added the following to unmute Line in for kmix if muted
    muted=$(dcop kmix Mixer0 mute 2)
    if [ "$muted" = "true" ] #If volume is muted
    then
      dcop kmix Mixer0 toggleMute 2
    fi
    # Note you cannot simply run ncid-speak here since the read CIDXXXX
    # commands would overwrite the passed values from the ncid server
    # Use the following to run festival to speak the caller-id
    # (code taken form ncid-speak)
    while [ ${SAYNUM:=1} != 0 ]
    do
        eval $T2S
        SAYNUM=`expr $SAYNUM - 1`
        [ $SAYNUM = 0 ] || /bin/sleep ${SpeakDelay:=1}
    done
fi

exit 0

#!/bin/sh

# ncid-kpopup
# usage: ncid --no-gui --program ncid-kpopup

# Created by Randy L. Rasmussen on Thu Dec 20, 2007

# Last Modified: Fri Aug 22, 2014

# Display a popup caption and speak the caller id
# Requires kdialog (for popup) and festival (to speak)

# input is always 8 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n""\n""\n
#
# if input is from a message
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMESG\nMTYPE\n

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-kpopup.conf

# Test whether echo needs option "-e" to interpret new line "\n"
if [ "`echo -e`" != " -e" ] ; then use_e="-e " ; else use_e= ; fi

# Defaults (see ncid-kpopup.conf for description):
kdialog=/usr/bin/kdialog
kpopup_geo="0x0+1600+1000" #Display in the bottom right corner of a 22" monitor
kpopup_timeout=10 #Displays popup for X number of seconds used by kdialog
kpopup_types="CID OUT HUP MSG"
kpopup_speak=""

[ -f $ConfigFile ] && . $ConfigFile

ncid_speak=/usr/local/share/ncid/ncid-speak

read DATE
read TIME
read NMBR
read NAME
read LINE
read TYPE
read MESG
read MTYPE

# Look for $TYPE
for i in $kpopup_types
do
    [ $i = "$TYPE" ] && \
    {
        case $TYPE in
            CID) title="Incoming Call:";;
            OUT) title="Outgoing Call:";;
            HUP) title="Blacklisted Call Hangup:";;
            BLK) title="Blacklisted Call Blocked:";;
            MSG) title="Message:";;
            PID) title="Caller ID from a smart phone:";;
            NOT) title="Notice of a smart phone message:";;
              *) title="Unknown Call Type: ($TYPE)";;
        esac
        found=1
        break
    }
done

# Exit if $TYPE not found
[ -z "$found" ] && exit 0

if [ "$TYPE" = "MSG" -o "$TYPE" = "NOT" ]
then
    $kdialog --geometry $kpopup_geo --title "$title" --passivepopup \
         "$MESG" $kpopup_timeout &
else
    $kdialog --geometry $kpopup_geo --title "$title" --passivepopup \
         "$TYPE $NAME $NMBR" $kpopup_timeout &

    # this speaks if there is a match
    if [ "$kpopup_speak" = "enable" ]
    then
        # Added the following to unmute Line in for kmix if muted
        muted=$(dcop kmix Mixer0 mute 2)
        if [ "$muted" = "true" ] #If volume is muted
        then
        dcop kmix Mixer0 toggleMute 2
        fi

        # call the ncid-speak module
        echo $use_e "$DATE\n$TIME\n$NMBR\n$NAME\n$LINE\n$TYPE" | $ncid_speak
    fi
fi

exit 0

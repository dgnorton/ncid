#!/bin/sh

# ncid-alert
# usage: ncid --no-gui --program ncid-alert

# Last Modified: Fri Aug 22, 2014

# Notify Output Module
# Pop-up a notification using 'send' from 'libnotify'
# Requires 'libnotify'

# input is always 8 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n""\n""\n
#
# if input is from a message
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMESG\nMTYPE\n

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-alert.conf

# Test whether echo needs option "-e" to interpret new line "\n"
if [ "`echo -e`" != " -e" ] ; then use_e="-e " ; else use_e= ; fi

# Defaults (see ncid-alert.conf for description):
alert_send=/usr/bin/notify-send
alert_types="CID OUT HUP BLK MSG PID NOT"
alert_timeout=10000 # timeout in ms
alert_urgency=low
alert_icon=call-start

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
for i in $alert_types
do
    [ $i = "$TYPE" ] && \
    {
        case $TYPE in
            CID) title="Incoming Call:    ";;
            OUT) title="Outgoing Call:    ";;
            HUP) title="Blacklisted Call Hangup:    ";;
            BLK) title="Blacklisted Call Blocked:    ";;
            MSG) title="Message:    ";;
            PID) title="Caller ID from smart phone:    ";;
            NOT) title="Notice from a smart phone:    ";;
              *) title="Unknown Call Type: ($TYPE)    ";;
        esac
        found=1
        break;
    }
done

# Exit if $TYPE not found
[ -z "$found" ] && exit 0

if [ "$TYPE" = "MSG" -o "$TYPE" = "NOT" ]
then
    # Display Message or Notice
    $alert_send -u $alert_urgency -t $alert_timeout \
        -i $alert_icon "$title" "$MESG" &
else
    # Display Caller ID information
    message=`echo $use_e "$NAME\n$NMBR\n$TIME\n$DATE\n$LINE"`
    $alert_send -u $alert_urgency -t $alert_timeout \
        -i $alert_icon "$title" "$NAME" &
fi

exit 0

#!/bin/sh

# ncid-alert
# usage: ncid --no-gui --program ncid-alert

# Last Modified: Wed May 29, 2013

# Notify Output Module
# Pop-up a notification using 'send' from 'libnotify'
# Requires 'libnotify'

# input is always 6 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# if input is from a message
# the message is in place of NAME:
# input: \n\n\n<MESSAGE>\n\nMSG\n

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

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

# Look for $CIDTYPE
for i in $alert_types
do
    [ $i = "$CIDTYPE" ] && \
    {
        case $CIDTYPE in
            CID) title="Incoming Call:    ";;
            OUT) title="Outgoing Call:    ";;
            HUP) title="Blacklisted Call Hangup:    ";;
            BLK) title="Blacklisted Call Blocked:    ";;
            MSG) title="Message:    ";;
            PID) title="Caller ID from smart phone:    ";;
            NOT) title="Notice from a smart phone:    ";;
              *) title="Unknown Call Type: ($CIDTYPE)    ";;
        esac
        found=1
        break;
    }
done

# Exit if $CIDTYPE not found
[ -z "$found" ] && exit 0

if [ "$CIDTYPE" = "MSG" -o "$CIDTYPE" = "NOT" ]
then
#   Display Message or Notice
    $alert_send -u $alert_urgency -t $alert_timeout \
        -i $alert_icon "$title" "$CIDNAME" &
else
#   Display Caller ID information
    message=`echo $use_e "$CIDNAME\n$CIDNMBR\n$CIDTIME\n$CIDDATE\n$CIDLINE"`
    $alert_send -u $alert_urgency -t $alert_timeout \
        -i $alert_icon "$title" "$CIDNAME" &
fi

exit 0

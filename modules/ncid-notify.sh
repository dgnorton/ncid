#!/bin/bash

# ncid-notify
# usage: ncid --no-gui --program ncid-notify

# Last Modified: Fri Aug 22, 2014

# sends a NCID notification to a iOS device or a Android device

# Requirement for iOS:
# The Prowl (Growl client for iOS) app from the app store
# Free registration at the Prowl website <http://www.prowlapp.com/>
# Generated API key to place in configuration file.

# Requirement for Android
# The "Notify My Android" app on your Android device.
# Free registration at the NMA website <http://notifymyandroid.appspot.com/>
# Generated API key to place in configuration file.

# Module Requires:
# Generated API key from Prowl or NMA (Notify My Android)
# bash 2.0 or higher (hopefully TiVo has at least bash 2.0)
# curl
# CA certificates

# input is always 8 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n""\n""\n
#
# if input is from a message
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMESG\nMTYPE\n

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-notify.conf

# default api key for each service
notify_apikey_prowl=
notify_apikey_nma=

# default api key file for each service
notify_apikeyfile_prowl=$ConfigDir/key-prowl-api
notify_apikeyfile_nma=$ConfigDir/key-nma-api

# default high volume key for each service (optional)
notify_hvolkey_prowl=""
notify_hvolkeyfile_prowl=$ConfigDir/key-prowl-provider
notify_hvolkey_nma=""
notify_hvolkeyfile_nma=$ConfigDir/key-nma-developer

# default protocol for each service
notify_protocol_prowl="https"
notify_protocol_nma="https"

# default priority level
notify_priority=0

# default time format
notify_clock="12"

# default call types to send notification
notify_types="CID"

# default 'application', 'event' and 'notification'
# by service

# Prowl defaults:
notify_application_prowl='ncid'
notify_event_prowl='$MESG'
notify_notification_prowl='$NAME $NMBR $LINE'

# NMA defaults: 
notify_application_nma='NCID \(${TYPE}\)'
notify_event_nma='$NAME $NMBR $LINE'
notify_notification_nma='$MESG: $DATE $TIME'

# default URL
notify_url=

[ -f $ConfigFile ] && . $ConfigFile

# place scalar service-specific variables from ncid-notify.conf into
# an indexed array to make it easier to deal with multiple services
# service is either 'prowl' or 'nma' (Notify My Android)

     notify_service[1]="prowl"

      notify_apikey[1]="$notify_apikey_prowl"
  notify_apikeyfile[1]="$notify_apikeyfile_prowl"
     notify_hvolkey[1]="$notify_hvolkey_prowl"
 notify_hvolkeyfile[1]="$notify_hvolkeyfile_prowl"
    notify_protocol[1]="$notify_protocol_prowl"
 notify_application[1]="$notify_application_prowl"   
       notify_event[1]="$notify_event_prowl"
notify_notification[1]="$notify_notification_prowl"

	  
     notify_service[2]="nma"

      notify_apikey[2]="$notify_apikey_nma"
  notify_apikeyfile[2]="$notify_apikeyfile_nma"
     notify_hvolkey[2]="$notify_hvolkey_nma"
 notify_hvolkeyfile[2]="$notify_hvolkeyfile_nma"
    notify_protocol[2]="$notify_protocol_nma"
 notify_application[2]="$notify_application_nma"   
       notify_event[2]="$notify_event_nma"
notify_notification[2]="$notify_notification_nma"

# determine settings for each service
count=0
for i in "${notify_service[@]}"
do
    count=$(($count + 1))
    case $i in
            "") continue;; # handle sparse array element
         prowl) option[$count]="-F"
                www[$count]=${notify_protocol[$count]}://prowl.weks.net/publicapi/add;;
           nma) option[$count]="-d"
                www[$count]=${notify_protocol[$count]}://notifymyandroid.appspot.com/publicapi/notify;;
             *) exit 1;;
    esac
done

# if notify_apikeyfile exists & notify_apikey blank, get api key from file
count=0
found=""
for i in "${notify_service[@]}"
do
    count=$(($count + 1))
	[ -z "$i" ] && continue # handle sparse array element
    [ -f "${notify_apikeyfile[$count]}" -a ! "${notify_apikey[$count]}" ] &&
        notify_apikey[$count]=`cat ${notify_apikeyfile[$count]}`
    # api key is required
    if [ "${notify_apikey[$count]}" ] 
	   then
	   found=1
	else
	   notify_service[$count]="" # no api key so clear this service from being used
	fi
done

# must have at least one service
[ -z "$found" ] && exit 1
	
# similarly for the optional high volume keys	
count=0
for i in "${notify_service[@]}"
do
    count=$(($count + 1))
    [ -z "$i" ] && continue # handle sparse array element
    [ -f "${notify_hvolkeyfile[$count]}" -a ! "${notify_hvolkey[$count]}" ] &&
        notify_hvolkey[$count]=`cat ${notify_hvolkeyfile[$count]}`
done
	
read DATE
read TIME
read NMBR
read NAME
read LINE
read TYPE
read MESG
read MTYPE

# Only send notification if current call type is known
found=""
for i in $notify_types
do
    [ $i = "$TYPE" ] && \
    {
        case $i in
            CID) DESC="Incoming Call";;
            OUT) DESC="Outgoing Call";;
            HUP) DESC="Blacklisted Call Hangup";;
            BLK) DESC="Blacklisted Call Blocked";;
            MSG) DESC="Message";
		         DATE=`date '+%m/%d/%Y'`;
		         TIME=`date '+%H:%M'`;;
              *) DESC='New Call Type: \(${TYPE}\)';;
        esac
        found=1
        break
    }
done

# exit if call type is unknown
[ -z "$found" ] && exit 1

if [ "$TYPE" = "MSG" -o "$TYPE" = "NOT" ]
then
    notify_event[2]='$MESG'
    notify_notification[1]='$MESG'
fi

# determine if url should be used
[ "$notify_url" -a "$TYPE" = "CID" ] && \
{
    # no safeguard for number being word(s)
    # set clickable url to the url + raw number
    rawnum=${NMBR//-/}
    clickable_url=$notify_url$rawnum
}

[ "$TIME" -a "$notify_clock" = "12" ] && \
{
    # convert time from 24 hour format to 12 hour format
    hour=${TIME/:*/}
    minute=${TIME/*:/}
    [ -z "$hour" ] && { hour=12 ampm=PM; }
    [ $hour -gt 11 ] && { hour=$(($hour - 12)); ampm=PM; } || ampm=AM
    notify_time="$hour:$minute $ampm"
} || notify_time=$TIME

# reset TIME to $notify_time so the 'eval' below will use the newly
# reformatted 12 hour time
TIME=$notify_time

# send notification
count=0
for i in "${notify_service[@]}"
do
    count=$(($count + 1))
	[ -z "$i" ] && continue # handle sparse array element

	 notify_application[$count]=`eval echo ${notify_application[$count]}`
	       notify_event[$count]=`eval echo ${notify_event[$count]}`
	notify_notification[$count]=`eval echo ${notify_notification[$count]}`
	
	# providerkey  used by Prowl
	# developerkey used by NMA
	
    curl \
        ${option[$count]} apikey="${notify_apikey[$count]}" \
        ${option[$count]} application="${notify_application[$count]}" \
        ${option[$count]} event="${notify_event[$count]}" \
        ${option[$count]} description="${notify_notification[$count]}" \
		${option[$count]} priority="$notify_priority" \
    	${option[$count]} providerkey="${notify_hvolkey[$count]}" \
        ${option[$count]} developerkey="${notify_hvolkey[$count]}" \
        ${option[$count]} url="$clickable_url" \
        ${www[$count]}
done

exit 0

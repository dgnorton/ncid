#!/bin/sh

# Page a cell phone, pager, or mail address
# Requires mail

# Last changed by jlc: Sun Sep 11, 2011

# input is always 6 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# if input is from a message
# the  message is in place of NAME:
# input: \n\n\n<MESSAGE>\n\nMSG\n
#
# ncid usage:
#   ncid --no-gui [--ring 4] [--message] --program ncid-page

# $CIDTYPE is one of:
#   CID: incoming call
#   OUT: outgoing call
#   HUP: blacklisted hangup
#   MSG: message instead of a call

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf

# set ADDRESS to a pager or cell phone email address
PageTo=

# default mail user is user running script
PageFrom=mail

[ -f $ConfigFile ] && . $ConfigFile

[ -z "$PageTo" ] && {
    echo "Set 'PageTo' to a pager or cell phone email address"
    exit 1
}

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

if [ "$CIDTYPE" = "MSG" ]
then
    MailSubject="Message"
    MailMsg="$CIDNAME"
else
    MailSubject="$CIDNMBR"
    MailMsg="\nTYPE: $CIDTYPE\nNAME: $CIDNAME\nNMBR: $CIDNMBR\nTIME: $CIDTIME\nDATE: $CIDDATE\n"
fi

# if line indicator found, include it
[ -n "$CIDLINE" ] && MailMsg="${MailMsg}LINE: $CIDLINE\n"

# if a mail user specified and script ID is root, set rootID
[ -n "$PageFrom" ] && [ "`id -nu`" = "root" ] && rootID=1

if [ -n "$rootID" ]
then
    # send mail as user $PageFrom
    echo -e $MailMsg |
        su -s /bin/sh -c "mail -s \"$MailSubject\" $PageTo" $PageFrom
else
    # send mail as user running script
    echo -e $MailMsg | mail -s "$MailSubject" $PageTo
fi

exit 0

#!/bin/sh

# ncid-page
# usage: ncid --no-gui --program ncid-page

# Last modified: Wed May 29, 2013

# sends Caller ID or message to a cell phone, pager, or any other email address
# Requires a mail program

# input is always 6 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# if input is from a message
# the message is in place of NAME:
# input: \n\n\n<MESSAGE>\n\nMSG\n

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-page.conf

# Test whether echo needs option "-e" to interpret new line "\n"
if [ "`echo -e`" != "-e" ] ; then use_e=" -e" ; else use_e= ; fi

# default mail program
PageMail=mail

# default email IP address
PageTo=

# default mail user if root is running script
PageFrom=mail

# default page subject option, either "" or "-s"
PageOpt=

# default $CIDTYPES to send page
PageTypes="CID"

[ -f $ConfigFile ] && . $ConfigFile

[ -z "PageTo" ] && \
{
    echo "Must set PageTo to SMS Gateway or other email address"
    exit 1
}

if [ -n "$PageFrom" ]
then
    # if valid user and script ID is root, set rootID
    [ "`id -nu $PageFrom 2> /dev/null`" = "$PageFrom" ] &&
    [ "`id -nu`" = "root" ] && rootID=1
fi

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

# Look for $CIDTYPE
for i in $PageTypes
do
    [ $i = "$CIDTYPE" ] && { found=1; break; }
done

# Exit if $CIDTYPE not found
[ -z "$found" ] && exit 0

if [ "$CIDTYPE" = "MSG" ]
then
    [ -n "$PageOpt" ] && PageOpt="$PageOpt \"Message\""
    MailMsg="\n$CIDNAME"
else
    [ -n "$PageOpt" ] && PageOpt="$PageOpt \"$CIDNMBR\""
    MailMsg="\nNCID TYPE: $CIDTYPE\nNAME: $CIDNAME\nNMBR: $CIDNMBR\nTIME: $CIDTIME\nDATE: $CIDDATE\n"
fi

# if line indicator found, include it
[ -n "$CIDLINE" ] && MailMsg="${MailMsg}LINE: $CIDLINE\n"

if [ -n "$rootID" ]
then
    # send mail as user $PageFrom
    echo $use_e $MailMsg |
        su -s /bin/sh -c "$PageMail $PageOpt $PageTo" $PageFrom
else
    # send mail as user running script
    echo $use_e $MailMsg | $PageMail $PageOpt $PageTo
fi

exit 0

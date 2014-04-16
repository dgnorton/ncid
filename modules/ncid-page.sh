#!/bin/sh

# ncid-page
# usage: ncid --no-gui --program ncid-page

# Last modified: Sun Apr 13, 2014

# sends Caller ID or message to a cell phone, pager, or any other email address
# Requires a mail program

# input is always 7 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMISC\n
#
# if input is from a message
# the message is in place of NAME:
# input: DATE\nTIME\nNUMBER\nMESG\nLINE\nTYPE\nNAME\n

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

# default $TYPES to send page (see ncid-page.conf for description):
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

read DATE
read TIME
read NMBR
read VAR1
read LINE
read TYPE
read VAR2

# Look for $TYPE
for i in $PageTypes
do
    [ $i = "$TYPE" ] && { found=1; break; }
done

# Exit if $TYPE not found
[ -z "$found" ] && exit 0

# if line indicator = "" make it "-"
[ -z "$LINE" ] && LINE="-"

if [ "$TYPE" = "MSG" ]
then
    MESG="$VAR1"
    NAME="$VAR2"
    MailMsg="NCID TYPE: $TYPE\nDATE: $DATE\nTIME: $TIME\nNAME: $NAME\nNMBR: $NMBR\nLINE: $LINE\n$MESG\n"
else
    NAME="$VAR1"
    MailMsg="NCID TYPE: $TYPE\nDATE: $DATE\nTIME: $TIME\nNAME: $NAME\nNMBR: $NMBR\nLINE: $LINE\n"
fi

[ -n "$PageOpt" ] && PageOpt="$PageOpt \"$NMBR\"\n"
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

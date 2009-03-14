#!/bin/sh

# Page a cell phone, pager, or mail address
# Requires mail

# Last changed by jlc: Fri Feb 13, 2009

# input is 5 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\n
#
# input is 5 lines if a message was sent
# input: \n\n\nMESSAGE\n\n
#
# ncid calls a external program with the "--call-prog" option
# default program: /usr/share/ncid/ncid-speak
#
# ncid usage examples:
#   ncid --call-prog --program ncid-page
#   ncid --no-gui --ring 4 --call-prog --program ncid-page
#   ncid --no-gui --ring 4 --message --call-prog --program ncid-page

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

MailMsg="\nNAME: $CIDNAME\nNMBR: $CIDNMBR\nTIME: $CIDTIME\nDATE: $CIDDATE\n"
MailSubject="$CIDNAME $CIDNMBR"

# if line indicator found, include it
[ -n "$CIDLINE" ] && MailMsg="${MailMsg}LINE: $CIDLINE\n"

# if a mail user specified and script ID is root, set rootID
[ -n "$PageFrom" ] && [ "`id -nu`" = "root" ] && rootID=1

if [ -n "$rootID" ]
then
    # send mail as user $PageFrom
    echo -e $MailMsg |
        su -s /bin/sh -c "/bin/mail -s \"$MailSubject\" $PageTo" $PageFrom
else
    # send mail as user running script
    echo -e $MailMsg | /bin/mail -s "$MailSubject" $PageTo
fi

exit 0

#!/bin/sh

# hangup a call based on a number or name

# input is 5 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\n
#
# input is 5 lines if a message was sent
# input: \n\n\nMESSAGE\n\n
# Message will be in $CIDNAME
#
# ncid calls a external program with the "--call-prog" option
# default program: /usr/share/ncid/ncid-speak
#
# ncid usage:
# do not give option for a message, this module is only for calls
#   ncid --no-gui --call-prog --program ncid-hangup

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf
Blacklist=$ConfigDir/ncid.blacklist
HangupScript=$ConfigDir/ncid.minicom
HangupProg=minicom
HangupOpts="-o -S $HangupScript"
HangupLog=/var/log/ncid-hangup.log
EndProg="\0001q"

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE

if [ -n "$CIDNMBR" ]
then
    # check for the blacklist and script files
    [ -f $Blacklist -a -f $HangupScript ] || exit 1

    # check for minicom
    type $HangupProg > /dev/null 2>&1 || exit 1

    # search for $CIDNAME or $CIDNMBR in Blacklist
    egrep "^$CIDNMBR|^${CIDNAME:-@@@@@}" "$Blacklist" > /dev/null 2>&1

    # if a match was found, hangup on caller and log the call
    (
        [ $? = 0 ] && \
        {
            # terminate the phone call
            echo -e $EndProg | $HangupProg $HangupOpts
            # maintain a hangup log file, if possible
            [ -f $HangupLog ] || \
            {
                [ -w `dirname $HangupLog` ] && touch $HangupLog;
            }
            [ -w $HangupLog ] &&
            echo "$CIDDATE $CIDTIME ${CIDLINE:-<->} $CIDNMBR $CIDNAME" \
                >> $HangupLog
        }
    ) > /dev/null 2>&1
fi

exit 0

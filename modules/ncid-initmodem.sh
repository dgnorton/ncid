#!/bin/bash

# reinitialize a modem to handle Caller ID if CIDNMBR=RING
# which indicates modem is not in Caller ID mode

# Last changed by jlc: Sun Aug 29, 2010

# modem must send "RING" each time it sees the ringing signal
# must be run as root

# input is 5 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\n
#
# input is 5 lines if a message was sent
# input: \n\n\nMESSAGE\n\n
# Message will be in $CIDNAME
#
# ncid usage:
#   ncid --no-gui --program ncid-initmodem

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf
nciddconf=$ConfigDir/ncidd.conf

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE

[ "$CIDNMBR" = "RING" ] &&
{
    # try to get the modem port and lockfile from ncidd.conf: set word = value
    while read arg1 word arg3 value junk
    do
        if [ "$arg1" = "set" -a "$word" = "lockfile" ]
        then
            lockfile="$value"
        elif [ "$arg1" = "set" -a "$word" = "ttyport" ]
        then
            ttyport="$value"
        fi
    done < $nciddconf

    # set the modem port and lockfile
    [ -z "$ttyport" ] && ttyport=/dev/modem
    [ -z "$lockfile" ] && lockfile=/var/lock/LCK..${ttyport##/dev/}

    # tell ncidd to reinitialize the modem
    touch $lockfile
    sleep 1
    rm -f $lockfile
}

exit 0

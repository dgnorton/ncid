#!/bin/bash

# ncid-initmodem
# usage: ncid --no-gui --program ncid-initmodem

# Last Modified: Fri Apr 11, 2014

# reinitialize a modem to handle Caller ID if NMBR=RING
# this indicates modem droped out of Caller ID mode.  Do
# not use with a modem that does not support Caller ID.
# requires a modem

# modem must send "RING" each time it sees the ringing signal
# must be run as root

# input is always 7 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMISC\n
#
# if input is from a message
# the message is in place of NAME:
# input: DATE\nTIME\nNUMBER\nMESG\nLINE\nTYPE\nNAME\n

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-initmodem.conf
nciddconf=/usr/local/etc/ncid/ncidd.conf

# Configuration file is not needed
[ -f $ConfigFile ] && . $ConfigFile

read DATE
read TIME
read NMBR
read VAR1
read LINE
read TYPE
read VAR2

[ "$NMBR" = "RING" ] &&
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

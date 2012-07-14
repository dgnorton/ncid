#!/bin/sh
# script for a TiVo with a modem that drops out of Caller ID mode
# script signals ncidd to re-initialize the modem
# script also restarts ncidd if it is not running
# script requires pgrep
# IMPORTANT: script name should not have ncidd in it
# Last modified  by jlc: Fri Jul 13, 2012

export PATH=/bin:/sbin:/tvbin:/usr/bin:/usr/sbin:/devbin
PATH=$PATH:/usr/local/bin:/usr/local/sbin:/var/hack/bin:/var/hack/sbin:/hack/bin

ConfigDir=/usr/local/etc/ncid
nciddconf=$ConfigDir/ncidd.conf

# check to see if ncidd is running
pgrep ncidd > /dev/null && \
{
    # ncidd is running

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

    # re-initialize the modem
    > $lockfile
    sleep 1
    rm $lockfile
} || \
{
    # ncidd not running, restart ncidd
    ncidd
}

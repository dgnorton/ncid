#!/bin/sh

# Skeleton Output Module
# Modify as needed for new module
# keep "ncid-" in the name

# Last changed by jlc: Wed Sep 19, 2007

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
#   ncid --no-gui --message --call-prog --program ncid-skel

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE

if [ -n "$CIDNMBR" ]
then
    # Display Caller ID information
    echo "$CIDDATE $CIDTIME $CIDNMBR $CIDNAME $CIDLINE"
else
    # Display Message
    echo "$CIDNAME"
fi

exit 0

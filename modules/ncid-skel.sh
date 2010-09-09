#!/bin/sh

# Skeleton Output Module
# Modify as needed for new module
# keep "ncid-" in the name

# Last changed by jlc: Sun Aug 29, 2010

# input is 5 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\n
#
# input is 5 lines if a message was sent
# input: \n\n\nMESSAGE\n\n
# Message will be in $CIDNAME
#
# ncid usage:
#   ncid --no-gui [--message] --program ncid-skel

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

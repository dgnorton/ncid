#!/bin/sh

# Samba Interface to create a popup
# Requires smbclient

# Last changed by jlc: Sun Aug 29, 2010

# send the CID information to a windows machine via popup
# This will not work if the messenger service is disabled.

# input is 5 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\n
#
# input is 5 lines if a message was sent
# input: \n\n\nMESSAGE\n\n
#
# ncid usage:
#       ncid --no-gui [--message] --program ncid-samba

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf

# set SambaClient to a windows computer name to send a SMB popup
SambaClient=

[ -f $ConfigFile ] && . $ConfigFile

[ -z "$SambaClient" ] && {
    echo "Set SambaClient to a windows computer name to send a SMB popup"
    exit 1
}

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE

if [ -n "$CIDNMBR" ]
then
    # Display Caller ID information
    echo "$CIDDATE $CIDTIME $CIDLINE $CIDNMBR $CIDNAME" |
         smbclient -M $SambaClient
else
    # Display Message
    echo "$CIDNAME" | smbclient -M $SambaClient
fi

exit 0

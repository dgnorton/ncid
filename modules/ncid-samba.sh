#!/bin/sh

# Samba Interface to create a popup
# Requires smbclient

# Last changed by jlc: Sun Sep 11, 2011

# send the CID information to a windows machine via popup
# This will not work if the messenger service is disabled.

# input is 6 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# input is 6 lines if a message was sent
# input: \n\n\n<MESSAGE>\n\nMSG\n
#
# ncid usage:
#       ncid --no-gui [--message] --program ncid-samba

# $CIDTYPE is one of:
#   CID: incoming call
#   OUT: outgoing call
#   HUP: blacklisted hangup
#   MSG: message instead of a call

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
read CIDTYPE

if [ -n "$CIDNMBR" ]
then
    # Display Caller ID information
    echo "$CIDTYPE $CIDDATE $CIDTIME $CIDLINE $CIDNMBR $CIDNAME" |
         smbclient -M $SambaClient
else
    # Display Message
    echo "$CIDNAME" | smbclient -M $SambaClient
fi

exit 0

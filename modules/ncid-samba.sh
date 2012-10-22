#!/bin/sh

# ncid-samba
# usage: ncid --no-gui --program ncid-samba

# Last modified: Fri Oct 12, 2012

# Samba Interface to create a popup
# Requires smbclient

# send the CID information to a windows machine via popup
# This will not work if the messenger service is disabled.

# input is always 6 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
#
# if input is from a message
# the message is in place of NAME:
# input: \n\n\n<MESSAGE>\n\nMSG\n

# $CIDTYPE is one of:
#   CID: incoming call
#   OUT: outgoing call
#   HUP: blacklisted hangup
#   MSG: message instead of a call

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-samba.conf

SambaClient=""
SambaTypes="CID OUT HUP MSG"

[ -f $ConfigFile ] && . $ConfigFile

[ -z "$SambaClient" ] && {
    echo "Set \"SambaClienti\" to a windows computer name to send a SMB popup"
    exit 1
}

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE
read CIDTYPE

# Look for $CIDTYPE
for i in $SambaTypes
do
    [ $i = "$CIDTYPE" ] && { found=1; break; }
done

# Exit if $CIDTYPE not found
[ -z "$found" ] && exit 0

if [ "$CIDTYPE" = "MAG" ]
then
    # Display Message
    echo "$CIDNAME" | smbclient -M $SambaClient
else
    # Display Caller ID information
    echo "$CIDTYPE $CIDDATE $CIDTIME $CIDLINE $CIDNMBR $CIDNAME" |
         smbclient -M $SambaClient
fi

exit 0

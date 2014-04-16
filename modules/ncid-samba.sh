#!/bin/sh

# ncid-samba
# usage: ncid --no-gui --program ncid-samba

# Last modified: Sun Apr 13, 2014

# Samba Interface to create a popup
# Requires smbclient

# send the CID information to a windows machine via popup
# This will not work if the messenger service is disabled.

# input is always 7 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMISC\n
#
# if input is from a message
# the message is in place of NAME:
# input: DATE\nTIME\nNUMBER\nMESG\nLINE\nTYPE\nNAME\n

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-samba.conf

# defaults (see ncid-samba.conf for description):
SambaTypes="CID OUT HUP BLK MSG PID NOT"
SambaClient=""

[ -f $ConfigFile ] && . $ConfigFile

[ -z "$SambaClient" ] && {
    echo "Set \"SambaClienti\" to a windows computer name to send a SMB popup"
    exit 1
}

read DATE
read TIME
read NMBR
read VAR1
read LINE
read TYPE
read VAR2

# Look for $TYPE
for i in $SambaTypes
do
    [ $i = "$TYPE" ] && { found=1; break; }
done

# Exit if $TYPE not found
[ -z "$found" ] && exit 0

if [ "$TYPE" = "MSG" -o "$TYPE" = "NOT" ]
then
    NAME="$VAR2"
    MESG="$VAR1"
    # Display Message or Notice
    echo "$MESG" | smbclient -M $SambaClient
else
    NAME="$VAR1"
    # Display Caller ID information
    echo "$TYPE $DATE $TIME $LINE $NMBR $NAME" |
         smbclient -M $SambaClient
fi

exit 0

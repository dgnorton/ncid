#!/bin/sh

# send the CID information to a windows machine via popup
# This will not work if the messenger service is disabled.

# input is 5 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\n
#
# input is 5 lines if a message was sent
# input: \n\n\nMESSAGE\n\n
#
# ncid calls a external program with the "--call-prog" option
# default program: /usr/share/ncid/ncid-speak
#
# ncid usage examples:
#       ncid --call-prog --message --program ncid-samba
#       ncid --no-gui --message --call-prog --program ncid-samba

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidscript.conf

# set CLIENT to a windows computer name to send a SMB popup
CLIENT=

[ -f $ConfigFile ] && . $ConfigFile

[ -z "$CLIENT" ] && {
    echo "Set CLIENT to a windows computer name to send a SMB popup"
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
    echo "$CIDDATE $CIDTIME $CIDLINE $CIDNMBR $CIDNAME" | smbclient -M $CLIENT
else
    # Display Message
    echo "$CIDNAME" | smbclient -M $CLIENT
fi

exit 0

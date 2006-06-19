#!/bin/sh

# send the CID information to a windows machine via popup
# This will not work if the messenger service is disabled.

# input is 5 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\n
#
# ncid calls a external program with the "--call-prog" option
# default program: /usr/share/ncid/ncid-page
#
# ncid usage examples:
#       ncid --call-prog --program ncid-samba
#       ncid --no-gui --call-prog --program ncid-samba

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

echo "         ******* Incoming Phone Call *******

$CIDDATE $CIDTIME $CIDNMBR $CIDNAME" | smbclient -M $CLIENT

exit 0

#!/bin/sh

# input is 5 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\n
#
# ncid calls a external program with the "--call-prog" option
# default program: /usr/share/ncid/ncid-page
#
# ncid usage examples:
#   ncid --call-prog
#   ncid --call-prog --program ncid-page
#   ncid --no-gui --call-prog

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidscript.conf

# set ADDRESS to a pager or cell phone email address
ADDRESS=

[ -f $ConfigFile ] && . $ConfigFile

[ -z "$ADDRESS" ] && {
    echo "Set ADDRESS to a pager or cell phone email address"
    exit 1
}

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE

if [ -z "$CIDLINE" ]
then
    # no line indicator
    echo -e "$CIDNAME\n$CIDNMBR\n$CIDTIME\n$CIDDATE\n" |
        mail -s "Telephone Call" $ADDRESS
else
    echo -e "$CIDNAME\n$CIDNMBR\n$CIDLINE\n$CIDTIME\n$CIDDATE\n" |
        mail -s "Telephone Call" $ADDRESS
fi

exit 0

#!/bin/sh

# input is 4 lines obtained from ncid using the "-all" option
# input: DATE\nTIME\nNUMBER\nNAME\n
# ncid calls a external program with the "--call-prog" option
# default program: /usr/share/ncid/ncid-page
#
# ncid usage examples:
#   ncid --all --call-prog
#	ncid --all --call-prog --program ncid-page
#	ncid --no-gui --all --call-prog

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

echo -e "$CIDNAME\n$CIDNMBR\n$CIDTIME\n$CIDDATE\n" |
	mail -s "Telephone Call" $ADDRESS

exit 0

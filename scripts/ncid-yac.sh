#!/bin/sh

# NCID to YAC Clients

# input is 5 lines obtained from ncid
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\n
#
# input is 5 lines if a message was sent
# input: \n\n\nMESSAGE\n\n
#
# ncid calls a external program with the "--call-prog" option
# default program: /usr/share/ncid/ncid-speak
#
# ncid usage:
#   ncid --no-gui --message --call-prog --program nid2yac

YACPORT=10629
YACLIST=127.0.0.1

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidscript.conf

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE

for YACCLIENT in ${YACLIST}
do
    echo -n "@CALL${CIDNAME}~${CIDNMBR}" | nc -w1 $YACCLIENT $YACPORT
done

exit 0

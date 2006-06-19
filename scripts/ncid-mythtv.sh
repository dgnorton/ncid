#!/bin/sh

# MythTV Display, see http://www.mythtv.org/wiki/index.php/Little_Gems

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

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE

mythtvosd --caller_name="$CIDNAME" \
          --caller_number="$CIDNMBR" \
          --caller_date="$CIDDATE" \
          --caller_time="$CIDTIME"

exit 0

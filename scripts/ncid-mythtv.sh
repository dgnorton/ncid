#!/bin/sh

# MythTV Display, see http://www.mythtv.info/moin.cgi/LittleGems

# input is 4 lines obtained from ncid using the "-all" option
# input: DATE\nTIME\nNUMBER\nNAME\n
# ncid calls a external program with the "--call-prog" option
# default program: /usr/share/ncid/ncid-page
#
# ncid usage examples:
#   ncid --all --call-prog
#   ncid --all --call-prog --program ncid-page
#   ncid --no-gui --all --call-prog

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidscript.conf

[ -f $ConfigFile ] && . $ConfigFile

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME

mythtvosd --caller_name="$CIDNAME" \
          --caller_number="$CIDNMBR" \
          --caller_date="$CIDDATE" \
          --caller_time="$CIDTIME"

exit 0

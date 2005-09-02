#!/bin/sh

# most of this program is taken from nciduser by Mace Moneta
# requires festival: http://www.cstr.ed.ac.uk/projects/festival

# input is 4 lines obtained from ncid using the "-all" option
# input: DATE\nTIME\nNUMBER\nNAME
# ncid calls a external program with the "--call-prog" option
# default program: /usr/share/ncid/ncid-page
#
# ncid usage examples:
#   ncid --all --call-prog
#   ncid --all --call-prog --program ncid-speak
#   ncid --no-gui --all --call-prog --program ncid-speak

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidscript.conf

### defaults if not using config file ###
# If festival is being used:
T2S='`echo $SAY | festival --tts`'
# If using a Macintosh without festival:
#T2S='/usr/bin/osascript -e \"say $SAY\"'
# What to say
SAY="Telephone call from $CIDNAME"
#SAY="$CIDNAME"
# Number of times to speak
SAYNUM=1
# delay between speaking
DELAY=2

[ -f $ConfigFile ] && . $ConfigFile

while [ ${SAYNUM:=1} != 0 ]
do
    eval $T2S
    SAYNUM=`expr $SAYNUM - 1`
    [ $SAYNUM = 0 ] || /bin/sleep ${DELAY:=1}
done

exit 0

#!/bin/sh

# Announce the Caller ID
# Requires festival

# Last changed by jlc: Wed Sep 19, 2007

# most of this program is taken from nciduser by Mace Moneta
# requires festival: http://www.cstr.ed.ac.uk/projects/festival

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
#   ncid --call-prog
#   ncid --no-gui --call-prog
#   ncid --call-prog --program ncid-speak
#   ncid --no-gui --call-prog --program ncid-speak

read CIDDATE
read CIDTIME
read CIDNMBR
read CIDNAME
read CIDLINE

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidmodules.conf

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
SpeakDelay=2

[ -f $ConfigFile ] && . $ConfigFile

while [ ${SAYNUM:=1} != 0 ]
do
    eval $T2S
    SAYNUM=`expr $SAYNUM - 1`
    [ $SAYNUM = 0 ] || /bin/sleep ${SpeakDelay:=1}
done

exit 0

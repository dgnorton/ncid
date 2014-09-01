#!/bin/sh

# ncid-skel
# usage: ncid --no-gui --program ncid-skel

# Last Modified: Fri Aug 22, 2014

# Skeleton Output Module
# Modify as needed for new module
# keep "ncid-" in the name

# Module should provide a default for all variables.
# User changeable variables are in /usr/local/etc/ncid/conf.d/ncid-skel.conf

# input is always 8 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n""\n""\n
#
# if input is from a message
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMESG\nMTYPE\n

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-skel.conf

# defaults (see ncid-skel.conf for description):
skel_types="CID OUT HUP BLK MSG PID NOT"
skel_raw=0

[ -f $ConfigFile ] && . $ConfigFile

read DATE
read TIME
read NMBR
read NAME
read LINE
read TYPE
read MESG
read MTYPE

# Look for $TYPE
for i in $skel_types
do
    [ $i = "$TYPE" ] && { found=1; break; }
done

# This is a special test mode, remove if using ncid-skel as a template
if [ $skel_raw ]
    then
        if [ "$found" ]; then RESULT="in list:"; else RESULT="not in list:"; fi
        echo "1 DATE=$DATE" >/dev/tty
        echo "2 TIME=$TIME" >/dev/tty
        echo "3 NMBR=$NMBR" >/dev/tty
        echo "4 NAME=$NAME" >/dev/tty
        echo "5 LINE=$LINE" >/dev/tty
        echo "6 TYPE=$TYPE $RESULT $skel_types" >/dev/tty
        echo "7 MESG=$MESG" >/dev/tty
        echo "8 MTYPE=$MTYPE" >/dev/tty
        echo "------------" >/dev/tty
fi
# End of special test mode

# Exit if $TYPE not found
[ -z "$found" ] && exit 0

# calls and messages are handled differently
if [ "$TYPE" = "MSG" -o "$TYPE" = "NOT" ]
then
    # Display Message or Notice on /dev/tty
    echo "$DATE|$TIME|$NMBR|$NAME|$LINE|$TYPE|$MTYPE" > /dev/tty
    echo "$MESG" > /dev/tty
else
    # Display Caller ID information on /dev/tty
    echo "$DATE|$TIME|$NMBR|$NAME|$LINE|$TYPE|" > /dev/tty
fi

exit 0

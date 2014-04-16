#!/bin/sh

# ncid-skel
# usage: ncid --no-gui --program ncid-skel

# Last modified: Sun Apr 13, 2014

# Skeleton Output Module
# Modify as needed for new module
# keep "ncid-" in the name

# Module should should provide a default for all cariables.
# User changable variables are in /usr/local/etc/ncid/conf.d/ncid-skel.conf

# input is always 7 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n\MISC\n
#
# if input is from a message
# the message is in place of NAME:
# input: DATE\nTIME\nNUMBER\nMESG\nLINE\nTYPE\nNAME\n

ConfigDir=/usr/local/etc/ncid/conf.d
ConfigFile=$ConfigDir/ncid-skel.conf

# default (see ncid-skel.conf for description):
skel_types="CID OUT HUP BLK MSG PID NOT"

[ -f $ConfigFile ] && . $ConfigFile

read DATE
read TIME
read NMBR
read VAR1
read LINE
read TYPE
read VAR2

# Look for $TYPE
for i in $skel_types
do
    [ $i = "$TYPE" ] && { found=1; break; }
done

# Exit if $TYPE not found
[ -z "$found" ] && exit 0

if [ "$TYPE" = "MSG" -o "$TYPE" = "NOT" ]
then
    NAME="$VAR2"
    MESG="$VAR1"
    # Display Message or Notice on /dev/tty
    echo "$DATE|$TIME|$NMBR|$NAME|$LINE|$TYPE" > /dev/tty
    echo "$MESG" > /dev/tty
else
    NAME="$VAR1"
    # Display Caller ID information on /dev/tty
    echo "$DATE|$TIME|$NMBR|$NAME|$LINE|$TYPE" > /dev/tty
fi

exit 0

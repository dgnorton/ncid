#!/bin/sh
# script to start NCID
# Requires the "pgrep" command
# Last modified  by jlc: Wed Oct 31, 2012

### This script requires pgrep.  If /var/hack/bin/pgrep is not
### present, you can use pgrep from the tivotools distribution:
### http://www.dealdatabase.com/forum/showthread.php?t=37602
### You can either add the directory of tivotools to PATH in
### the PATH section of you can copy pgrep to /var/hack/bin/
### if you do not need tivotools installed.

### This script can be run manually or from rc.sysinit.author:
### manually:         /var/hack/bin/startncid

### This script can start ncidd, sip2ncid, yac2ncid, tivocid, tivoncid,
### ncid-initmodem, ncid-yac, and ncid-notify.
### It can also set the local timezone.
### 
### The default script starts ncidd and tivocid.
###
### Uncomment or comment out indicated lines in the
### customize section to start selected NCID programs.
###
### A program will not start if it is already running.
### Kill programs manually to stop them
###
### If you are using sip2ncid or yac2ncid, you need to uncomment
### one of the TZ lines or modify one for your timezone.

################
### Defaults ###
################

export PATH TZ LD_LIBRARY_PATH
# default PATH and LD_LIBRARY_PATH
PATH=/bin:/sbin:/tvbin:/devbin:/var/hack:/var/hack/bin:/var/hack/sbin:/hack/bin
LD_LIBRARY_PATH=/lib:/var/hack/lib:/hack/bin

###############################
###############################
### Customize Section Start ###
###############################
###############################

############
### PATH ###
############
### If you need to search an additional directory to run pgrep
### For example, the pgrep version in tivotools, add the directory path
### of tovotools to the following line and uncomment it (remove the #):
#PATH=$PATH:

#######################
### LD_LIBRARY_PATH ###
#######################
### If you need to search an library directory, add it to
### the following line and uncomment it (remove the #):
#LD_LIBRARY_PATH=$LD_LIBRARY_PATH:

#################################################
### The TiVo Timezone is UTC                  ###
###                                           ###
### If you are using sip2ncid or yac2ncid,    ###
### set TZ to your local timezone.            ###
#################################################
### Here are example TZ lines for EST:
### TZ=EST5EDT,M3.2.0,M11.1.0 # Gives daylight savings start and end dates
### TZ=TIMEZONE.Mmonth.week.day/time,month.week.day/time
###    EST5EDT .  M3  . 2  . 0      , M11 . 1  . 0  (time defaults to 2:00 AM)
### TZ=EST                    # No daylight savings time
###
### Remove one of the following '#' to enable your time zone
### or modify it, or add your missing timezone
#TZ=AST4ADT,M3.2.0,M11.1.0    # ATLANTIC TIME
#TZ=EST5EDT,M3.2.0,M11.1.0    # EASTERN TIME
#TZ=CST6CDT,M3.2.0,M11.1.0    # CENTRAL TIME
#TZ=MST7MDT,M3.2.0,M11.1.0    # MOUNTAIN TIME
#TZ=PST8PDT,M3.2.0,M11.1.0    # PACIFIC TIME
#TZ=AKST9AKDT,M3.2.0,M11.1.0  # ALASKAN TIME
#TZ=HST10,M3.2.0,M11.1.0      # HAWAII-ALEUTIAN STANDARD TIME

################################
### Enable Programs to Start ###
################################
### Remove '#' from beginning of line to enable program.
### Add '#' to beginning of line to disable program.
### Startncid will not try to start a running program.
### The distribution default only starts ncidd and tivoncid

### Server and Gateways
#
# Enable Server if using it on this TiVo
SERVER=ncidd
#
# Enable SIP Gateway if using SIP (VoIP) to get Caller ID
# Be sure to uncomment this line in ncidd.c: # set noserial = 1
#SIPGW=sip2ncid
#
# Enable YAC Gateway if using yac to get Caller ID
#YACGW=yac2ncid

### Enable only one of these three clients: tivocid, tivoncid, or ncid-fly
###   if out2osd works on your system use tivocid
###   tivoncid should work on all systems, but it uses text2osd
###   which causes a reboot if the TiVo is using HME
###   Install and enable ncid-fly if you use HME apps
#
# Enable tivoncid client if using text2osd, disable tivocid client
OSDCLIENT=tivoncid
#
# Enable tivocid client if using out2osd, disable tivoncid client
#OSDCLIENT=tivocid
#
# Enable the Fly Client Module if using ncid-fly to display on the TiVo
# OSDCLIENT must not be enabled to use this output module.
#
# Requires installation of ncid-fly and supporting programs plus rsyslog-5.8.4
#
# Get rsyslog and install it from
#   http://www.dealdatabase.com/forum/showthread.php?66672-rsyslog-5-8-4
#
# Get and install the ncid-fly package from:
# http://www.dealdatabase.com/forum/showthread.php?53236-Series-3-caller-ID-NCID&p=316308#post316308
#   cd /var; tar -xzvf <path>/ncid-fly-mips-tivo.tgz
#
# Uncomment this line if using the ncid-fly package
#MODULES="$MODULES ncid-fly"
#
# This package is also usable if you use a full path to fly2osd
#   http://www.dealdatabase.com/forum/showthread.php?66673-fly2osd&p=315611
# Uncomment this line if using fly2osd, modify path as required
# MODULES="$MODULES /var/hack/fly2osd/ncid-fly"
#
# For a older version of ncid-fly see
#   http://www.dealdatabase.com/forum/showpost.php?p=308346&postcount=75

### Additional client modules
#
# Enable Initmodem Client Module to automatically reinitialize modem
# for Caller ID.  Autodetects modem in non-CID mode on a incoming call.
#MODULES="$MODULES ncid-initmodem"
#
# Enable Notify Client module if sending NCID data to iOS or Android device
# Requires: curl, website registration, and a app for android or iOS
#MODULES="$MODULES ncid-notify"
#
# Enable Page Client module if sending a NCID data SMS message to a cell phone
# Requires: a mail program
#MODULES="$MODULES ncid-page"
#
# Enable YAC Client Module if sending Caller ID to yac clients
# Must configure "YACLIST" in ncid-yac.conf
#MODULES="$MODULES ncid-yac"

#############################
#############################
### Customize Section END ###
#############################
#############################

### Server
[ -n "$SERVER" ] &&
{
    pgrep -fl $SERVER > /dev/null || $SERVER
}

### SIP Gayteway
[ -n "$SIPGW" ] &&
{
    pgrep -fl $SIPGW > /dev/null || $SIPGW
} 

### YAC Gateway
[ -n "$YACGW" ] &&
{
    if ! pgrep -fl $YACGW > /dev/null
    then
        $YACGW&
    fi
}

### Client
[ -n "$OSDCLIENT" ] &&
{
    if !  pgrep -fl "out2osd|ncid-tivo" > /dev/null
    then
        $OSDCLIENT&
    fi
}

### All Modules
for module in $MODULES
do
    if ! pgrep -fl $module > /dev/null
    then
        ncid --no-gui --program $module&
    fi
done

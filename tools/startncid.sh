#!/bin/sh
# script to start NCID
# Requires the "ps" command
# Last modified  by jlc: Thu Apr 15, 2010

### This script can be run from:
### rc.sysinit.author:   /var/hack/bin/startncid rmpid
### or manually:         /var/hack/bin/startncid

### This script can start ncidd, sip2ncid, yac2ncid, tivocid, tivoncid,
### ncid-initmodem, and ncid-yac.  It can also set the local timezone.
### 
### The default is to start ncidd and tivocid.
### Uncomment or comment out lines to start the NCID programs required.
###
### The NCID programs will not start if already running.
### Kill programs manually to stop them
###
### If you are using sip2ncid or yac2ncid, you need to uncomment
### one of the TZ lines or modify one for your timezone.

# Indicate usage if a argument is given and it is not rmpid
[ "$1" != "" -a "$1" != "rmpid" ] && \
{
    echo "Usage $0 [rmpid]"
    exit 0
}

# if argument is rmpid, remove all NCID pid files in /var/run
[ "$1" = "rmpid" ] && rm -f /var/run/*ncid*.pid

# Set the Path to include the NCID bin and sbin directories
export PATH TZ
PATH=/bin:/sbin:/tvbin:/devbin:/var/hack:/var/hack/bin:/var/hack/sbin:/hack/bin

################################################
### The TiVo Timezone is UTC                 ###
###                                          ###
### If you are using sip2ncid or yac2ncid,   ###
### you should set TZ to the local timezone. ###
################################################
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

###########################
### Start Programs Used ###
###########################
### remove '#' from beginning of line to enable program
### add '#' to beginning of line disable program

# Enable Server if using it on this TiVo
SERVER=ncidd

# Enable SIP Gateway if using SIP (VoIP) to get Caller ID
#SIPGW=sip2ncid

# Enable YAC Gateway if using yac to get Caller ID
#YACGW=yac2ncid

# Clients, enable only one client
# if out2osd works on your system use tivocid
# test2osd should work on all systems, but is not as good
#
# Enable tivoncid client if using text2osd, disable tivocid client
OSDCLIENT=tivoncid
#
# Enable tivocid client if using out2osd, disable tivoncid client
#OSDCLIENT=tivocid

# Enable Initmodem Client Module if need to re-initialize modem
#INITMOD=ncid-initmodem

# Enable YAC Client Module if sending Caller ID to yac clients
# Must configure "YACLIST" in ncidmodules.conf
#YACMOD=ncid-yac

################################
### End of all Modifications ###
################################

### Server
[ -n "$SERVER" ] &&
ps auxw | grep $SERVER | grep -v grep > /dev/null || $SERVER

### SIP Gayteway
[ -n "$SIPGW" ] &&
ps auxw | grep $SIPGW | grep -v grep > /dev/null || $SIPGW 

### YAC Gateway
[ -n "$YACGW" ] &&
{
    if ! ps auxw | grep $YACGW | grep -v grep > /dev/null
    then
        $YACGW&
    fi
}

### Client
[ -n "$OSDCLIENT" ] &&
{
    if !  ps auxw | grep -E "out2osd|ncid-tivo" | grep -v grep > /dev/null
    then
        $OSDCLIENT&
    fi
}

### Initmodem Client Module
[ -n "$INITMOD" ] &&
{
    if ! ps auxw | grep $INITMOD | grep -v grep > /dev/null
    then
        ncid --no-gui --call-prog --program $INITMOD&
    fi
}

### YAC Client Module
[ -n "$YACMOD" ] &&
{
    if ! ps auxw | grep $YACMOD | grep -v grep > /dev/null
    then
        ncid --no-gui --messages --call-prog --program $YACMOD&
    fi
}

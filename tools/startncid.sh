#!/bin/sh
# script to start NCID
# Requires the "ps" command
# Last modified  by jlc: Mon Jul 19, 2010

### This script requires pgrep.  If /var/hack/bin/pgrep is not
### present, you can use pgrep from the tivotools distribution:
### http://www.dealdatabase.com/forum/showthread.php?t=37602
### You can either add the directory of tivotools to PATH in
### the PATH section of you can copy pgrep to /var/hack/bin/
### if you do not need tivotools installed.

### This script can be run from:
### rc.sysinit.author:   /var/hack/bin/startncid rmpid
### or manually:         /var/hack/bin/startncid

### This script can start ncidd, sip2ncid, yac2ncid, tivocid, tivoncid,
### ncid-initmodem, and ncid-yac.  It can also set the local timezone.
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

##################################
##################################
### Start of Customize Section ###
##################################
##################################

############
### PATH ###
############
### If you need to search an additional directory to run pgrep
### For example, the pgrep version in tivotools, add the directory path
### of tovotools to the following line and uncomment it (remove the #):
#PATH=$PATH:

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

###############################
### Start Required Programs ###
###############################
### Remove '#' from beginning of line to enable program.
### Add '#' to beginning of line to disable program.
### Startncid will not try to start a running program.
### The distribution default only starts ncidd and tivoncid

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
################################
### End of Customize Section ###
################################
################################

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

### Initmodem Client Module
[ -n "$INITMOD" ] &&
{
    if ! pgrep -fl $INITMOD > /dev/null
    then
        ncid --no-gui --call-prog --program $INITMOD&
    fi
}

### YAC Client Module
[ -n "$YACMOD" ] &&
{
    if ! pgrep -fl $YACMOD > /dev/null
    then
        ncid --no-gui --call-prog --program $YACMOD&
    fi
}

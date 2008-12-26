#!/bin/sh
# script to start NCID
# Last modified  by jlc: Sat Dec 20, 2008

### This script can be run from:
### rc.sysinit.author:   /var/hack/bin/startncid rmpid
### or manually:         /var/hack/bin/startncid

### This script starts ncidd, sip2ncid, yac2ncid, tivocid, tivoncid, or
### ncid with the page or YAC module. It can also set the local timezone.
### 
### The default is to start ncidd and tivocid.
### Uncomment/comment lines to start the NCID programs needed.
###
### If you are using sip2ncid or yac2ncid, you need to uncomment the
### TZ line and modify it for your timezone.

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
PATH=/bin:/sbin:/tvbin:/devbin:/var/hack:/var/hack/bin:/var/hack/sbin

### The TiVo Timezone is UTC
### If you are using sip2ncid or yac2ncid and you want calls in your local
### timezone, set TZ to the local timezone.
###
### Here are example TZ lines for EST:
### TZ=EST5EDT,M3.2.0,M11.1.0 # With daylight savings time
### TZ=EST5EDT                # With daylight savings time
### TZ=EST                    # No daylight savings time
###
#TZ=EST5EDT,M3.2.0,M11.1.0

### Start the server
ncidd

### Start the SIP Gateway
#sip2ncid

### Start either client, but not both ###
# Start the client that uses out2osd
tivocid &
# or start the client that uses text2osd
#tivoncid &

### Start ncid with the page module to send call information to a cell phone
### Must configure "PageTo" in ncidmodules.conf
### Ring Count is only used for modems, for SIP, use: --ring -1
###
#ncid --no-gui --ring 4 --message --call-prog --program ncid-page &

### Start ncid with the YAC module to send call information to YAC clients
### Must configure "YACLIST" in ncidmodules.conf
###
#ncid --no-gui --message --call-prog --program ncid-yac &

### start the YAC Gateway
### needed if running a YAC Server on a PC to obtain the Caller ID
###
#yac2ncid &

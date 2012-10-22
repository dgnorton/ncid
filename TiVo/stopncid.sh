#!/bin/sh
# script to stop NCID
# Requires the "pgrep" command
# Created  by jlc: Fri Jul 13, 2012
# Modified  by jlc: Wed Sep 19, 2012

### This script uses bash and pgrep

### If /var/hack/bin/pgrep is not present, you can use pgrep
### from the tivotools distribution:
### http://www.dealdatabase.com/forum/showthread.php?t=37602
### You can either add the directory of tivotools to PATH in
### the PATH section of you can copy pgrep to /var/hack/bin/
### if you do not need tivotools installed.

### This script can be run manually and from crontab:
### /var/hack/bin/stopncid

### This script will stop ncidd, ncid2ncid, sip2ncid, yac2ncid,
### tivocid, tivoncid, ncid-initmodem, ncid-notify, ncid-page,
### ncid-tivo, and ncid-yac.

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
### of tivotools to the following line and uncomment it (remove the #):
#PATH=$PATH:

#######################
### LD_LIBRARY_PATH ###
#######################
### If you need to search an library directory, add it to
### the following line and uncomment it (remove the #):
#LD_LIBRARY_PATH=$LD_LIBRARY_PATH:

########################
### Programs to Stop ###
########################
### Normally you would not modify this line unless you need to
### add a program to be stoppped

STOPNCID="
          ncid2ncid
          sip2ncid
          yac2ncid
          tivocid
          tivoncid
          ncid-initmodem
          ncid-notify
          ncid-page
          ncid-tivo
          ncid-yac
          ncidd
         "

##############################
##############################
### Customize Section Stop ###
##############################
##############################

for i in $STOPNCID
do
    PID=`pgrep -fl $i` && \
    {
        echo $PID;
        kill ${PID%% *}
    }
done


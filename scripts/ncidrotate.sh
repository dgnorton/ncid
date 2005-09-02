#!/bin/sh

# converted by John L. Chmielewski
# from a python script by Lyman Epp
# Created Wed Aug 4, 2004
# Last modified: Fri Mar 4, 2005

[ "$1" != "prerotate" -a "$1" != "postrotate" ] && \
{
    echo "Usage: `basename $0` {prerotate|postrotate}"
    exit -1
}

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidrotate.conf

# default values (used without a config file)
Logfile=/var/log/cidcall.log
Newlogfile=/var/log/cidcall.cur
Arclogfile=/var/log/cidcall.arc
Lines2keep=0

[ -f $ConfigFile ] && . $ConfigFile

[ "$1" = "prerotate" ] && \
{
    LineCount=`wc -l $Logfile | sed 's/ *\([0-9]*\).*/\1/'`
    ArcLines=`expr $LineCount - $Lines2keep`

    if [ $Lines2keep -gt 0 ]
    then
        tail -$Lines2keep $Logfile > $Newlogfile
    else
        touch $Newlogfile
    fi

    if [ $ArcLines -gt 0 ]
    then
        head -$ArcLines $Logfile > $Arclogfile
    else
        touch $Arclogfile
    fi
    mv -f $Arclogfile $Logfile
} || \
{
    # postrotate
    mv -f $Newlogfile $Logfile
}

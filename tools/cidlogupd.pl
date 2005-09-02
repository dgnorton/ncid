#!/usr/bin/perl

# cidlog - caller ID report

# Created by Aron Green on Mon Nov 25, 2002
# based on cidlog and cidalias
# Cleanup by John L. Chmielewski on Tue Nov 26, 2002
# Changed $CONFIG value on Sat May 21, 2005 by John L. Chmielewski
# Modified by John L. Chmielewski on Sat Aug 13, 2005
#   - Changed from using config file to alias file

use Getopt::Std;

$ALIAS = "/etc/ncid/ncidd.alias";
$LOG = "/var/log/cidcall.log";

getopts('a:l:') ||
    die "Usage: cidlogupd [-a aliasfile] [-l logfile] [newlogfile]\n";

($alias = $opt_a) || ($alias = $ALIAS);
($log = $opt_l) || ($log = $LOG);
($newlog = shift) || ($newlog = sprintf("%s.new", $log));

open(ALIASFILE, $alias) || die "Could not open $alias\n";
open(LOGFILE, $log) || die "Could not open $log\n";
open(NEWLOGFILE, ">$newlog") || die "Could not open $newlog\n";

while (<ALIASFILE>) {
    if (/^alias/) {
    chomp;
        ($type, $from, $to, $value) = /^.*alias\s+(\w+)\s+"*([\w\s\@'&,_-]+)"*\s+=\s+"*([\w\s\@'&_-]+)"*\s*i*f*\s*"*([\w\s\@'&_-]*)"*$/;
    $alias = join(":", ($type, $from, $to, $value));
    push(@aliases, $alias);
    }
}

#CID: *DATE*11242002*TIME*2112*LINE*1*NMBR*9549142285*MESG*NONE*NAME*Cell*

while (<LOGFILE>) {
    if (/CID|EXTRA/) {
        ($date, $time, $number, $mesg, $name) = 
            /.*DATE.(\d+).*TIME.(\d+).*NU*MBE*R.([-\w\s]+).*MESG.(\w+).*NAME.(.*)\*+$/;
        ($line) = /.*LINE.([-\w\s]+).*/;

    foreach $alias (@aliases) {
        ($type, $from, $to, $value) = split(/:/, $alias);
        if ($value ne "") {
            if ($type eq "NAME" && $number eq $value && $name eq $from)
                {$name = $to;}
            if ($type eq "NMBR" && $name eq $value && $number eq $from)
                {$number = $to;}
        } else {
            if ($type eq "NAME" && $name eq $from) {$name = $to;}
            if ($type eq "NMBR" && $number eq $from) {$number = $to;}
        }
    }
    printf(NEWLOGFILE
        "CID: *DATE*%s*TIME*%s*LINE*%s*NMBR*%s*MESG*%s*NAME*%s*\n",
        $date, $time, $line, $number, $mesg, $name);
    } else {
        printf(NEWLOGFILE);
    }
}

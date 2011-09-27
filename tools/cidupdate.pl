#!/usr/bin/perl

# cidupdate - update Caller ID aliases in alias file

# Created by Aron Green on Mon Nov 25, 2002
# based on cidlog and cidalias
# Cleanup by John L. Chmielewski on Tue Nov 26, 2002
# Changed $CONFIG value on Sat May 21, 2005 by John L. Chmielewski
# Modified by John L. Chmielewski on Sat Aug 13, 2005
#   - Changed from using config file to alias file
# Modified by John L. Chmielewski on Fri Apr 14, 2006
#   - Changed name from cidlogupd to cidupdate, updated variable names
# Modified by John L. Chmielewski on Sat Aug 12, 2006
#   - Fixed "-c cidlog" option, Fixed alias expression line to handle
#     '*' for a name or number, fixed alias checking in if statements
# Modified by John L. Chmielewski on Sun Feb 13, 2011
#   - changed the -a option to -A and the -c option to -C
#   - removed unused -l option
# Modified by John L. Chmielewski on Sat Jun 11, 2011
#   - fixed regex and changed join and split character from ':' to '"'
#   - changed regex for getting the number to include special characters

use Getopt::Std;

$ALIAS = "/etc/ncid/ncidd.alias";
$CIDLOG = "/var/log/cidcall.log";

getopts('A:C:') ||
    die "Usage: cidupdate [-A aliasfile] [-C cidlog] [newcidlog]\n";

($alias = $opt_A) || ($alias = $ALIAS);
($cidlog = $opt_C) || ($cidlog = $CIDLOG);
($newcidlog = shift) || ($newcidlog = sprintf("%s.new", $cidlog));

open(ALIASFILE, $alias) || die "Could not open $alias\n";
open(CIDLOG, $cidlog) || die "Could not open $cidlog\n";
open(NEWCIDLOG, ">$newcidlog") || die "Could not open $newcidlog\n";

while (<ALIASFILE>) {
    if (/^alias/) {
        chomp;
        ($type, $from, $to, $value) = /^.*alias\s+(\w+)\s+"*([^"]+)"*\s+=\s+"*([^"]+)"*\s+if\s+"*([^"]+)"*$/;
        if ($value == "") {
        ($type, $from, $to) = /^.*alias\s+(\w+)\s+"*([^"]+)"*\s+=\s+"*([^"]+)"*(.*)$/;
        }
        $alias = join('"', ($type, $from, $to, $value));
        push(@aliases, $alias);
    }
}

#CID: *DATE*11242002*TIME*2112*LINE*1*NMBR*9549142285*MESG*NONE*NAME*Cell*

while (<CIDLOG>) {
    if (/CID|EXTRA/) {
        ($date, $time, $number, $mesg, $name) = 
            /.*DATE.(\d+).*TIME.(\d+).*NU*MBE*R.(.*)\*MESG.(\w+).*NAME.(.*)\*+$/;
        ($line) = /.*LINE.([-\w\s]+).*/;

    foreach $alias (@aliases) {
        ($type, $from, $to, $value) = split(/"/, $alias);
        if ($value ne "") {
            if ($type eq "NAME" && $number eq $value) {$name = $to;}
            if ($type eq "NMBR" && $name eq $value) {$number = $to;}
        } else {
            if ($type eq "NAME" && $name eq $from) {$name = $to;}
            if ($type eq "NMBR" && $number eq $from) {$number = $to;}
        }
    }
    printf(NEWCIDLOG
        "CID: *DATE*%s*TIME*%s*LINE*%s*NMBR*%s*MESG*%s*NAME*%s*\n",
        $date, $time, $line, $number, $mesg, $name);
    } else {
        printf(NEWCIDLOG);
    }
}
print "diff $cidlog $newcidlog\n";
exec('diff', $cidlog, $newcidlog);

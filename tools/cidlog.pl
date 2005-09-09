#!/usr/bin/perl

# cidlog - caller ID report

# Created by John L. Chmielewski on Fri Sep 14, 2001
# modified by jlc on Tue Jul 30, 2002
#   modified to look for lines that start with CID or EXTRA
#   modified to locate NUMBER or NMBR field
#   modified $date to work with MMDD and MMDDYYYY data
# modified by Aron Green on Sun Nov 24, 2002
#   fixed regular expression to handle "'" in the name field
# modified by jlc on Mon Apr 7, 2003
#   fixed regular expression to handle 11 digit numbers
# modified by jlc on Fri Aug 12, 2005
#   modified to display the new "LINE" filed
# modified by jlc on Mon Aug 29, 2005
#   fixed regular expression for obtaining LINE fielf
#   changed -r option to print all lines in the logfile
#   add -m option for printing MSG lines

use Getopt::Std;

getopts('mr') || die "Usage: cidlog [-m][-r] [logfile]\n";

($log = shift) || ($log = "/var/log/cidcall.log");

format STDOUT =
@<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @<<<<<<<<<< @<<<<< @<<<
$name,           $number,       $date,      $time, $line
.

open(LOGFILE, $log) || die "Could not open $log\n";

while (<LOGFILE>) {
    if ($opt_r) {print; next;}
    if ($opt_m) {if (/MSG:/) {print;} next;}
    if (/CID|EXTRA/) {
        ($date, $time, $number, $name) = 
            /.*DATE\*(\d+).*TIME\*(\d+).*NU*MBE*R\*([-\w\s]+).*NAME\*(.*)\*+$/;
        ($line) = /.*\*LINE\*([-\w\s]+).*/;
        $line = "<$line>";
        $line =~ s/<-*>//;
        $date =~ s/(\d\d)(\d\d)(\d\d\d\d)*/$1\/$2\/$3/;
        $date =~ s/\/$//;
        $time =~ s/(\d\d)(\d\d)/$1:$2/;
        $number =~ s/\d?(\d\d\d)(\d\d\d)(\d\d\d\d)/($1)$2-$3/;
        write;
    }
}

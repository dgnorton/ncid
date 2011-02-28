#!/usr/bin/perl

# cidcall - caller ID report

# Created by John L. Chmielewski on Fri Sep 14, 2001
# modified by jlc on Tue Jul 30, 2002
#    - modified to look for lines that start with CID or EXTRA
#    - modified to locate NUMBER or NMBR field
#    - modified $date to work with MMDD and MMDDYYYY data
# modified by Aron Green on Sun Nov 24, 2002
#    fixed regular expression to handle "'" in the name field
# modified by jlc on Mon Apr 7, 2003
#    fixed regular expression to handle 11 digit numbers
# modified by jlc on Fri Aug 12, 2005
#    modified to display the new "LINE" filed
# modified by jlc on Fri Apr 14, 2006
#    added -m option, modified raw option to print all lines, changed name
# modified by jlc on Wed Mar 28, 2007
#    - modified regular expressions to look for * with key word
# modified by jlc on Sun May 16, 2010
#    - removed <> from enclosing line label,
#    - changed number from (xxx)xxx-xxxx to xxx-xxx-xxxx
# modified by jlc on Sun Feb 13, 2011
#    - added -cho options
#    - the -chmo options can be combined
#    - formats and prints the entire call log file by default
#    - prints the line labels when formatted

use Getopt::Std;

getopts('chmor') || die "Usage: cidcall [-r | -chom] [cidlog]\n";

($cidlog = shift) || ($cidlog = "/var/log/cidcall.log");

format STDOUT =
@<<< @<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @<<<<<<<<<< @<<<<< @<<<<<<<<<
$label, $name,           $number,       $date,      $time, $line
.

open(CIDLOG, $cidlog) || die "Could not open $cidlog\n";

while (<CIDLOG>) {
  if (!$opt_r && !$opt_c && !$opt_h && !$opt_m && !$opt_o) {&parseLine;}
  elsif ($opt_r) {print;}
  else {
    if ($opt_c) { if (/CID:/) {&parseLine;} }
    if ($opt_h) { if (/HUP:/) {&parseLine;} }
    if ($opt_m) { if (/MSG:/) {print;} }
    if ($opt_o) { if (/OUT:/) {&parseLine;} }
  }
}

sub parseLine {
    ($label, $date, $time, $number, $name) = 
     /(\w+:).*\*DATE.(\d+).*\*TIME.(\d+).*\*NU*MBE*R.([-\w\s]+).*\*NAME.(.*)\*+$/;
    ($line) = /.*\*LINE.([-\w\d]+).*/;
    $line =~ s/-*//;
    $date =~ s/(\d\d)(\d\d)(\d\d\d\d)*/$1\/$2\/$3/;
    $date =~ s/\/$//;
    $time =~ s/(\d\d)(\d\d)/$1:$2/;
    $number =~ s/\d?(\d\d\d)(\d\d\d)(\d\d\d\d)/$1-$2-$3/;
     write;
}

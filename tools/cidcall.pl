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
# modified by jlc on Sat Jan 19, 2013
#    - added -e option and fixed if statement for no options
#    - changed format to handle END start and end call times
#   - improved code, addcwedd long options, and added pod documentation

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case_always);

my ($cid, $end, $hup, $msg, $out, $help, $man, $raw);
my ($label, $date, $line, $name, $number);
my ($stime, $etime);
my $cidlog;

Getopt::Long::Configure ("bundling");
my ($result) = GetOptions(
    "CID|C"  => \$cid,
    "END|E"  => \$end,
    "HUP|H"  => \$hup,
    "MSG|M"  => \$msg,
    "OUT|O"  => \$out,
    "help|h" => \$help,
    "man|m"  => \$man,
    "raw|r"  => \$raw
 ) || pod2usage(2);
pod2usage(-verbose => 1, -exitval => 0) if $help;
pod2usage(-verbose => 2, -exitval => 0) if $man;

($cidlog = shift) || ($cidlog = "/var/log/cidcall.log");

format STDOUT =
@<<< @<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @<<<<<<<< @<<<<<<<<<< @<<<<<<< @<<<<<<<
$label, $name,           $number,       $line,    $date,    $stime,  $etime
.

open(CIDLOG, $cidlog) || die "Could not open $cidlog\n";

while (<CIDLOG>) {
  if (!$raw && !$cid && !$end && !$hup && !$msg && !$out) {
    if (/CID:|HUP:|OUT:|END:/) {&parseLine;}
    if (/MSG:/) {print;}
  }
  elsif ($raw) {print;}
  else {
    if ($cid) { if (/CID:/) {&parseLine;} }
    if ($end) { if (/END:/) {&parseLine;} }
    if ($hup) { if (/HUP:/) {&parseLine;} }
    if ($msg) { if (/MSG:/) {print;} }
    if ($out) { if (/OUT:/) {&parseLine;} }
  }
}

sub parseLine {
    ($label, $date, $stime, $number, $name) = 
     /(\w+:).*\*DATE.(\d+).*\*TIME.(\d+).*\*NU*MBE*R.([-\w\s]+).*\*NAME.(.*)\*+$/;
    ($line) = /.*\*LINE.([-\w\d]+).*/;
    $line =~ s/-*//;
    $date =~ s/(\d\d)(\d\d)(\d\d\d\d)*/$1\/$2\/$3/;
    $date =~ s/\/$//;
    $stime =~ s/(\d\d)(\d\d)/$1:$2/;
    $number =~ s/\d?(\d\d\d)(\d\d\d)(\d\d\d\d)/$1-$2-$3/;
    $etime = "";
    if (/END:/) {
        ($stime, $etime) =
         /.*SCALL.\d+\/\d+\/\d+ (\d\d:\d\d:\d\d).*ECALL.\d+\/\d+\/\d+ (\d\d:\d\d:\d\d).*$/;
    }
     write;
}

=head1 NAME

cidcall - view calls, hangups, messages, and end of calls in the NCID call file

=head1 SYNOPSIS

cidcall [--help|-h]
        [--man|-m]
        [--raw|-r]
        [--CID|-C]
        [--END|-E]
        [--HUP|-P]
        [--MSG|-M]
        [--OUT|-O]
        [cidlog]

=head1 DESCRIPTION

The cidcall script displays the cidcall.log file.

=head2 Options

=over 7

=item -h, --help

Prints the help message and exits

=item -m, --man

Prints the manual page and exits

=item -r, --raw

Display the raw call file.

Default: Format the call file

=item -C, --CID

Display CID lines (incoming calls) in the call file.

Default: Display all line types.

=item -E, --END

Display END lines (gateway end of call) in the call file.

Default: Display all line types.

=item -H, --HUP

Display HUP lines (terminated calls) in the call file.

Default: Display all line types.

=item -M, --MSG

Display MSG lines (messages) in the call file.

Default: Display all line types.

=item -O, --OUT

Display OUT lines (outgoing calls) in the call file.

Default: Display all line types.

=back

=head2 Arguments

=over 7

=item cidlog

The NCID call file.

Default: /var/log/cidcall.log

=back

=head1 SEE ALSO

ncidd.conf.5,
ncidd.alias.5,
ncidd.blacklist.5,
cidalias.1,
cidupdate.1

=cut

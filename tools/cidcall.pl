#!/usr/bin/perl

# cidcall - caller ID report

# Created by John L. Chmielewski on Fri Sep 14, 2001
#
# Copyright (c) 2001-2014 by
#   John L. Chmielewski <jlc@users.sourceforge.net>
#   Aron Green

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case_always);

my ($cid, $end, $hup, $msg, $out, $pid, $not, $help, $man, $raw);
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
    "PID|P"  => \$pid,
    "NOT|N"  => \$not,
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
  if (!$raw && !$cid && !$end && !$hup && !$msg && !$out && !$pid && !$not) {
    if (/CID:|HUP:|OUT:|PID:/) {&parseLine;}
  }
  elsif ($raw) {print;}
  else {
    if ($cid) { if (/CID:/) {&parseLine;} }
    if ($end) { if (/END:/) {&parseLine;} }
    if ($hup) { if (/HUP:/) {&parseLine;} }
    if ($msg) { if (/MSG:/) {print;} }
    if ($not) { if (/NOT:/) {print;} }
    if ($out) { if (/OUT:/) {&parseLine;} }
    if ($out) { if (/PID:/) {&parseLine;} }
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

Default: Display CID, HUP, and OUT lines.

=item -E, --END

Display END lines (gateway end of call) in the call file.

Default: Display CID, HUP, OUT, and PID lines.

=item -H, --HUP

Display HUP lines (terminated calls) in the call file.

Default: Display CID, HUP, OUT, and PID lines.

=item -M, --MSG

Display MSG lines (messages) in the call file.

Default: Display CID, HUP, OUT, and PID lines.

=item -N, --NOT

Display NOT lines (smart phone note (message)) in the call file.

Default: Display CID, HUP, OUT, and PID lines.

=item -O, --OUT

Display OUT lines (outgoing calls) in the call file.

Default: Display CID, HUP, OUT, and PID lines.

=item -P, --PID

Display PID lines (smart phone Caller ID) in the call file.

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

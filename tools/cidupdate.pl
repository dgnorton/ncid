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
# modified by jlc on Sat Jan 19, 2013
#   - improved code, addcwedd long options, and added pod documentation

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case_always);

my ($alias, $cidlog, $help, $man);
my $newcidlog;
my @aliases;
my ($type, $from, $to, $value);
my ($date, $time, $line, $number, $mesg, $name);

my $ALIAS = "/etc/ncid/ncidd.alias";
my $CIDLOG = "/var/log/cidcall.log";

Getopt::Long::Configure ("bundling");
my ($result) = GetOptions(
    "help|h"        => \$help,
    "man|m"         => \$man,
    "aliasfile|a=s" => \$alias,
    "cidlog|c=s"    => \$cidlog
 ) || pod2usage(2);
pod2usage(-verbose => 1, -exitval => 0) if $help;
pod2usage(-verbose => 2, -exitval => 0) if $man;

$alias = $ALIAS if !$alias;
$cidlog = $CIDLOG if !$cidlog;
($newcidlog = shift) || ($newcidlog = sprintf("%s.new", $cidlog));

open(ALIASFILE, $alias) || die "Could not open $alias\n";
open(CIDLOG, $cidlog) || die "Could not open $cidlog\n";
open(NEWCIDLOG, ">$newcidlog") || die "Could not open $newcidlog\n";

while (<ALIASFILE>) {
    if (/^alias/) {
        chomp;
        ($type, $from, $to, $value) = /^.*alias\s+(\w+)\s+"*([^"]+)"*\s+=\s+"*([^"]+)"*\s+if\s+"*([^"]+)"*$/;
        if ($value eq "") {
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

=head1 NAME

cidupdate -  update aliases in the NCID call file

=head1 SYNOPSIS

cidupdate [--help|-h]
          [--man|-m]
          [--aliasfile|-a <aliasfile>]
          [--cidlog|-c <cidlog>]
          [newcidlog]

=head1 DESCRIPTION

The cidupdate script updates the cidcall.log file using the aliases
found in the ncidd.alias file.

=head2 Options

=over 7

=item -h, --help

Prints the help message and exits

=item -m, --man

Prints the manual page and exits

=item -a <aliasfile>, --aliasfile <aliasfile>

Set the alias file to <aliasfile>

Default: /etc/ncid/ncidd.alias

=item -c <logfile>, --cidlog <logfile>

Set the call file to <logfile>

Default: /var/log/cidcall.log

=back

=head2 Arguments

=over 7

=item newcidlog <newlogname>

Set the new cidlog file to <newlogname>

Default: /var/log/cidcall.new

=back

=head1 SEE ALSO

ncidd.conf.5,
ncidd.alias.5,
ncidd.blacklist.5,
cidalias.1,
cidcall.1

=cut

#!/usr/bin/perl -w

# Created by Aron Green on Sun Nov 24, 2002
#
# Copyright (c) 2001-2014 by
#   Aron Green
#   John L. Chmielewski <jlc@users.sourceforge.net>
#   Steve Limkemann

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case_always);

my ($help, $man, $raw);
my ($alias, $blacklist, $whitelist, $name, $number, $from, $to);
my (@multiples, $line, $nbr, $index, $action, $lastAction);
my %listed = (bl => 0, wl => 0);
my $blwl = "bl";
my ($ret, $listfile, @list_files);

my $ALIAS = "/etc/ncid/ncidd.alias";

Getopt::Long::Configure ("bundling");
my ($result) = GetOptions(
    "help|h" => \$help,
    "man|m"  => \$man,
    "raw|r"  => \$raw
 ) || pod2usage(2);
pod2usage(-verbose => 1, -exitval => 0) if $help;
pod2usage(-verbose => 2, -exitval => 0) if $man;

($alias = shift) || ($alias = $ALIAS);
($blacklist = $alias) =~ s/(alias)$/blacklist/;
($whitelist = $alias) =~ s/(alias)$/whitelist/;

@list_files = ($blacklist, $whitelist);
foreach my $file (@list_files)
{
    $listfile = $file;
    &doList;
    $blwl = "wl";
}

open(ALIASFILE, $alias) || die "Could not open $alias\n";

while (<ALIASFILE>) {
    next if (/^\s*#/ || /^$/);
    $line = $number = $name = $nbr = undef;
    if (/^\s*alias/) {
        if ($raw) {print;}
        elsif (/alias NAME/) {
            if (/\s+if\s+\d+\s*$/) {
                # alias NAME __ = "___" if (phone number)
                ($name, $number) = /.*=\s+"?([^"]*)"?\s+if\s+(\d+)/;
                ($nbr = $number) =~ s/(\d{3})(\d{3})(\d{4})\s*$/($1)$2-$3/;
                $line = "If number is $nbr, Change name to: $name\n";

            } elsif (/\s+if\s+\^\d+\s*$/) {
                # alias NAME __ = "___" if ^(partial phone number)
                ($name, $number) = /.*=\s+"?([^"]*)"?\s+if\s+\^(\d+)/;
                ($nbr = $number) .= '_' x (10 - length $number);
                 $nbr=~ s/(.{3})(.{3})(.{4})\s*$/($1)$2-$3/;
                $line = "If number is $nbr, Change name to: $name\n";

            } elsif (/\s+if\s+\S+\s*$/) {
                # alias NAME __ = "___" if ____
                ($name, $number) = /.*=\s+"?([^"]*)"?\s+if\s+(\S+)/;
                $number .= ' ' x (13 - length $number);
                $line = "If number is $number, Change name to: $name\n";

            } else {
                ($from, $to) = /.*NAME\s+"?([^"]*)"?\s+=\s+"?([^"]*)"?/;
                chomp $to;
                $line = "Change name from: $from To: $to\n";
                $name = $to;
            }
        } elsif (/alias NMBR/) {
            if (/\s+if\s+/) {
                ($number, $name) = /.*=\s+(\d+)\s+if\s+"?([^"]*)"?/;
                ($nbr = $number) =~ s/(\d{3})(\d{3})(\d{4})\s*$/($1)$2-$3/;
                $line =  "If name is $name, Change number to: $nbr\n";
            } else {
                ($from, $to) = /.*NMBR\s+(\d+)\s+=\s+"?([^"]*)"?/;
                $number = $to;
                $from =~ s/(\d{3})(\d{3})(\d{4})\s*$/($1)$2-$3/;
                if ($to =~ /^\d+$/) {
                    $to =~ s/(\d{3})(\d{3})(\d{4})/($1)$2-$3/;
                }
                $line = "Change number from: $from To: $to\n";
            }
        } elsif (/alias LINE/) {
                ($from, $to) = /.*LINE\s+"?([^"]*)"?\s+=\s+"?([^"]*)"?/;
                chomp $to;
                $line = "Change line from: $from To: $to\n";
                $name = $to;
        } else {
            ($from, $to) = /\s+"?([^"]*)"?\s+=\s+"?([^"]*)"?/;
            chomp $to;
            $line = "Change: $from To: $to\n";
            $name = $to;
        }
        if (defined $name) {
            if (!defined $ret && ($listed{$name}{"bl"} || $listed{$name}{"wl"})) {
             print "\n"
            };
            undef $ret;
            print "Alias:     $line";
            if ($listed{$name}{"bl"}) { print "BlackList: $name\n" }
            if ($listed{$name}{"wl"}) { print "WhiteList: $name\n" }
            if ($listed{$name}{"bl"} || $listed{$name}{"wl"}) {
                print "\n";
                $ret = 1;
            };
        }
    }
}

sub doList {

    if (not $raw and open (LISTFILE, $listfile)) {
        while (<LISTFILE>) {
        next if (/^\s*#/ || /^\s*$/);
            chomp;
            s /\s*#.*//;
            if (/^^?[^'"]/) {
                @multiples = split /\s+/, $_;
                foreach my $item (@multiples) {
                    $listed{$item}{$blwl} = 1;
                }
            } else {
                $_ = substr $_, 1, -1;
                $listed{$_}{$blwl} = 1;
            }
        }
    }
    close(LISTFILE);
}

=head1 NAME

cidalias - view alias definitions in the NCID alias and blacklist files

=head1 SYNOPSIS

cidalias [--help|-h]
         [--man|-m]
         [--raw|-r]
         [aliasfile] 

=head1 DESCRIPTION

The cidalias script displays aliases in the alias file.  If there are
any aliases in the blacklist and whitelist files, it will display the
alias names.

The blacklist and whitelist files must be in the same directory as the
alias file.  If the location of the alias file is changed on the command
line, the the path to the alias file is also used as the path to the
blacklist and whitelist files.

=head2 Options

=over 7

=item -h, --help

Prints the help message and exits

=item -m, --man

Prints the manual page and exits

=item -r, --raw

Display the raw alias file.

Default: Format the alias file

=back

=head2 Arguments

=over 7

=item aliasfile

The NCID alias file.  The path given for the alias file is
also applied to the blacklist and whitelist files.

=over 7

=item Defaults:

/etc/ncid/ncidd.alias,
/etc/ncid/ncidd.blacklist,
/etc/ncid/ncidd.whitelist

=back

=back

=head1 SEE ALSO

ncidd.conf.5,
ncidd.alias.5,
ncidd.blacklist.5,
ncidd.whitelist.5,
cidcall.1,
cidupdate.1

=cut

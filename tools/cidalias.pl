#!/usr/bin/perl -w

# Created by Aron Green on Sun Nov 24, 2002
# based on cidlog
# Cleanup by John L. Chmielewski on Tue Nov 26, 2002
# modified by jlc on Tue Apr 8, 2003
#    - modified to format output
#    - added the raw ('r) option
# modified by jlc on Sat May 21, 2005
#   - changed config to alias, and CONFIGFILE to ALIASFILE
#   - changed value of $alias
# modified by Steve Limkemann on Sat Dec 1, 2012
#   - improved code, improved display, and added blacklist feature
# modified by jlc on Sat Jan 19, 2013
#   - improved code, added long options, and added pod documentation

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case_always);

my ($help, $man, $raw);
my ($alias, $blacklist, $name, $number, $from, $to);
my (@multiples, %blacklisted, $line, $nbr, $index, $action, $lastAction);

Getopt::Long::Configure ("bundling");
my ($result) = GetOptions(
    "help|h" => \$help,
    "man|m"  => \$man,
    "raw|r"  => \$raw
 ) || pod2usage(2);
pod2usage(-verbose => 1, -exitval => 0) if $help;
pod2usage(-verbose => 2, -exitval => 0) if $man;

($alias = shift) || ($alias = "/etc/ncid/ncidd.alias");
($blacklist = $alias) =~ s/(alias)$/blacklist/;


if (not $raw and open (BLACKFILE, $blacklist)) {
    while (<BLACKFILE>) {
        next if /^#/;
        chomp;
        next if $_ eq  '';
        s /\s*#.*//;
        if (/^^?[^'"]/) {
            @multiples = split /\s+/, $_;
            foreach my $item (@multiples) {
                $blacklisted{$item} = ($item =~ s/^\^// ? 2 : 1);
            }
        } else {
            $_ = substr $_, 1, -1;
            $blacklisted{$_} = s/^\^// ? 2 : 1;
        }
    }
}

open(ALIASFILE, $alias) || die "Could not open $alias\n";

while (<ALIASFILE>) {
    $line = $number = $name = $nbr = undef;
    if (/^\s*alias/) {
        if ($raw) {print;}
        elsif (/NAME/) {

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
        } elsif (/NMBR/) {
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
        } else {
            ($from, $to) = /alias\s+"?([^"]*)"?\s+=\s+"?([^"]*)"?/;
            chomp $to;
            $number = $to;
            $from =~ s/\d?(\d\d\d)(\d\d\d)(\d\d\d\d)/($1)$2-$3/;
            $to =~ s/\d?(\d\d\d)(\d\d\d)(\d\d\d\d)/($1)$2-$3/;
            $line = "Change: $from To: $to\n";
        }
    }
    next unless $line;
    if (defined $name and exists $blacklisted{$name}) {
        $action = 'Hangup';
    } elsif (defined $number and exists $blacklisted{$number}) {
        $action = 'Hangup';
    } else {
        $action = 'Alias ';
        foreach my $key (keys %blacklisted) {
            $index = defined $name ? index $name, $key : -1;
            $index = index $number, $key if $index == -1 and defined $number;
            next if $index == -1;
            next if $blacklisted{$key} == 2 && $index;
            $action = 'Hangup';
            last;
        }
    }
    print "\n" if defined $lastAction and $action ne $lastAction;
    print "$action $line";
    $lastAction = $action;
}

=head1 NAME

cidalias - view alias definitions in the NCID alias and blacklist files

=head1 SYNOPSIS

cidalias [--help|-h]
         [--man|-m]
         [--raw|-r]
         [aliasfile] 

=head1 DESCRIPTION

The cidalias script displays aliases in the alias file and in the
blacklist file.

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

The NCID alias file.

Default: /etc/ncid/ncidd.alias & /etc/ncid/ncidd.blacklist

=back

=head1 SEE ALSO

ncidd.conf.5,
ncidd.alias.5,
ncidd.blacklist.5,
ncidd.whitelist.5,
cidcall.1,
cidupdate.1

=cut

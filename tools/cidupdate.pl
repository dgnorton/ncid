#!/usr/bin/perl

# cidupdate - update Caller ID call log file or files using the
# current alias file.
#
# Copyright (c) 2002-2013 by
#   Aron Green,
#   John L. Chmielewski <jlc@users.sourceforge.net> and
#   Steve Limkemann
#
# Created by Aron Green on Mon Nov 25, 2002
#   - Based on cidlog and cidalias
# Cleanup by John L. Chmielewski on Tue Nov 26, 2002
# Modified by John L. Chmielewski on Sat Aug 13, 2005
#   - Changed from using config file to alias file
# Modified by John L. Chmielewski on Fri Apr 14, 2006
#   - Changed name from cidlogupd to cidupdate, updated variable names
# Modified by John L. Chmielewski on Sun Feb 13, 2011
#   - Changed the -a option to -A and the -c option to -C
#   - Removed unused -l option
# modified by John L. Chmielewski on Sat Jan 19, 2013
#   - Improved code, added long options, and added pod documentation
# modified by Steve Limkemann on Wed May 29, 2013
#   - Changed from outputting the difference between the old and
#     updated CID call logs to outputting a report of the changes and
#     asking the user if the new log should be kept or discarded.  If
#     kept, the new log has the same modification timestamp as the
#     old log.
#   - Changed from doing linear searches of a list based on the alias
#     file for each CID call log entry to using a hash table and an
#     array for leading digit number matches.
#   - Modified to work either from the command line or when executed by
#     the NCID server on behalf of the user via the NCID client.
#   - Added the ability to update all of the CID call logs.

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case_always);

my ($alias, $cidlog, $help, $man);
my $newcidlog;
my (@aliases, %hash);
my ($type, $from, $to, $value, $mod_time, $logType);
my ($date, $time, $line, $number, $mesg, $name, @log_files);
my ($partialNumber, $length, $newValue, $multiple, $found);

my $ALIAS = "/etc/ncid/ncidd.alias";
my $CIDLOG = "/var/log/cidcall.log";

Getopt::Long::Configure ("bundling");
my ($result) = GetOptions(
    'help|h'        => \$help,
    'man|m'         => \$man,
    'aliasfile|a=s' => \$alias,
    'cidlog|c=s'    => \$cidlog,
    'multi'         => \$multiple
 ) || pod2usage(2);
pod2usage(-verbose => 1, -exitval => 0) if $help;
pod2usage(-verbose => 2, -exitval => 0) if $man;

$alias = $ALIAS if !$alias;
$cidlog = $CIDLOG if !$cidlog;

@log_files = glob "$cidlog*";
@log_files = grep {/^$cidlog\.?\d*$/o} @log_files;
$#log_files = 0 unless $multiple;

open(ALIASFILE, $alias) || die "Could not open $alias: $!\n";

while (<ALIASFILE>) {
    next unless /^alias/;
    chomp;
    s/\s*#.*$//;
    if (/^alias\s+(\w+)\s+"*([^"]+)"*\s+=\s+"*([^"]+)"*\s+if\s+"*([^"]+)"*$/) {
        ($type, $from, $to, $value) = ($1, $2, $3, $4);
    } elsif (/^alias\s+(\w+)\s+"*([^"]+)"*\s+=\s+"*([^"]+)"*(.*)$/) {
        ($type, $from, $to, $value) = ($1, $2, $3, '');
    } elsif (/^alias\s+"*([^"]+)"*\s+=\s+"*([^"]+)"*(.*)$/) {
        ($type, $from, $to, $value) = ('both', $1, $2, '');
    } else {
        print "Unknown: $_\n";
        next;
    }
    if ($value ne '') {
        if ((substr $value, 0, 1) eq '^') {
            $value = substr $value, 1;
            push @aliases, ([$value, length $value, $type, $to]);
        } else {
            $hash{$value} = [$type, $to];
        }
    } else {
        if ((substr $value, 0, 1) eq '^') {
            $from = substr $from, 1;
            push @aliases, ([$from, length $from, $type, $to]);
        } else {
            $hash{$from} = [$type, $to];
        }
    }
}

#CID: *DATE*11242002*TIME*2112*LINE*1*NMBR*9549142285*MESG*NONE*NAME*Cell*

foreach $cidlog (@log_files) {
    $newcidlog = "$cidlog.new";
    open(CIDLOG, $cidlog) || die "Could not open $cidlog: $!\n";
    open(NEWCIDLOG, ">$newcidlog") || die "Could not open $newcidlog: $!\n";

    while (<CIDLOG>) {
        if (/CID|EXTRA|HUP/) {
            ($logType, $date, $time, $line, $number, $mesg, $name) =
                    (split /\*/) [0, 2, 4, 6, 8, 10, 12];

            if ($number eq 'RING') {
                printf(NEWCIDLOG);
                next;
            }
            if (exists $hash{$number}) {
                if ($hash{$number}[0] eq 'NAME') {
                    if ($hash{$number}[1] ne $name) {
                        record_change ("1 Changed $name to $hash{$number}[1] for $number", $cidlog);
                        $name = $hash{$number}[1];
                    }
                } else {
                    if ($hash{$number}[1] ne $number) {
                        record_change ("2 Changed $number to $hash{$number}[1]", $cidlog);
                        $name = $hash{$number}[1];
                    }
                }
            } elsif (exists $hash{$name}) {
                if ($hash{$name}[0] eq 'NAME') {
                    if ($hash{$name}[1] ne $name) {
                        record_change ("3 Changed $name to $hash{$name}[1]", $cidlog);
                        $name = $hash{$name}[1];
                    }
                } else {
                    if ($hash{$name}[1] ne $number) {
                        record_change ("4 Changed $number to $hash{$name}[1]", $cidlog);
                        $number = $hash{$name}[1];
                    }
                }
            } else {
                $found = 0;
                foreach $alias (@aliases) {
                    ($partialNumber, $length, $type, $newValue) = @$alias;
                    if (substr ($number, 0, $length) eq $partialNumber) {
                        $found = 1;
                        if ($name ne $newValue) {
                            record_change ("1 Changed $name to $newValue for $number", $cidlog);
                            $name = $newValue;
                            last;
                        }
                    }
                }
                if (not $found and $name ne 'NO NAME') {
                    record_change ("5 Changed $name to NO NAME for $number", $cidlog);
                    $name = 'NO NAME';
                }
            }
            printf(NEWCIDLOG
                "$logType*DATE*$date*TIME*$time*LINE*$line*NMBR*$number*MESG*$mesg*NAME*$name*\n");
        } else {
            printf(NEWCIDLOG);
        }
    }
    no_change ($cidlog);
    $mod_time = (stat CIDLOG)[9];
    close CIDLOG;
    close NEWCIDLOG;
    utime $mod_time, $mod_time, $newcidlog;
}
report_changes ();
if (-t STDIN) {
    print "\nreject or accept changes? (R/a): ";
    my $resp = <STDIN>;
    chomp $resp;
    $resp = 'r' unless $resp;
    if (substr ((lc $resp), 0, 1) eq 'r') {
        remove_new ();
        print "\nUpdates to CID call logs have been discarded\n\n";
    } else {
        use_new ();
        print "\nChanges have been made to the CID log files\n\n";
    }
}

{
    my (%files, @files, %changes, @changes);

    sub record_change {
        my ($key, $file) = @_;

        push @files, $file unless exists $files{$file};
        $files{$file} ++;
        push @changes, $key unless exists $changes{$key};
        $changes{$key}++;
    }

    sub report_changes {
        my ($temp1, $temp2);

        print "\n" if -t STDIN;
        foreach (@files) {
            ($temp1, $temp2) = $files{$_} == 1 ? ('was', ''): ('were', 's');
            $files{$_} = 'no' if $files{$_} == 0;
            print "There $temp1 $files{$_} change$temp2 to $_\n";
        }
        print "\n";
        foreach (@changes) {
            $temp1 = $changes{$_} == 1 ? '': 's';
            print "$_ $changes{$_} time$temp1\n";
        }
    }

    sub no_change {
        my $file = shift;

        if (not exists $files{$file}) {
            push @files, $file;
            $files{$file} = 0;
        }
    }

    sub remove_new {

        foreach (@files) {
            unlink "$_.new"
        }
    }

    sub use_new {

        foreach (@files) {
            if (/\.\d+$/) {
                rename "$_.new", $_;
            } elsif (system ("killall -SIGUSR1 ncidd") != 0) {
                rename "$_.new", $_;
            }
        }
    }
}

=head1 NAME

cidupdate -  update aliases in the NCID call file

=head1 SYNOPSIS

cidupdate [--help|-h]
          [--man|-m]
          [--multi]
          [--aliasfile|-a <aliasfile>]
          [--cidlog|-c <cidlog>]

=head1 DESCRIPTION

The cidupdate script updates the current call log file
(cidcall.log) using the entires found in the alias file
(ncidd.alias).  All of the the call log files (cidcall.log,
cidcall.log.1, cidcall.log.2, etc.) are updated instead if
the --multi option is present.


=head2 Options

=over 7

=item -h, --help

Prints the help message and exits

=item -m, --man

Prints the manual page and exits

=item --multi

Updates all of the call log files

=item -a <aliasfile>, --aliasfile <aliasfile>

Set the alias file to <aliasfile>

Default: /etc/ncid/ncidd.alias

=item -c <logfile>, --cidlog <logfile>

Set the call file to <logfile>

Default: /var/log/cidcall.log

=back

=head1 SEE ALSO

ncidd.conf.5,
ncidd.alias.5,
ncidd.blacklist.5,
cidalias.1,
cidcall.1

=cut

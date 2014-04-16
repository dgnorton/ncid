#!/usr/bin/perl

# cidupdate - update Caller ID call log file or files using the
# current alias file.
#
# Created by Aron Green on Mon Nov 25, 2002
#
# Copyright (c) 2002-2014 by
#   Aron Green,
#   John L. Chmielewski <jlc@users.sourceforge.net> and
#   Steve Limkemann
#   Chris Lenderman

use strict;
use warnings;
use Pod::Usage;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case_always);

my (@aliases, $alias, $cidlog, $newcidlog, $changed);
my ($help, $man, $version, $multiple);
my ($type, $from, $to, $value, $mod_time, $logType, $ignore1);
my ($date, $time, $line, $number, $mesg, $name, @log_files);
my ($htype, $scall, $ecall, $ctype);

my $prog = basename($0);
my $VERSION = "(NCID) XxXxX";

my $ALIAS = "/etc/ncid/ncidd.alias";
my $CIDLOG = "/var/log/cidcall.log";

Getopt::Long::Configure ("bundling");
my ($result) = GetOptions(
    'help|h'        => \$help,
    'man|m'         => \$man,
    'aliasfile|a=s' => \$alias,
    'cidlog|c=s'    => \$cidlog,
    'multi'         => \$multiple,
    'ignore1'       => \$ignore1,
    'version|V'     => \$version
 ) || pod2usage(2);
die "$prog $VERSION\n" if $version;
pod2usage(-verbose => 1, -exitval => 0) if $help;
pod2usage(-verbose => 2, -exitval => 0) if $man;

$alias = $ALIAS if !defined $alias;
$cidlog = $CIDLOG if !defined $cidlog;

@log_files = glob "$cidlog*";
die "Could not open $cidlog: $!\n" if $#log_files == -1;

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
        ($type, $from, $to, $value) = ('NMBRNAME', $1, $2, '');
    } else {
        print "Unknown: $_\n";
        next;
    }
    $to =~ s/\s*$//;
    $value =~ s/\s*$//;
    push @aliases, ([$type, $from, $to, $value]);
}

#CID: *DATE*11242002*TIME*2112*LINE*1*NMBR*9549142285*MESG*NONE*NAME*Cell*

foreach $cidlog (@log_files) {
    $newcidlog = "$cidlog.new";
    open(CIDLOG, $cidlog) || die "Could not open $cidlog: $!\n";
    open(NEWCIDLOG, ">$newcidlog") || die "Could not open $newcidlog: $!\n";

    while (<CIDLOG>) {
        if (/^CID|^HUP|^OUT|^PID|^BLKr|^END/) {
            ($logType, $date, $time, $line, $number, $mesg, $name) =
                (split /\*/) [0, 2, 4, 6, 8, 10, 12];
            if (/^END/) {
                ($logType, $htype, $date, $time, $scall, $ecall, $ctype, $line, $number, $name) =
                (split /\*/) [0, 2, 4, 6, 8, 10, 12, 14, 16, 18];
            }


            if ($number eq 'RING') {
                print NEWCIDLOG;
                next;
            }
            $number =~ s/^1// if $ignore1;
            foreach $alias (@aliases) {
                ($type, $from, $to, $value) = @$alias;
                if ($type eq "NAME" && $value) {
                    if (strmatch($value, $number)&& !strmatch($name, $to)) {
                        record_change ("1 Changed \"$name\" to \"$to\" for $number", $cidlog);
                        $name = $to;
                    }
                }
                elsif ($type eq "NAME") {
                    if (strmatch($from, $name)) {
                        record_change ("3 Changed \"$name\" to \"$to\"", $cidlog);
                        $name = $to;
                    }
                }
                if ($type eq "NMBR" && $value) {
                    if (strmatch($value, $name) && !strmatch($number, $to)) {
                        record_change ("2 Changed \"$number\" to \"$to\" for $name", $cidlog);
                        $number = $to;
                    }
                }
                elsif ($type eq "NMBR") {
                    if (strmatch($from, $number)) {
                        record_change ("4 Changed \"$number\" to \"$to\"", $cidlog);
                        $number = $to;
                    }
                }
                if ($type eq "LINE") {
                    if (strmatch($from, $line)) {
                        record_change ("5 Changed \"$line\" to \"$to\"", $cidlog);
                        $line = $to;
                    }
                }
                if ($type eq "NMBRNAME") {
                    if (strmatch($from, $name)) {
                        record_change ("6 Changed \"$name\" to \"$to\"", $cidlog);
                        $name = $to;
                    }
                    if (strmatch($from, $name)) {
                        record_change ("7 Changed \"$number\" to \"$to\"", $cidlog);
                        $number = $to;
                    }
                }
            }
            if ($logType eq "END: ") {
                print NEWCIDLOG
                  "$logType*HTYPE*$htype*DATE*$date*TIME*$time*SCALL*$scall*ECALL*$ecall*CTYPE*$ctype*LINE*$line*NMBR*$number*NAME*$name*\n";
            } else {
                print NEWCIDLOG
                  "$logType*DATE*$date*TIME*$time*LINE*$line*NMBR*$number*MESG*$mesg*NAME*$name*\n";
            }
        } else {
            print NEWCIDLOG;
        }
    }
    no_change ($cidlog);
    $mod_time = (stat CIDLOG)[9];
    close CIDLOG;
    close NEWCIDLOG;
    utime $mod_time, $mod_time, $newcidlog;
}
report_changes ();
if ($changed) {
    if ( -t STDIN) {
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
} else {remove_new ();}

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
            if ($files{$_} == 0) {$files{$_} = 'no';}
            else {$changed = 1;}
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

sub strmatch {
my($find, $string) = @_;

if ($find =~ /^\^/) {
    # handle ^<string> ^*<string> ^*<string>* ^<string>*
    $find =~ s/\^\*/\^/;
    if ($find =~ /\*$/) {$find =~ s/\*$//;}
    else {$find =~ s/$/\$/;}
}else {
    # handle <string> *<string> *<string>* <string>*
    if ($find =~ /^\*/) {$find =~ s/\*//;}
    else {$find =~ s/^/\^/;}
    if ($find =~ /\*$/) {$find =~ s/\*$//;}
    else {$find =~ s/$/\$/;}
}

# some people like an alias with a "?" in it
$find =~ s/([?+.()|{}\[\]-])/\\$1/g;

return ($string =~ /$find/);
}

=head1 NAME

cidupdate -  update aliases in the NCID call file

=head1 SYNOPSIS

cidupdate [--help|-h]
          [--man|-m]
          [--multi]
          [--ignore1]
          [--version|-V]
          [--aliasfile|-a <aliasfile>]
          [--cidlog|-c <cidlog>]

=head1 DESCRIPTION

The cidupdate script updates the current call log file
(cidcall.log) using the entires found in the alias file
(ncidd.alias).

If the "--multi" option is present, the current cidcall.log file
and previous ones are updated.

If the  "--ignore1" option is present, all numbers in the call file
will have the leading 1 ignored, if any, to match an alias number.

=head2 Options

=over 7

=item -h, --help

Prints the help message and exits

=item -m, --man

Prints the manual page and exits

=item --multi

Updates all of the call log files

=item --ignore1

Ignores a leading 1 in a call file number.
Required when the ignore1 server option is set.

=item -V, --version

Displays the version.

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

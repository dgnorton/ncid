#!/usr/bin/perl

# ncidutil - Perform various operations on the alias, black list
#            and white list files.  Designed to be called by the
#            server in response to client requests.

# Created by Steve Limkemann on Sat Mar 23, 2013

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case_always);

my ($filename, $filename1, $type, $action, $item, @tag, $tagged, $where);
my ($found, $finished, $sep, $alias, $comment, $extra);

@tag = ('', '##############', '# Auto Added #', '##############', '');

my ($help, $man);

Getopt::Long::Configure ("bundling");
my ($result) = GetOptions(
    'help|h'        => \$help,
    'man|m'         => \$man
 ) || pod2usage(2);

pod2usage(-verbose => 2, -exitval => 0) if $man;
pod2usage(-verbose => 1, -exitval => 0) if $help || scalar @ARGV < 4;

($filename, $type, $action, $item, $extra) = @ARGV;

$filename1 = "${filename}.update";
open INPUT, '<', "$filename" or die "Unable to open $filename\n$!\n";
open OUTPUT, '>', "$filename1" or die "Unable to open $filename1\n$!\n";

if ((index $item, ' {') > 1) {
    ($item, $alias) = split /\s+\{/, $item;
    $alias =~ s/\}//;
} elsif ($type eq 'Alias') {
    ($item, $alias) = split /\s+/, $item, 2;
} else {
    $alias = '';
}
$action = 'remove' if $action eq 'modify' and $alias eq '';

$item =~ s/-//g if $item =~ /^[0-9\-]+$/;

$tagged = $found = $finished = 0;
while (<INPUT>) {
    if ($finished) {
        print OUTPUT $_;
        next;
    }
    chomp;
    if ($tagged <= $#tag and $_ eq $tag[$tagged]) {
        $tagged++;
    } elsif ($tagged <= $#tag) {
        $tagged = 0;
        $tagged++ if $_ eq $tag[0];
    }
    $comment = index $_, '#';
    $comment = length $_ if $comment < 0;
    if ($comment > 0) {
        $where = index $_, $item;
        if (($where >= 0) and ($where < $comment)) {
            $found = 1;
            if ($action eq 'add') {
                close INPUT;
                close OUTPUT;
                unlink "$filename1";
                die "Entry is already present.\n";
            }
            if ($action eq 'remove') {
                $finished = 1;
                next;
            }
            if ($action eq 'modify') {
                $item = "alias NAME * = \"$alias\" if $item";
                print OUTPUT "$item\n";
                $finished = 1;
                next;
            }
        }
    }
    print OUTPUT "$_\n";
}
close INPUT;
if ($finished) {
    close INPUT;
    close OUTPUT;
    rename "$filename1", "$filename";
    die "Done.\n" 
}
if ($action eq 'add') {
    if ($tagged <= $#tag) {
        foreach (@tag) {
            print OUTPUT "$_\n";
        }
    }
    if ($type eq 'Alias') {
        $item = "alias NAME * = \"$alias\" if $item";
    } else {
        $item = "\"$item\"" if (index $item, ' ') >= 0;
    }
    $item = "$item \t# $extra" if $extra;
    print OUTPUT "$item\n";
    close OUTPUT;
    rename "$filename1", "$filename";
} else {
    close OUTPUT;
    unlink "$filename1";
    die "Entry is not present.\n";
    unlink "$filename1";
}

=head1 NAME

cidupdate -  update aliases in the NCID call file

=head1 SYNOPSIS

ncidutil [options]
         <filename>
         <type>
         <action>
         <item>
         [extra]

=head1 DESCRIPTION

The ncidutil script performs various operations on the alias, black list
and white list files.  Designed to be called by the server in response
to client requests.

=head2 Options

=over 11

=item -h, --help

Prints the help message and exits

=item -m, --man

Prints the manual page and exits

=back

=head2 Arguments

=over 11

=item <filename>

name of the alias, blacklist, or whitelist file

=item <type>

Alias, Blacklist, or Whitelist

=item <action>

add, remove, or modify

=item <item>

the string and string replacement

=item [extra]

optional, but not used

=back

=head1 SEE ALSO

ncidd.conf.5,
ncidd.alias.5,
ncidd.blacklist.5,
cidalias.1,
cidcall.1,
cidupdate.1

=cut

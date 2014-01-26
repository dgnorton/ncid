#!/usr/bin/perl

# ncidutil - Perform various operations on the alias, black list
#            and white list files.  Designed to be called by the
#            server in response to client requests.

# Created by Steve Limkemann on Sat Mar 23, 2013

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case_always);

my ($filename, $filename1, $list, $action, $item, @tag, $tagged, $where);
my ($found, $finished, $sep, $alias, $comment, $extra, $type, $name);
my ($multiple, $blacklist, $whitelist, $filein, $fileout, $nmbr, $quote);
my ($aliasType, $listType, $search, $replace);

my @listTypes = ('Alias', 'Blacklist', 'Whitelist', 'UNKNOWN');
my @aliasNo= ('NOALIAS');
my @aliasTypes = ('NOALIAS', 'NAMEDEP', 'NMBRDEP', 'NMBRNAME', 'NMBRONLY', 'NAMEONLY', 'LINEONLY', 'UNKNOWN');

@tag = ('', '##############', '# Auto Added #', '##############', '');

my ($help, $man);

Getopt::Long::Configure ("bundling");
my ($result) = GetOptions(
    'help|h'        => \$help,
    'man|m'         => \$man,
    'multi=s'        => \$multiple
 ) || pod2usage(2);

pod2usage(-verbose => 2, -exitval => 0) if $man;
pod2usage(-verbose => 1, -exitval => 0) if $help || scalar @ARGV < 4;

($filename, $list, $action, $item, $extra) = @ARGV;

foreach $listType (@listTypes) {
    die "Unknown list type: \"$list\"" if $listType eq 'UNKNOWN';
    last if $listType eq $list;
}

if ($list eq 'Alias') {
    ($nmbr, $alias) = $item =~ /(.*)&&(.*)/;
    ($type, $name) = $extra =~ /(.*)&&(.*)/;

    $nmbr = '' if not defined $nmbr;
    $alias = '' if not defined $alias;
    $type = '' if not defined $type;
    $name = '' if not defined $name;

    $nmbr =~ s/-//g if $nmbr =~ /^[0-9\-]+$/;

    # check for valid alias type
    foreach $aliasType (@aliasTypes) {
        die "Unknown alias type: \"$type\"" if $aliasType eq 'UNKNOWN';
        last if $aliasType eq $type;
    }

    # check for unsupported alias type
    foreach $aliasType (@aliasNo) {
        die "Unsupported alias type: \"$type\"" if $aliasType eq $type;
    }
    if ($type eq 'NAMEDEP' || $type eq 'NMBRONLY') {
       $search = $nmbr;
    } else { $search = $name; }
} else {
    $item =~ s/-//g if $item =~ /^[0-9\-]+$/;
    $search = $item;
}

$filename1 = "${filename}.update";
open INPUT, '<', "$filename" or die "Unable to open $filename\n$!\n";
open OUTPUT, '>', "$filename1" or die "Unable to open $filename1\n$!\n";

$action = 'remove' if $action eq 'modify' and $alias eq '';

if (defined $multiple and ($action eq 'modify' or $action eq 'remove')) {
    ($blacklist, $whitelist) = $multiple =~ /(.*)\s(.*)/;

    foreach $filein ($blacklist, $whitelist) {
        $fileout = "${filein}.update";
        open FILEIN, '<', "$filein" or die "Unable to open $filein$!\n";
        open FILEOUT, '>', "$fileout" or die "Unable to open $fileout\n$!\n";

        while (<FILEIN>) {
            if (/^\s*$/) {print FILEOUT $_; next}
            if (/$name/) {
                $quote = "\"$name\"";
                $name = $quote if /$quote/;
                if ($action eq "modify") {
                s/$name/"$alias"/;
                $name =~ s/"//g;
                print FILEOUT $_;
                }
            } else {print FILEOUT $_}
        }
        close FILEIN;
        close FILEOUT;
    }
}

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
        $where = index $_, $search;
        if (($where >= 0) and ($where < $comment)) {
            $found = 1;
            if ($action eq 'add') {
                close INPUT;
                close OUTPUT;
                unlink "$filename1";
                die "Entry is already present.\n";
            }
            if ($action eq 'modify') {
                $replace = $search;
                if ($type eq 'NAMEDEP') {
                    $_ = "alias NAME * = \"$alias\" if \"$nmbr\"";
                }
                elsif ($type eq 'NMBRDEP') {
                    $_ = "alias NMBR * = \"$alias\" if \"$name\"";
                }
                else {
                    $quote = "\"$replace\"";
                    $replace = $quote if /$quote/;
                    $alias = "\"$alias\"";
                    s/$replace/$alias/;
                }
                print OUTPUT "$_\n";
                $finished = 1;
                next;
            }
            if ($action eq 'remove') {
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
    if (defined $multiple) {
        rename "${blacklist}.update", "$blacklist";
        rename "${whitelist}.update", "$whitelist";
    }
    die "Done.\n" 
}
if ($action eq 'add') {
    if ($tagged <= $#tag) {
        foreach (@tag) {
            print OUTPUT "$_\n";
        }
    }
    if ($list eq 'Alias') {
        $item = "alias NAME * = \"$alias\" if $nmbr" if $type eq "NAMEDEP";
        $item = "alias NMBR * = \"$alias\" if $name" if $type eq "NMBRDEP";
        $item = "alias NAME \"$name\" = \"$alias\"" if $type eq "NAMEONLY";
        $item = "alias NMBR \"$nmbr\" = $alias\"" if $type eq "NMBRONLY";
        $item = "alias \"$name\" = \"$alias\"" if $type eq "NMBRNAME";
        $item = "alias LINE \"$name\" = \"$alias\"" if $type eq "LINEONLY";
    } else {
        $item = "\"$item\"" if (index $item, ' ') >= 0;
        $item = "$item \t# $extra" if $extra;
    }
    print OUTPUT "$item\n";
    close OUTPUT;
    rename "$filename1", "$filename";
    die "Done.\n" 
} else {
    close OUTPUT;
    unlink "$filename1";
    die "Entry is not present.\n";
}

=head1 NAME

cidutil - add or modify entries in the alias, blacklist, and whitelist files

=head1 SYNOPSIS

ncidutil [options] <arguments>

=head1 DESCRIPTION

The ncidutil script is designed to be called by the NCID server in
response to client requests.  Five arguments are required.

The ncidutil script can add, modify or remove a "if" type alias from
the alias file.  If a alias is modified and if the hangup option of
the server is enabled, ncidutil will modify the alias if it is also
in either or both of the blacklist and whitelist files.

If the "--multi" option is given, ncidutil can add or remove entries
from the blacklist and whitelist files.  The entry can be a alias from
the alias file.

=head2 Options

=over 11

=item -h, --help

Prints the help message and exits

=item -m, --man

Prints the manual page and exits

=item --multi "blacklist whitelist"

Updates the blacklist and whitelist files when an alias is modified

=back

=head2 Arguments

=over 11

=item <filename>

Name of the alias, blacklist, or whitelist file.

=item <list>

The type of list: Alias, Blacklist, Whitelist

=item <action>

add, mofify, remove

 for list = Alias: add, remove, or modify
 for list = Blacklist: add or remove
 for list = Whitelist: add or remove

=item <item>

For an alias, type is either "number&&alias" or "number&&".
Quotes are required.

 number is the number in the call file
 alias is from the user

For list = Blacklist or Whitelist, item is either a number or name.

=item <extra>

For list = Alias,  extra is "type&&name".
Quotes are required.

 type is the alias type
 name is the name in the call file

For a blacklist or whitelist file, extra is a comment.

=back

=head1 SEE ALSO

ncidd.conf.5,
ncidd.alias.5,
ncidd.blacklist.5,
ncidd.whitelist.5,
cidalias.1,
cidcall.1,
cidupdate.1

=cut

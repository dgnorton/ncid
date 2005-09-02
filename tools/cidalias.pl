#!/usr/bin/perl

# Created by Aron Green on Sun Nov 24, 2002
# based on cidlog
# Cleanup by John L. Chmielewski on Tue Nov 26, 2002
# modified by jlc on Tue Apr 8, 2003
#    - modified to format output
#    - added the raw ('r) option
# modified by jlc on Sat May 21, 2005
#   - changed config to alias, and CONFIGFILE to ALIASFILE
#   - changed value of $alias

use Getopt::Std;

getopts('r') || die "Usage: cidalias [-r] [aliasfile]\n";

($alias = shift) || ($alias = "/etc/ncid/ncidd.alias");

open(ALIASFILE, $alias) || die "Could not open $alias\n";

while (<ALIASFILE>) {
    if (/^alias/) {
        if ($opt_r) {print;}
        elsif (/NAME/) {
            if (/\s+if\s+/) {
                ($name, $number) = /.*=\s+("?.*"?)\s+if\s+(\d+)/;
                $number =~ s/\d?(\d\d\d)(\d\d\d)(\d\d\d\d)/($1)$2-$3/;
                print "alias: IF NUMBER: $number :CHANGE NAME TO: $name\n";
            } else {
                ($from, $to) = /.*NAME\s+("?.*"?)\s+=\s+("?.*"?)/;
                print "alias: CHANGE NAME: $from :TO: $to\n";
            }
        } elsif (/NMBR/) {
            if (/\s+if\s+/) {
                ($number, $name) = /.*=\s+(\d+)\s+if\s+("?.*"?)/;
                $number =~ s/\d?(\d\d\d)(\d\d\d)(\d\d\d\d)/($1)$2-$3/;
                print "alias: IF NAME: $name :CHANGE NUMBER TO: $number\n";
            } else {
                ($from, $to) = /.*NMBR\s+(\d+)\s+=\s+(\d+)/;
                $from =~ s/\d?(\d\d\d)(\d\d\d)(\d\d\d\d)/($1)$2-$3/;
                $to =~ s/\d?(\d\d\d)(\d\d\d)(\d\d\d\d)/($1)$2-$3/;
                print "alias: CHANGE NUMBER: $from :TO: $to\n";
            }
        } else {
            ($from, $to) = /alias\s+("?.*"?)\s+=\s+("?.*"?)/;
            $from =~ s/\d?(\d\d\d)(\d\d\d)(\d\d\d\d)/($1)$2-$3/;
            $to =~ s/\d?(\d\d\d)(\d\d\d)(\d\d\d\d)/($1)$2-$3/;
            print "alias: CHANGE: $from :TO: $to\n";
        }
    }
}

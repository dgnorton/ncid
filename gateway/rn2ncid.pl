#!/usr/bin/perl

# rn2ncid - Android smart phone app 'Remote Notifier' to NCID gateway

# Copyright (c) 2005-2013
#  by John L. Chmielewski <jlc@users.sourceforge.net>
#     Todd Andrews <tandrews@users.sourceforge.net>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use POSIX qw(strftime);
use Getopt::Long qw(:config no_ignore_case_always);
use File::Basename;
use Config::Simple;
use Pod::Usage;
use IO::Socket::INET;
use IO::Select;

my $prog = basename($0);
my $confile = basename($0, '.pl');
my $VERSION = "(NCID) XxXxX";

my $ConfigDir = "/usr/local/etc/ncid";
my $ConfigFile = "$ConfigDir/$confile.conf";

# Constants
my $CALLTYPE = "PID";

my ($ncidaddr, $ncidport) = ('localhost', 3333);
my ($peerport, $peeraddr);
my $ncidhost = "";
my $ncidsock = undef;
my $ncidline = undef;
my $cellport = 10600;
my $cellPort = undef;
my $cellsock = undef;
my $celldata;
my $defaultTO = 0.2;
my $timeout = $defaultTO;
my $selectTO = undef;
my $delay = 30;
my $Delay = undef;
my $logfile = basename($0, '.pl');
   $logfile = "/var/log/" . $logfile . ".log";
my ($logfileMode, $logfileModeEnglish);
my $logfileAppend;
my $logfileOverwrite;
my $debug;
my $verbose = 1;
my $Verbose = undef;
my ($help, $man, $version);
my $pidfile = "";
my $savepid;
my $pid;
my $test;
my $fileopen;
my $select;
my @ready;
my $rh;
my ($pos, $num, $cnt, $loc, $gotnum);
my $match = undef;
my $addr;
my $cfg;
my $linenum = 1;
my $ignoreTO;
my %config;
my @reject;

my $date = strftime("%m/%d/%Y %H:%M:%S", localtime);

# command line processing
my @save_argv = @ARGV;
Getopt::Long::Configure ("bundling");
my ($result) = GetOptions("ncidhost|n=s" => \$ncidhost,
               "configfile|C=s" => \$ConfigFile,
               "logfile-append|l=s" => \$logfileAppend,
               "logfile-overwrite|L=s" => \$logfileOverwrite,
               "debug|D" => \$debug,
               "delay|d" => \$Delay,
               "help|h" => \$help,
               "man|m" => \$man,
               "verbose|v=i" => \$Verbose,
               "version|V" => \$version,
               "test|t" => \$test,
               "cellport|c=s" => \$cellPort,
               "pidfile|p=s" => \$pidfile
             ) || pod2usage(2);
die "$prog $VERSION\n" if $version;
pod2usage(-verbose => 1, -exitval => 0) if $help;
pod2usage(-verbose => 2, -exitval => 0) if $man;

# reading configuration file after command line processing
# is necessary because the command line can change the
# location of the configuration file
$cfg = new Config::Simple($ConfigFile);
if (defined $cfg) {
    # opened config file
    %config = $cfg->vars();
    $verbose = $config{'default.verbose'};
    $ncidaddr = $config{'default.ncidaddr'};
    $ncidport = $config{'default.ncidport'};
    $delay = $config{'default.delay'};
    $cellport = $cfg->param('default.cellport');
    @reject = $cfg->param('default.reject');
}

if ($test) {
    $debug = 1;
    $verbose = 3;
}

# these command line values override the configuration file values
$ncidport = $1 if $ncidhost =~ s/:(\d+)//;
$ncidaddr = $ncidhost if $ncidhost;
$cellport = $cellPort if $cellPort;
$delay    = $Delay if $Delay;
$verbose = $Verbose if defined $Verbose;

$logfileMode = ">>"; # default to append
$logfileModeEnglish = "Appending to";

if ($logfileAppend and $logfileOverwrite) { $logfileOverwrite = undef; }

if ($logfileOverwrite) {
   $logfileMode = ">";
   $logfileModeEnglish = "Overwriting";
   $logfile = $logfileOverwrite;
} else {
  if ($logfileAppend) {
     $logfile = $logfileAppend;
  }
}
  
if (open(LOGFILE, "$logfileMode$logfile")) {
    LOGFILE->autoflush(1); # make LOGFILE handle 'hot', i.e., no buffering
    $fileopen = 1;
}

logMsg(1, "Started: $date\n");

# log command line and any options on separate lines
my $cl = "Command line: " . $0;
for my $arg (@save_argv) {
    if ( '-' eq substr($arg, 0, 1)) {
        logMsg(1, "$cl\n");
        $cl = "              $arg";
    } else {
        $cl = $cl . " " . $arg;
    }
}
logMsg(1, "$cl\n");

if ($fileopen) {logMsg(1, "Logfile: $logfileModeEnglish $logfile\n");}
else {logMsg(1, "Could not open logfile: $logfile\n");}

if (defined $cfg) {logMsg(1, "Processed config file: $ConfigFile\n");}
else {logMsg(1, "Config file not found: $ConfigFile\n");}

logMsg(1, "Gateway: $prog version $VERSION\n");
logMsg(1, "Verbose level: $verbose\n");
logMsg(1, "Debug mode\n") if ($debug);

if ($test) {logMsg(1, "Test mode\nNot sending data to NCID\n");}

&doPID;

if (@reject) {logMsg(1, "Ignoring messages from: @reject\n");}
else {logMsg(1, "No messages rejected.\n");}

$SIG{'HUP'}  = 'sigHandle';
$SIG{'INT'}  = 'sigHandle';
$SIG{'QUIT'} = 'sigHandle';
$SIG{'TERM'} = 'sigHandle';
$SIG{'PIPE'} = 'sigIgnore';

$select = IO::Select->new();

# $select undefined if could not create new object
errorExit("ERROR in Select Object Creation : $!") if !defined $select;

&connectNCID if ! $test;

&connectPhone;

# get a set of readable handles, block until at least one is ready
while (1) {
    if (!(@ready = $select->can_read($selectTO))) {
        # select timeout
        connectNCID();
        if (defined  $ncidsock) {
            $selectTO = undef;
            logMsg(1, "Listening at port $cellport\n");
        }
    }
    foreach $rh (@ready) {
        if (defined $ncidsock && $rh == $ncidsock) {
          # NCID server Caller ID
          $ncidline = <$rh>;
          if (!defined $ncidline) {
            $select->remove($ncidsock);
            $selectTO = $delay;
            logMsg(1, "NCID server at $ncidaddr:$ncidport disconnected\n");
            logMsg(1, "Trying to reconnect every $delay seconds\n");
          }
          else {logMsg(5, $ncidline);}
        }
        elsif ($rh == $cellsock) {
          # Smart phone CID or message
          my $datasock = $cellsock->accept();
          my $ret = $datasock->recv($celldata, 1024);
          close($datasock);
          logMsg(3, "$celldata\n");
          &doLine;
        }
    }
}

sub connectNCID {
  $ncidsock = IO::Socket::INET->new (
    Proto    => 'tcp',
    PeerAddr => $ncidaddr,
    PeerPort => $ncidport,
  );

  # $ncidsock undefined if could not connect to server
  if (!defined $ncidsock) {
    if (defined $selectTO) {return;}
    else {errorExit("NCID server: $ncidaddr:$ncidport $!");}
  }

  logMsg(1, "Connected to NCID server at $ncidaddr:$ncidport\n");
  my $greeting = <$ncidsock>;
  logMsg(1, "$greeting");

  # read and discard cidcall log sent from server
  while (<$ncidsock>)
  {
    # a log file may or nay not be sent
    # but a 300 message is always sent
    last if /^300/;

    logMsg(5, $_);
  };
  logMsg(1, $_); # 300 message

  $select->add($ncidsock);
}

sub connectPhone {
  $cellsock = IO::Socket::INET->new (
    Proto     => 'tcp',
    Listen    => 5,
    LocalPort => $cellport,
    Reuse     => 1
  ) or errorExit("Could not listen at port: $cellport $!");

  logMsg(1, "Listening at port $cellport\n");

  $select->add($cellsock);
}

sub doLine {
    my $nciddate = strftime("%m%d%H%M", localtime);
    my ($type, $f5, $f6, $msg, $ncidname, $phoneid, $ncidnmbr, $logmsg);

    # Known message types: RING PING BATTERY SMS MMS VOICEMAIL
    ($phoneid, $type, $f5, $f6) = $celldata =~
        /\/\w+(\w\w\w\w)\/\w+\/(\w+)\/(.*?)\/(.*)/;

    $type="NULL" if !defined $type;
    logMsg(3, "Detected type: $type\n");
    
    if ($type =~ /RING/) {
        # incoming call
        ($ncidname) = $f6 =~ /(.*?)(,\s|\s-)/;
        $logmsg = $msg =
            sprintf("CALL: ###DATE%s...CALL%s...LINE%s...NMBR%s...NAME%s+++",
                    $nciddate, $CALLTYPE, $phoneid, $f5, $ncidname);
    } elsif ($type =~ /PING|BATTERY/) {
        # internal message
        $logmsg = $msg = sprintf("NOT: PHONE %s: %s %s", $phoneid, $type, $f6);
    } elsif ($type =~ /SMS|MMS/) {
        # incoming message
        $logmsg = $msg = sprintf("NOT: PHONE %s: %s from %s",
            $phoneid, $type, $f5);
    } elsif ($type =~ /VOICEMAIL/) {
        # voice message
        $logmsg = $msg = sprintf("NOT: PHONE %s: %s", $phoneid, $type);
    } else {
        # unknown message
        $logmsg = "$type message not sent to NCID";
    }

    logMsg(3, "$logmsg\n");

    if ($msg) {
        my $norej = 1;
        foreach my $rej (@reject) {
            if($rej eq $f5) {
                $norej = 0;
                $logmsg = "rejected $rej";
                logMsg(3, "$logmsg\n");
            }
        }
        if ($norej && !$test && !defined $selectTO) {
            print $ncidsock $msg, "\r\n";
        }
    }
}

sub doPID {
    # Only create a PID file if $pidfile contains a file name
    if ($pidfile ne "") {
        if (-e $pidfile) {
            # only one instance per computer permitted
            unless (open(PIDFILE, $pidfile)) {
                errorExit("pidfile exists and is unreadable: $pidfile\n");
            }
            $savepid = <PIDFILE>;
            close(PIDFILE);
            chop $savepid;

            # Check PID file to see if active PID in it
            # Does not work for Windows
            if (-d "/proc") {
                if (-d "/proc/$savepid") {
                    errorExit("Process ($savepid) already running: $pidfile\n");
                } else {
                    logMsg(1, "Found stale pidfile: $pidfile\n");
                }
            } else {
                my $ret = `ps $savepid 2>&1`;
                if ($? == 0) {
                    errorExit("Process ($savepid) already running: $pidfile\n");
                } elsif ($? != -1) {
                    logMsg(1, "Found stale pidfile: $pidfile\n");
                } else {
                    logMsg(1, "ps command not found\n");
                }
            }
        }

        if (open(PIDFILE, ">$pidfile")) {
            print(PIDFILE "$$\n");
            $pid = $$;
            close(PIDFILE);
            logMsg(1, "Wrote pid $pid in $pidfile\n");
        } else { logMsg(1, "Could not write pidfile: $pidfile\n"); }
    }   
    else {logMsg(1, "Not using PID file\n");}
}

sub logMsg {
    my($level, $message) = @_;

    if (!defined $message) {print "Oops, unexpected exit\n"; exit 1}

    # write to STDOUT
    print $message if $debug && $verbose >= $level;

    # write to logfile
    print LOGFILE $message if $fileopen && $verbose >= $level;
}

sub cleanup() {
    close($ncidsock) if $ncidsock;
    close($cellsock) if $cellsock;
    if ($pid) {
        unlink($pidfile);
        logMsg(1, "Removed $pidfile\n");
    }
}

sub sigHandle {
    my $sig = shift;
    cleanup();
    my $date = strftime("%m/%d/%Y %H:%M:%S", localtime);
    logMsg(1, "\nTerminated $date: Caught SIG$sig\n");
    close(LOGFILE);
    exit(0);
}

sub sigIgnore {
    my $sig = shift;
    my $date = strftime("%m/%d/%Y %H:%M:%S", localtime);
    logMsg(1, ": Ignored SIG$sig: $date\n");
}

sub errorExit {
    logMsg(1, "@_");
    cleanup();
    my $date = strftime("%m/%d/%Y %H:%M:%S", localtime);
    logMsg(1, "\nTerminated: $date\n");
    close(LOGFILE);
    exit(-1);
}

=head1 NAME

rn2ncid - Android smart phone app 'Remote Notifier' to NCID gateway

=head1 SYNOPSIS

rn2ncid [--debug|-D]
        [--delay|-d <seconds>]
        [--help|-h]
        [--logfile-append|-l <filename>]
        [--logfile-overwrite|-L <filename>]
        [--configfile|-C <filename>]
        [--man|-m]
        [--ncidhost|-n <[host][:port]>]
        [--test| -t]
        [--pidfile|-p <filename>]
        [--verbose|-v <1-9>]
        [--version|-V]
        [--cellport|-c <port>]

=head1 DESCRIPTION

The B<rn2ncid> gateway obtains Caller ID and messages from a cell
phone.  It uses an Android app called B<Remote Notifier for Android>
to obtain the information and send it to the NCID server.  The server
then sends the CID information to the NCID clients.

The B<Remote Notifier for Android> app uses a 16 digit hex number to
identify the smart phone.  The B<rn2ncid> gateway uses 4 of the least
significant digits as the phone id.  Therefore you can run the app
in multiple smart phones without needing to configure them.

The phone id can be aliased by the NCID server so you can give each
phone a meaningful identification such a B<CELL>, or B<SP-1>, or
wharever.

The B<rn2ncid> configuration file is B</etc/ncid/rn2ncid.conf>.
See the rn2ncid.conf man page for more details.  If you are
also using B<ncid-page> or B<ncid-notify>.  you need to configure
the B<reject> variable.

The B<rn2ncid> gateway can run on any computer, but normally it is run
on same box as the NCID server.  If it is not run on the same box as the
NCID server, you must configure the server IP address in the configuration
file.

=head2 OPTIONS

=over 2

=item -n <[host][:port]>, --ncidhost=<[host][:port]>

Specifies the NCID server.
Port may be specified by suffixing the hostname with :<port>.

Input must be <host> or <host:port>, or <:port>

Default:  localhost:3333

=item -c <port>, --cellport <port>

Specifies the port to listen on for messages from a smart phone.

Default 10600

=item -d <seconds>, --delay <seconds>

If the connection to the NCID server is lost,
try every <delay> seconds to reconnect.

Default: 30

=item -D, --debug

Debug mode, displays all messages that go into the log file.
Use this option to run interactively.

=item -h, --help

Displays the help message and exits.

=item -m, --man

Displays the manual page and exits.

=item -C, --configfile=<filename>

Specifies the configuration file to use.  The program will still run if
a configuration file is not found.

Default: /usr/local/etc/ncid/rc2ncid.conf

=item -l, --logfile-append=<filename>

=item -L, --logfile-overwrite=<filename>

Specifies the logfile name to write.  The program will still run if
it does not have permission to write to it.

If both options are present, --logfile-append takes precedence.

Default: Append to /var/log/rn2ncid.log

=item -p, --pidfile=<filename>

Specifies the pidfile name to write. The program will still run if
it does not have permission to write a pidfile. The pid filename that
should be used is /var/run/rc2ncid.pid.

Default: no pidfile

=item -t, --test

Test mode is a connection to the Whozz Calling Network Device
without a connection to the NCID server.  It sets debug mode
and verbose = 3.  The verbose level can be changed on the command line.

Default: no test mode

=item -v, --verbose <1-9>

Output information, used for the logfile and the debug option.  Set
the level to a higher number for more information.  Levels range from
1 to 9, but not all levels are used.

Default: verbose = 1

=item -V, --version

Displays the version.

=back

=head1 EXAMPLES

=over 4

=item Start lcdncid in test mode at verbose level 3

rn2ncid --test

=item Start rc2ncid in debug mode at verbose level 1

rn2ncid -D

=back

=head1 REQUIREMENTS

=over

=item https://play.google.com/store/apps/details?id=org.damazio.notifier&hl=en

The "Remote Notifier for Android" app on your Android device.

=back

perl 5.6 or higher,
perl(Config::Simple)

=head1 FILES

/etc/ncid/rn2ncid.conf

=head1 SEE ALSO

ncidd.8,
wc2ncid.1,
sip2ncid.8

=cut

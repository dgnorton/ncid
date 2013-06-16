#!/usr/bin/perl

# wc2ncid - Whozz Calling device to NCID server gateway

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
use Data::HexDump;

my $prog = basename($0);
my $confile = basename($0, '.pl');
my $VERSION = "(NCID) XxXxX";

my $ConfigDir = "/usr/local/etc/ncid";
my $ConfigFile = "$ConfigDir/$confile.conf";

my ($ncidaddr, $ncidport) = ('localhost', 3333);
my ($peerport, $peeraddr);
my $ncidhost = "";
my $ncidsock = undef;
my $ncidline = undef;
my @wcaddr = ('192.168.0.90');
my $wcport = 3520;
my @wchost;
my $wcsock = undef;
my $wcipaddr;
my $wcdata;
my $wcline;
my $wcCmd;
my $setwc;
my $defaultTO = 0.2;
my $timeout = $defaultTO;
my $selectTO = undef;
my $delay = 30;
my $Delay = undef;
my $bcsock;
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
my $wclines;
my $ignoreTO;
my %config;
my @status = ({gotcall => 0, ring => 0, pickup => 0, hangup => 0});
my @ring = ({date => "", time => ""});
my @pickup = ({date => "", time => ""});
my @hangup = ({date => "", time => ""});
my @wc = ({'M', 'I', 'D', 'P', 'T', 'U', 'C', 'O', 'S', 'F', 'L', 'B'});
my @foundWC = ({'I', 'P', 'U', 'S', 'F', 'L', 'B', 'N'});
my (@gotwc, @missingwc);

my $bcaddr = inet_ntoa(INADDR_BROADCAST);

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
               "wchost|w=s" => \@wchost,
               "set-wc" => \$setwc,
               "pidfile|p=s" => \$pidfile
             ) || pod2usage(2);
die "$prog $VERSION\n" if $version;
pod2usage(-verbose => 1, -exitval => 0) if $help;
pod2usage(-verbose => 2, -exitval => 0) if $man;

if ($test) {
    $debug = 1;
    $verbose = 3;
}

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
    @wcaddr = $cfg->param('default.wcaddr');
}

# these command line values override the configuration file values
$delay = $Delay if $Delay;
$ncidport = $1 if $ncidhost =~ s/:(\d+)//;
$ncidaddr = $ncidhost if $ncidhost;
$verbose = $Verbose if defined $Verbose;
if (@wchost) {
    @wchost = split(/,/,join(',',@wchost));
    @wcaddr = @wchost;
}

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

if ($test) { logMsg(1, "Test mode\nNot using NCID host\n"); }

&doPID;

$SIG{'HUP'}  = 'sigHandle';
$SIG{'INT'}  = 'sigHandle';
$SIG{'QUIT'} = 'sigHandle';
$SIG{'TERM'} = 'sigHandle';
$SIG{'PIPE'} = 'sigIgnore';

$select = IO::Select->new();

# $select undefined if could not create new object
errorExit("ERROR in Select Object Creation : $!") if !defined $select;

&connectNCID if ! $test;

&connectWC;

&doDiscover if $setwc;

for ($pos = 0; $pos < $#wcaddr + 1; $pos++) {
    $num = $pos + 1;
    logMsg(1, "\nDevice WC-$num at address: $wcaddr[$pos]\n");
    if ($setwc) {
      &setWC;
      next if $addr eq "!OK";
    }
    &doWC;
}

logMsg(1, "\nMissing WC devices: @missingwc\n") if @missingwc;
errorExit("Could not find any WC devices\n") if ! @gotwc;
logMsg(1, "Waiting for calls from: @gotwc\n");

# get a set of readable handles, block until at least one is ready
while (1) {
    if (!(@ready = $select->can_read($selectTO))) {
        # select timeout
        connectNCID();
        if (defined  $ncidsock) {
            $selectTO = undef;
            logMsg(1, "Waiting for calls from @gotwc\n");
        }
    }
    foreach $rh (@ready) {
        if (defined $ncidsock && $rh == $ncidsock) {
          # NCID server Caller ID
          $ncidline = <$ncidsock>;
          if (!defined $ncidline) {
            $select->remove($ncidsock);
            $selectTO = $delay;
            logMsg(1, "NCID server at $ncidaddr:$ncidport disconnected\n");
            logMsg(1, "Trying to reconnect every $delay seconds\n");
          }
          else {logMsg(5, $ncidline);}
        }
        else {
          # One or more WC devices Call Data

          # Start of all packets (may or may not include $ at position 20)
          #          1         2
          #0123456789012345678901
          #^^<U>??????<S>??????$

          $rh->recv($wcdata, 120, 0);
          if ('$' eq substr($wcdata, 21, 1)) {$wcline = substr($wcdata, 22);}
          else {$wcline = substr($wcdata, 21);}
          &doCall;
        }
    }
}

sub connectNCID {
  $ncidsock = IO::Socket::INET->new(
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

sub resetWC {
  # Reset the Whozz Calling Ethernet Link Device.

  $wclines = 0;
  $wcCmd = "^^Id-R";
  send($wcsock, $wcCmd, 0, $wcipaddr);
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcport\n");
  $timeout = 9;
  logMsg(1, "Waiting up to $timeout seconds for first reset packet\n");
  &getPacket;
  $wclines++ if @ready;
  $timeout = 3;
  $ignoreTO = 1;
  logMsg(1,
    "Looping for more reset packets until a $timeout seconds timeout\n");
  for (@ready = 0; @ready != 0;) {
    &getPacket;
    $wclines++ if @ready;
  }
  $ignoreTO = 0;
  $timeout = $defaultTO;
  $wc[$pos]{L} = $wclines;
  logMsg(1, "WC-$num has $wclines telephone lines\n") if $wclines;
}

sub doDiscover {
  # set the port to $wcport
  my $wcportHex = unpack('H4', pack('S>',$wcport));
  &connectBC("^^IdT$wcportHex\r");
  &getPacket;
  errorExit("Could not set all WC devices port to $wcport\n") if ! @ready;
  logMsg(1, "All WC devices port set to $wcport\n");

  $ignoreTO = 1;
  connectBC("^^Id-V");
  &getPacket;
  errorExit("Error: Did not discover any WC device\n") if ! @ready;
  $loc = 0;
  &getinfo;
  $loc++;

  # Look for more WC devices
  do {
    &getPacket;
    if (@ready) {
      &getinfo;
      $loc++;
    }
  } until @ready eq 0;
  $ignoreTO = 0;

  logMsg(1, "Discovered $loc WC device(s)\n");
  &chkaddr;
  errorExit("Error: $match WC devices have IP address $foundWC[$loc]{I}\n")
    if $match;
}

# check for duplicate IP addresses in @foundWC
sub chkaddr {
    for $loc (0 .. $#foundWC) {
        $match = 0;
        for ($cnt = $loc + 1; $cnt < $#foundWC + 1; $cnt++) {
            if ($foundWC[$loc]{I} eq $foundWC[$cnt]{I}) {$match++;}
        }
        last if $match;
    }
}

sub getaddr {
  $addr = "!OK";
  for $cnt (0 .. $#foundWC) {
    if ($addr eq "!OK" && $foundWC[$cnt]{N} == 0) {
      $addr = $foundWC[$cnt]{I};
      $match = $cnt;
    }
    if ($num == $foundWC[$cnt]{N}) {
      $addr = "OK";
      $match = $cnt;
      last;
    }
  }

  if ($addr eq "OK") {
    logMsg(1, "WC-$num already configured as $wcaddr[$pos]\n");
  } elsif ($addr eq "!OK") {
    logMsg(1, "No free device and no device at $wcaddr[$pos] for WC-$num\n");
    push(@missingwc, "WC-$num ($wcaddr[$pos])");
  } else {
    logMsg(1, "WC-$num free device address $addr will become $wcaddr[$pos]\n");
    # flag free device as used
    $foundWC[$match]{N} = -1;
  }

}

# get the position in @wcaddr for an IP address in @foundWC,
# not there if $gotnum == 0
sub setnum {
  for ($gotnum = $cnt = 0; $cnt < $#wcaddr + 1; $cnt++) {
      if ($wcaddr[$cnt] eq $foundWC[$loc]{I}) {
          $gotnum = $cnt + 1;
          last;
      }
  }
}

# populate @foundWC for the WC device
sub getinfo {
    # Start of all packets in configured mode
    # "$" at position 20 may or may not be there
    #          1         2
    #012345678901234567890
    #^^<U>??????<S>??????$

    # Firmware Version Line
    $foundWC[$loc]{F} = substr($wcline, 0);

    # WC IP address
    $foundWC[$loc]{I} = $peeraddr;

    # WC port
    $foundWC[$loc]{T} = $peerport;

    # WC unit number which should be the device's number of lines
    $wclines = &multiByteStringToInteger(substr($wcdata, 5, 6));
    $foundWC[$loc]{U} = $wclines;

    # WC serial number
    $foundWC[$loc]{S} = unpack('H12',substr($wcdata, 14, 6));
    $foundWC[$loc]{S} =~ s/(..)(..)(......)(..)/$1-$2-$3-$4/;

    # WC number of lines
    if ($wclines != 2 || $wclines != 4 || $wclines != 8) {$wclines = 0}
    $foundWC[$loc]{L} = $wclines;

    # WC beginning line number
    $foundWC[$loc]{B} = substr($wcline, 19,2);

    # WC address in @wcaddr if set to 1
    &setnum;
    $foundWC[$loc]{N} = $gotnum;

    logMsg(1,  "    $foundWC[$loc]{F}\n    S=$foundWC[$loc]{S}");
    logMsg(1, " I=$foundWC[$loc]{I} P=$foundWC[$loc]{T} U=$foundWC[$loc]{U}");
    logMsg(1, " L=$foundWC[$loc]{L} B=$foundWC[$loc]{B} N=$foundWC[$loc]{N}\n");
}

sub setWC {
  # Set the WC address from the configuration file or command line.
  # set the beginning line number

  my $wcAddrP1;
  my $wcAddrP2;
  my $wcAddrP3;
  my $wcAddrP4;
  my $wcaddrhex;

  &getaddr;
  if ($addr eq "!OK") {
    # no available WC device found
    return;
  }

  if ($addr ne "OK") {
    # set the WC address, $addr is the address of the free WC device
    ($wcAddrP1, $wcAddrP2, $wcAddrP3, $wcAddrP4) = split(/\./, $wcaddr[$pos]);
    $wcaddrhex = unpack('H8', pack('C', $wcAddrP1) . pack('C', $wcAddrP2) .
        pack('C', $wcAddrP3) . pack('C', $wcAddrP4));
    $wcCmd = "^^IdI$wcaddrhex";
    $wcipaddr = sockaddr_in($wcport, inet_aton($addr));
    send($wcsock, $wcCmd, 0, $wcipaddr);
    logMsg(1, "Sent \"$wcCmd\" to $addr:$wcport\n");
    &getPacket;
    errorExit("Could not set WC-$num IP address to $wcaddr[$pos]\n")
      if ! @ready;
    logMsg(1, "WC-$num IP address set to $wcaddr[$pos]\n");

    # check for a packet, then ignore it
    # no packet is expected, but this step appears to be necessary
    # on some units to either trigger, or allow time for, the new IP
    # address to be updated in the device
    $ignoreTO = 1;
    &getPacket;
    $ignoreTO = 0;
  }

  $wcipaddr = sockaddr_in($wcport, inet_aton($wcaddr[$pos]));

  # reset the WC to get total number of telephone lines supported
  &resetWC;
  if (!$wclines) {
    logMsg(1, "Could not reset WC-$num\n");
    return;
  }

  # use the unit number to store the number of telephone lines
  $wcCmd = "^^IdU00000000000$wclines\r";
  send($wcsock, $wcCmd, 0, $wcipaddr);
  $wcCmd =~ s/\r$//;
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcport\n");
  &getPacket;

  # make sure a 2-line WC device is at position 1
  if ($num != 1 && $wclines == 2) {
    errorExit("The 2-line Whozz Calling device must be WC-1\n");
  }

  # set the starting telephone line number
  my $lnum = sprintf("%02d", $linenum);
  $wcCmd = "^^Id-N00000077$lnum\r";
  send($wcsock, $wcCmd, 0, $wcipaddr);
  $wcCmd =~ s/\r$//;
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcport\n");
  $timeout = 9;
  logMsg(1, "Waiting up to $timeout seconds to set line number\n");
  $ignoreTO = 1;
  &getPacket;
  $ignoreTO = 0;
  $timeout = $defaultTO;
  logMsg(1,
    "WC-$num at $wcaddr[$pos] set to beginning line number = $linenum\n");
  $linenum = $linenum + $wclines;
}

sub doWC {
  $wcipaddr = sockaddr_in($wcport, inet_aton($wcaddr[$pos]));
  $wcCmd = "^^IdX";
  send($wcsock, $wcCmd, 0, $wcipaddr);
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcport\n");
  $ignoreTO = 1;
  &getPacket;
  $ignoreTO = 0;

  if (!@ready) {
    logMsg(1, "Whozz Calling Device at $wcaddr[$pos] not found\n");
    if (!$#wcaddr) {
      logMsg(1, "Only one WC device configured, so will try to locate one.\n");
      # findWC() only returns if a device was found
      &findWC;
    }
    else {
      logMsg(1, "Device $foundWC[$match]{I} is out of subnet\n")
        if defined $match;
      push(@missingwc, "WC-$num ($wcaddr[$pos])");
      return;
    }
  }

  # WC device was found
  &decodePacket;
  push(@gotwc, "WC-$num ($wcaddr[$pos])");

  $wcCmd = "^^Id-V";
  send($wcsock, $wcCmd, 0, $wcipaddr);
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcport\n");
  &getPacket;
  errorExit("No response from Whozz Calling\n") if ! @ready;
  &decodePacket;

  # Without this delay, the first flag sent in doFlags won't be set
  # (it just gets ignored). This appears to be a problem only on
  # certain WC units (e.g., Whozz Calling 8 full featured,
  # firmware v9.7).
  select(undef,undef,undef, .1); #100 millisecond delay

  &doFlags;
  $wcCmd = "^^Id-V";
  send($wcsock, $wcCmd, 0, $wcipaddr);
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcport\n");
  &getPacket;
  &decodePacket;
  # WC device beginning Line number
  $wc[$pos]{B} = substr($wcline, 19,2);

}

# Locate a WC Ethernet Link Device
sub findWC {
  doDiscover();
  logMsg(1, "\n*** IMPORTANT IMPORTANT IMPORTANT ***\n");
  logMsg(1, "Found WC device at address \$wcaddr = $foundWC[0]{I};\n");
  logMsg(1, "Either change address in $ConfigFile: wcaddr = $foundWC[0]{I}\n");
  logMsg(1, "Or change device address to $wcaddr[$pos]: wc2ncid --set-wc\n\n");

  $wcaddr[$pos] = $foundWC[0]{I};
  $wcipaddr = sockaddr_in($wcport, inet_aton($wcaddr[$pos]));
  $wcCmd = "^^IdX";
  send($wcsock, $wcCmd, 0, $wcipaddr);
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcport\n");
  &getPacket;
  errorExit("Device $foundWC[0]{I} is out of subnet\n") if ! @ready;
}

# open a socket to receive packets from one or more WC Ethernet Link Devices
sub connectWC {
  $wcsock = IO::Socket::INET->new(
    Proto     => 'udp',
    LocalPort => $wcport
  );

  # $wcsock undefined if could not connect to server
  errorExit("ERROR in WC Socket Creation : $!") if !defined $wcsock;

  logMsg(1, "Opened Whozz Calling Ethernet Link Device port: $wcport\n");

  $select->add($wcsock);
}

sub getPacket {
  @ready = $select->can_read($timeout);
  if (@ready) { 
    foreach $rh (@ready) {
        ($peerport, $peeraddr) = sockaddr_in($rh->recv($wcdata, 90, 0));
        $peeraddr = inet_ntoa($peeraddr);
        logMsg(1, "Received data from $peeraddr:$peerport\n");
        if ('$' eq substr($wcdata, 21, 1)) {$wcline = substr($wcdata, 22);}
        else {$wcline = substr($wcdata, 21);}
        my $f = new Data::HexDump;
        $f->data($wcdata);
        logMsg(4, "Packet size: " . length($wcdata) . "\n" . $f->dump . "\n");
        # only one response wanted
        last;
    }
  } else { 
     logMsg(1,
       "Timeout: no response received in $timeout seconds\n") if !$ignoreTO; 
  }
}

# open a broadcastsocket to send one command to all WC Ethernet Link Devices
# then close socket
sub connectBC {
  ($wcCmd) = @_;

  $select->remove($wcsock);
  close($wcsock);
  logMsg(1, "Closed WC port\n");

  $bcsock = IO::Socket::INET->new(
    Proto     => 'udp',
    Broadcast => 1,
    PeerAddr  => $bcaddr,
    PeerPort  => $wcport,
    LocalPort => $wcport
  );

  # $bcsock undefined if could not connect to server
  errorExit("ERROR in Broadcast Socket Creation : $!") if !defined $bcsock;

  logMsg(1, "Opened Broadcast\n");
  send($bcsock, $wcCmd, 0);
  $wcCmd =~ s/\r$//;
  logMsg(1, "Sent $wcCmd to Broadcast\n");
  close($bcsock);
  logMsg(1, "Closed Broadcast\n");

  &connectWC;
}

# decode the WC packet
sub decodePacket {
  # Start of all packets in configured mode
  # "$" at position 20 may or may not be there
  #          1         2
  #012345678901234567890
  #^^<U>??????<S>??????$

  if ('V' eq substr($wcline, 0, 1)) {
    # Firmware Version Line
    $wc[$pos]{F} = substr($wcline, 0);
    logMsg(1,  "    $wc[$pos]{F}\n");
  }
  else {
    # line: 1 substr offset, line 2: offset, line 3: data
    #          1         2         3         4         5         6        
    #012345678901234567890123456789012345678901234567890123456789012345678
    #<M>??????<I>????<D>????<P>??<T>??<U>??????<C>??????<O>??????<S>??????

    # WC Mac Address
    $wc[$pos]{M} = unpack('H12',substr($wcline, 3, 6));
    $wc[$pos]{M} =~ s/(..)(..)(..)(..)(..)(..)/$1:$2:$3:$4:$5:$6/;

    # WC IP address
    $wc[$pos]{I} = &unpackIP4address(substr($wcline, 12, 8));

    # destination IP address
    $wc[$pos]{D} = &unpackIP4address(substr($wcline, 19, 8));

    # destination port
    $wc[$pos]{P} = unpack('S>', substr($wcline,26,2));

    # WC port
    $wc[$pos]{T} = unpack('S>', substr($wcline,31,2));

    # WC unit number
    $wc[$pos]{U} = &multiByteStringToInteger(substr($wcline, 36, 6));
    if ($wc[$pos]{U} >= 1000) {
      $wc[$pos]{U} = "0x" . unpack('H12',substr($wcline, 36, 6));
    }

    # destination Mac address
    $wc[$pos]{C} = unpack('H12',substr($wcline, 45, 6));
    $wc[$pos]{C} =~ s/(..)(..)(..)(..)(..)(..)/$1:$2:$3:$4:$5:$6/;

    # Broadcast Mac address
    $wc[$pos]{O} = unpack('H12',substr($wcline, 54, 6));
    $wc[$pos]{O} =~ s/(..)(..)(..)(..)(..)(..)/$1:$2:$3:$4:$5:$6/;

    # WC serial number
    $wc[$pos]{S} = unpack('H12',substr($wcline, 63, 6));
    $wc[$pos]{S} =~ s/(..)(..)(......)(..)/$1-$2-$3-$4/;

    logMsg(1, "    M=$wc[$pos]{M} I=$wc[$pos]{I} D=$wc[$pos]{D}");
    logMsg(1, " P=$wc[$pos]{P} T=$wc[$pos]{T}\n    U=$wc[$pos]{U}");
    logMsg(1, " C=$wc[$pos]{C} O=$wc[$pos]{O} S=$wc[$pos]{S}\n");
  }
}

sub doFlags {
    # All default flags: ECXUDASOBKT
    # The two line model only supports flags: Cc Dd Aa Ss Oo Tt
    # only need to change two defaults: C -> c and D -> d
    # mostly the two line unit does not respond to flag setting

    logMsg(1, "Checking and setting required flags\n");
    $ignoreTO = 1;
    if ($wc[$pos]{F} =~ /.*C.*/) {
        $wcCmd = "^^Id-c";
        send($wcsock, $wcCmd, 0, $wcipaddr);
        logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcport\n");
        &getPacket;
    }
    if ($wc[$pos]{F} =~ /.*D.*/) {
        $wcCmd = "^^Id-d";
        send($wcsock, $wcCmd, 0, $wcipaddr);
        logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcport\n");
        &getPacket;
    }
    if ($wc[$pos]{F} =~ /.*a.*/) {
        $wcCmd = "^^Id-A";
        send($wcsock, $wcCmd, 0, $wcipaddr);
        logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcport\n");
        &getPacket;
    }
    if ($wc[$pos]{F} =~ /.*O.*/) {
        $wcCmd = "^^Id-o";
        send($wcsock, $wcCmd, 0, $wcipaddr);
        logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcport\n");
        &getPacket;
    }
    if ($wc[$pos]{F} =~ /.*t.*/) {
        $wcCmd = "^^Id-T";
        send($wcsock, $wcCmd, 0, $wcipaddr);
        logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcport\n");
        &getPacket;
    }
    $ignoreTO = 0;
}

sub multiByteStringToInteger {
    my $m = shift; # multi-byte string to convert
    my $l = length($m);
    my $d = 0; # resulting decimal

    for (my $i = 0; $i < $l; $i++) {
        $d+=unpack('C',substr($m,$l-$i-1,1))*(256**$i);
    }

    return $d
}

sub unpackIP4address {
    my $s = shift;
    my $ip1 = unpack('C', substr($s,0,1));
    my $ip2 = unpack('C', substr($s,1,1));
    my $ip3 = unpack('C', substr($s,2,1));
    my $ip4 = unpack('C', substr($s,3,1));

    return $ip1 . "." . $ip2 . "." . $ip3 . "." . $ip4;
}

sub doCall {
  my $msg;     # either a "CALL" or "CALLINFO" text line
  my $line;    # line number: 2 characters
  my $type;    # call inbound or outbound: I or O
  my $ltype;   # either "IN" or "OUT" depending on $type
  my $se;      # call start or end: S or E
  my $dur;     # duration in seconds: 4 digits
  my $cs;      # checksum, good or bad: G or B
  my $ring;    # distinctive ring type (A B C D) & number of rings: 2 chars
  my $dtmm;    # month: 2 characters
  my $dtdd;    # day: 2 characters
  my $tmhh;    # hour: 2 characters
  my $tmmm;    # minute: 2 characters
  my $ampm;    # AM or PM
  my $nmbr;    # phone number: 14 characters
  my $name;    # 15 characters
  my $dttm;    # date and time combined: mmddhhmm
  my $lable;   # line label: WC<line>
  my $rdate;   # ring date: mm/dd
  my $rtime;   # ring time: hh:mm:ss
  my $unit;    # unit number
  my $serial;  # serial number
  my $callend; # either "CANCEL" or "BYE"
  my $sdate;   # mm/dd at start of call
  my $syear;   # yyyy at start of call
  my $stime;   # hh:mm:ss at start of call
  my $edate;   # mm/dd at end of call
  my $eyear;   # yyyy at end of call
  my $etime;   # hh:mm:ss at end of call
  my $scall;   # call start: mm/dd/yyyy hh:mm:ss
  my $ecall;   # call end:   mm/dd/yyyy hh:mm:ss

  # WC unit number
  $unit = &multiByteStringToInteger(substr($wcdata, 5, 6));

  # WC serial number
  $serial = unpack('H12',substr($wcdata, 14, 6));
  $serial =~ s/(..)(..)(......)(..)/$1-$2-$3-$4/;

  # Example record (spaces between fields indicated by periods,
  # except in "CallerID.com")
  #          1         2         3         4         5         6    <-substr
  #01234567890123456789012345678901234567890123456789012345678901     offset
  #01.I.S.0276.G.B3.09/26.11:28.AM.800-240-463799.CallerID.com      <-data
  #                                12345678901234 123456789012345   <-fixed
  #                                                                   field

  logMsg(3, "Unit=$unit Serial=$serial\n$wcline\n");

  # get the first 2 fields to determine if call data or detail
  ($line, $type) = $wcline =~ /(\d\d)\s+(\w)/;

  if ($type eq 'I' or $type eq 'O') {
    ($se, $dur, $cs,$ring, $dtmm, $dtdd, $tmhh, $tmmm, $ampm, $nmbr, $name) = $wcline=~
    /\d\d\s+\w\s+(\w)\s+(\d\d\d\d)\s+(\w)\s+(\w+)\s+(\d\d)\/(\d\d)\s+(\d\d):(\d\d)\s+(\w+)\s+([A-Za-z0-9-_*]+)\s+([A-Za-z0-9-_*]*.*)/;

    if (($ampm eq 'AM') && ($tmhh == 12)) {$tmhh -= 12;}
    if (($ampm eq 'PM') && ($tmhh != 12)) {$tmhh += 12;}
    $dttm =  $dtmm . $dtdd . $tmhh . $tmmm;

    $name =~ s/\s*$//;
    if ($name eq '') {$name = 'NONAME';}

    $status[$line]{gotcall} = 1;
    $lable = "WC$line";

    if ($type eq 'I') {$ltype = "IN";}
    else {$ltype = "OUT";}

    if ($se eq 'S') {
      # Start of either incoming or outgoing call
      $msg = sprintf("CALL: ###DATE%s...CALL%s...LINE%s...NMBR%s...NAME%s+++",
                      $dttm, $ltype, $lable, $nmbr, $name);
    } elsif ($se eq 'E') {
      # End of either incoming or outgoing call
      if ($status[$line]{pickup}) {
        # end of call after pickup
        $callend = "BYE";
        $rdate = $hangup[$line]{date};
        $edate = $rdate;
        $rdate =~ s/\///;
        $rtime = $hangup[$line]{time};
        $etime = $rtime;
        $rtime =~ s/(\d\d):(\d\d).*/$1$2/;
        $dttm = $rdate . $rtime;
        if ($status[$line]{ring})
        {
            $sdate = $ring[$line]{date};
            $stime = $ring[$line]{time};
        }
        else
        {
            $sdate = $pickup[$line]{date};
            $stime = $pickup[$line]{time};
        }
      } else {
        # end of call with no pickup
        $callend = "CANCEL";
        if ($status[$line]{ring})
        {
            $sdate = $ring[$line]{date};
            $stime = $ring[$line]{time};
        }
        else {
            $sdate = "$dtmm/$dtdd";
            $stime = "$tmhh:$tmmm:00";
        }
        $edate = $sdate;
        $etime = $stime;
      }
      $eyear = strftime("%Y", localtime);
      $syear = $eyear;
      if (('12' == substr($sdate,0,2)) && ('01' == substr($edate,0,2))) {
         $syear=$eyear-1
      }
      $scall = "$sdate/$syear $stime";
      $ecall = "$edate/$eyear $etime";
      $msg = sprintf(
          "CALLINFO: ###%s...DATE%s...SCALL%s...ECALL%s...CALL%s...LINE%s...NMBR%s...NAME%s+++",
          $callend, $dttm, $scall, $ecall, $ltype, $lable, $nmbr, $name);
      $status[$line]{gotcall} = $status[$line]{ring} = $status[$line]{pickup} = $status[$line]{hangup} = 0;
    }
    logMsg(2, "$msg\n");
    if (!$test && !defined $selectTO) { print $ncidsock $msg, "\r\n"; }
  } elsif ($type eq 'R') {
    # ring: R
    ($rdate, $rtime) = $wcline =~ /\d\d\s+\w\s+(\d\d\/\d\d)\s+(\d\d:\d\d:\d\d)/;
    $status[$line]{ring} = 1;
    $ring[$line]{date} = $rdate;
    $ring[$line]{time} = $rtime;
    logMsg(2, "Phone Off Hook: L$line $rdate $rtime\n");
  } elsif ($type eq 'F') {
    # off hook: F
    ($rdate, $rtime) = $wcline =~ /\d\d\s+\w\s+(\d\d\/\d\d)\s+(\d\d:\d\d:\d\d)/;
    $status[$line]{pickup} = 1;
    $pickup[$line]{date} = $rdate;
    $pickup[$line]{time} = $rtime;
    logMsg(2, "Phone Off Hook: L$line $rdate $rtime\n");
  } elsif ($type eq 'N') {
    # on hook: N
    ($rdate, $rtime) = $wcline =~ /\d\d\s+\w\s+(\d\d\/\d\d)\s+(\d\d:\d\d:\d\d)/;
    $status[$line]{hangup} = 1;
    $hangup[$line]{date} = $rdate;
    $hangup[$line]{time} = $rtime;
    if (!$status[$line]{gotcall})
    {
        # no call
        $status[$line]{pickup} = $status[$line]{hangup} = 0;
    }
    logMsg(2, "Phone On Hook: L$line $rdate $rtime\n");
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
    close($wcsock) if $wcsock;
    close($bcsock) if $bcsock;
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

wc2ncid - Whozz Calling device to NCID server gateway

=head1 SYNOPSIS

wc2ncid [--debug|-D]
        [--delay|-h <seconds>]
        [--help|-h]
        [--logfile-append|-l <filename>]
        [--logfile-overwrite|-L <filename>]
        [--configfile|-C <filename>]
        [--man|-m]
        [--ncidhost|-n <[host][:port]>]
        [--set-wc]
        [--test| -t]
        [--pidfile|-p <filename>]
        [--verbose|-v <1-9>]
        [--version|-V]
        [--wchost|-w <address1>[,address2][,...]

=head1 DESCRIPTION

The WC (Whozz Calling) gateway obtains Caller ID from one or more
Whozz Calling Ethernet Link devices.  The Whozz Calling Ethernet
Link device handles multi-line Caller ID, either 2, 4, or 8 telephone
lines.  The basic models handle incoming calls and the deluxe models
handle incoming and outgoing calls.

See the Whozz Calling feature matrix for the various models:
  http://www.callerid.com/feature-table/
 
The Whozz Calling devices do not pick-up, go off-hook, or answer
the telephone line.  They cannot be used to hangup the line for
phone numbers in the ncidd blacklist file, but a modem can be used
with the WC gateway for the bklacklist feature of ncidd.

=head2 OPTIONS

=over 2

=item -n <[host][:port]>, --ncidhost=<[host][:port]>

Specifies the NCID server.
Port may be specified by suffixing the hostname with :<port>.

Input must be <host> or <host:port>, or <:port>

Default:  localhost:3333

=item -w <address1[,address2][,...]>, --wchost=<address1[,address2],[,...]>

Specifies the Whozz Calling Ethernet Link Device or devices.
Multiple addresses for devices are comma separated.

Input must be <address> or <address1,address2,etc>.

Default: 192.168.0.90

=item -d <seconds>, --delay <seconds>

If the connection to the NCID server is lost,
try every <delay> seconds to reconnect.

Default: 30

=item -D, --debug

Debug mode, displays all messages that go into the log file.  Use this option to run interactively.

=item -h, --help

Displays the help message and exits.

=item -m, --man

Displays the manual page and exits.

=item -C, --configfile=<filename>

Specifies the configuration file to use.  The program will still run if
a configuration file is not found.

Default: /usr/local/etc/ncid/wc2ncid.conf

=item --set-wc

Sets the IP address, beginning line number, number of telephone lines,
and sending port for each Whozz Calling Ethernet Link Device.

It sets the IP address for the WC device from the address for
"wcaddr" in the configuration file or --wchost on the command line.

It automatically sets the beginning line number for the WC device which
is used as a line label prefixed with "WC".  Each device gets a beginning
line number that is the ending line number plus one from the preceeding
device, for example; device 1 (WC01 WC02) device 2 (WC03 WC04 WC05 WC06).

NOTE: All devices are automatically configured to send call information
on port 3520.

=item -l, --logfile-append=<filename>

=item -L, --logfile-overwrite=<filename>

Specifies the logfile name to write.  The program will still run if
it does not have permission to write to it.

If both options are present, --logfile-append takes precedence.

Default: Append to /var/log/wc2ncid.log

=item -p, --pidfile=<filename>

Specifies the pidfile name to write. The program will still run if
it does not have permission to write a pidfile. The pid filename that
should be used is /var/run/wc2ncid.pid.

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

=item Start wc2ncid, set IP address to 192.168.1.90 from command
line, set the beginning line number automatically, and set the
sending Ethernet port to 3520 (the default):

wc2ncid --set-wc --wchost 192.168.1.90

=item Start wc2ncid in test and debug modes at verbose 5:

wc2ncid -tv5

=back

=head1 REQUIREMENTS

=over

=item At least one Whozz Calling Ethernet Link device

http://www.callerid.com

=back

perl 5.6 or higher,
perl(Config::Simple),
perl(Data::HexDump)

=head1 FILES

/etc/ncid/wc2ncid.conf

=head1 SEE ALSO

ncidd.8,
wct.1,
wc2ncid.conf.5

=cut

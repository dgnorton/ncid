#!/usr/bin/perl

# Copyright (c) 2012 by John L. Chmielewski <jlc@users.sourceforge.net>
#                       Todd Andrews <tandrews@users.sourceforge.net>

# wct is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# any later version.

# wct is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA

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
my $confile = basename('wc2ncid.pl', '.pl');
my $VERSION = "(NCID) XxXxX";

my $ConfigDir = "/usr/local/etc/ncid";
my $ConfigFile = "$ConfigDir/$confile.conf";

my ($peerport, $peeraddr);
my @wcaddr = ('192.168.0.90');
my $wcport = 3520;
my @wcports = ($wcport); # allows showing discovered devices not using std port 3520
my @wchost;
my $wcsock = undef;
my $wcipaddr;
my $wcdata;
my $wcline;
my $wcCmd;
my $userCmd;
my $setwc;
my $defaultTO = 0.2;
my $timeout = $defaultTO;
my $bcsock;
my $logfile = "wct.log";
my ($logfileMode, $logfileModeEnglish);
my $logfileAppend;
my $logfileOverwrite;
my $debug = 1;
my $verbose = 1;
my $Verbose = undef;
my ($help, $man, $version);
my $pidfile = "";
my $savepid;
my $pid;
my $fileopen;
my $select;
my @ready;
my $rh;
my ($pos, $num, $cnt, $loc, $gotnum);
my $match;
my $addr;
my $cfg;
my $linenum = 1;
my $wclines;
my $ignoreTO;
my %config;
my $gotdata;
my $discover;
my $discoverLoopSecs;
my $discoverLoopCount = 1;
my $forcedDiscover = 0; # =1 means device IP addresses will NOT come from config file or command line --wchost
my $forceSelect = 0; # =1 means we only detected one device but we need to be able to choose ALL DEVICES

my @wc = ({'M', 'I', 'D', 'P', 'T', 'U', 'C', 'O', 'S', 'F', 'L','B'});
my @foundWC = ({'I', 'P', 'U', 'S', 'F', 'L', 'B', 'N'});
my (@gotwc, @missingwc);

my $bcaddr = inet_ntoa(INADDR_BROADCAST);

my $date = strftime("%m/%d/%Y %H:%M:%S", localtime);

# command line processing
my @save_argv = @ARGV;
Getopt::Long::Configure ("bundling");
my ($result) = GetOptions(
               "configfile|C=s" => \$ConfigFile,
               "logfile-append|l=s" => \$logfileAppend,
               "logfile-overwrite|L=s" => \$logfileOverwrite,
               "debug|D" => \$debug,
               "help|h" => \$help,
               "man|m" => \$man,
               "verbose|v=i" => \$Verbose,
               "version|V" => \$version,
               "wchost|w=s" => \@wchost,
               "set-wc" => \$setwc,
               "pidfile|p=s" => \$pidfile,
               "discover|discovery|d" => \$discover,
               "discover-loop|discovery-loop=i" => \$discoverLoopSecs
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
    @wcaddr = $cfg->param('default.wcaddr');
}

# these command line values override the configuration file values
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

logMsg(1, "$prog version $VERSION\n");
logMsg(1, "Verbose level: $verbose\n");
logMsg(1, "Debug mode\n") if ($debug);

if ($fileopen) {logMsg(1, "Logfile: $logfileModeEnglish $logfile\n");}
else {logMsg(1, "Could not open logfile: $logfile\n");}

&doPID;

if (defined $cfg) {logMsg(1, "Processed config file: $ConfigFile\n");}
else {logMsg(1, "Config file not found: $ConfigFile\n");}

$select = IO::Select->new();

# $select undefined if could not create new object
errorExit("ERROR in Select Object Creation : $!") if !defined $select;

if (@wcaddr && !$discover && !$discoverLoopSecs) {
   $pos = 0;
   &connectWC;
   &doDiscover if $setwc;

   for ($pos = 0; $pos < $#wcaddr + 1; $pos++) {
       $num = $pos + 1;

       # when reading IP addresses from config file or command line,
       # set default port to $wcport for all devices
       $wcports[$pos]=$wcport;

       logMsg(1, "\nDevice WC-$num at address: $wcaddr[$pos]\n");
       if ($setwc) {
         &setWC;
         next if $addr eq "!OK";
       }
       &doWC;
   }
   # add broadcast so we can select "ALL DEVICES"
   push(@wcaddr, $bcaddr); 
   $wcports[$#wcaddr] = $wcport; 
   $wc[$#wcaddr]{I} = $bcaddr;
} else {
  # no devices defined on command line or in config file,
  # or --discover or --discover-loop is in effect
  $forcedDiscover = 1;
  while (1) {
      &doDiscoverReadOnly;
      if ($discoverLoopSecs) {
         $discoverLoopCount++;
         logMsg(1,"Sleeping for $discoverLoopSecs seconds before starting discover loop iteration #$discoverLoopCount\n");      
         sleep ($discoverLoopSecs);
         $select->remove($wcsock);
         $wcsock->close();
      } else { last; }
  }
}

# We're done discovering or initializing all devices.
# Now, use the first valid device in the list as the default one to start
# working with. Re-establish $wcsock handle in case we're dealing with
# a non-standard port for the first device.
if (@wcaddr) {
   my $foundValid=undef;
   for ($pos = 0; $pos < $#wcaddr + 1; $pos++) {
       if ($wc[$pos]{I} || ($wcaddr[$pos] eq $bcaddr)) {
          $foundValid=$pos;
          $select->remove($wcsock);
          $wcsock->close();
          &connectWC;
          $wcipaddr = sockaddr_in($wcports[$pos], inet_aton($wcaddr[$pos]));
          last;
       }
   }
   errorExit("Could not determine a default device.") if !defined $foundValid;
   $pos=$foundValid;
}

logMsg(1, "\nMissing WC devices: @missingwc\n") if @missingwc;
 
&selectDevice; # operator selection

my $prompt = "Command ('help', 'select' or <ctrl><d> to quit): ";
print "\n\n[",&whichDeviceIP,"] ",$prompt;

my $skipReadData = 0; # =1 to eliminate unnecessary timeout after doing 'help', 'select', etc.

while (<>)
{
    # send command
    chop;
    $userCmd = "$_";
    if (length($userCmd)) {
        if (lc($userCmd) eq 'help') { 
           open(my $p2uPipe, "|-", $ENV{PAGER} || "more") or die "Can't start pager: $!";
          pod2usage(-verbose => 99, 
                    -output => $p2uPipe,
                    -sections => "INTERACTIVE COMMAND MODE",
                    -exitval => "NOEXIT");
          close($p2uPipe);
          $skipReadData = 1;
          $wcCmd="";
        } else {
          if (lc($userCmd) eq 'select') {
             $forceSelect = 1;
             &selectDevice;
             $forceSelect = 0;
             $skipReadData = 1;
             $wcCmd="";
          } else {
            if (length($userCmd) eq 1 && &is_integer($userCmd) && $userCmd ge 1 && $userCmd le 9) {
               $verbose = $userCmd;
               print "Verbose level set to $verbose";
               $skipReadData = 1;
               $wcCmd="";
            } else {
              if ($userCmd eq "X") {
                 $forcedDiscover = 1;
                 $select->remove($wcsock);
                 close($wcsock);
                 logMsg(1, "Closed WC port\n");
                 &doDiscoverReadOnly;
                 $pos=0; # default to first detected device
                 &selectDevice;
                 $skipReadData = 1;
                 $wcCmd="";
              } else {
                if ($userCmd eq "d2h") {
                   &dec2hex;
                   $skipReadData = 1;
                   $wcCmd="";
                } else {
                    $wcCmd="^^Id$userCmd";
                    if ($wcaddr[$pos] eq $bcaddr) {
                       &connectBC($wcCmd);
                    } else {
                      $wcsock->send("$wcCmd\r", 0, $wcipaddr);
                    }
                    logMsg(1, "Sent $wcCmd\n");   
                }
              }
            }
          }
        }
    }

    if (!$skipReadData) {
       # read data from wc device
       $timeout = 5;
       &getPacket;
       $timeout = 3;
       for (@ready = 0; @ready != 0;) { &getPacket; }
    }
    $skipReadData = 0;
    print "\n\n[",&whichDeviceIP,"] ",$prompt;

}

# Locate a WC Ethernet Link Device
# unlike doDiscover, this routine does NOT send packets that could modify
# the configuration of discovered devices
sub doDiscoverReadOnly {
  logMsg(1, "Attempting to discover Whozz Calling Ethernet Link Devices...\n");
  @wcaddr=();
  @wcports=($wcport);
  $pos=0; # force default port
  &connectWC;
  &connectBC("^^IdX");
  # read data from wc device
  $pos = -1;
  $timeout = $defaultTO;
  &getDiscoverReadOnlyPackets;
  $timeout = $defaultTO;
  for (@ready = 0; @ready != 0;) { &getDiscoverReadOnlyPackets; }
  errorExit("Whozz Calling Ethernet Link Device not found\n") if $pos == -1;
  my $num = $pos +1;
  logMsg(1, "\n$num Whozz Calling Ethernet Link Devices were found\n");
   # add broadcast so we can select "ALL DEVICES"
   push(@wcaddr, $bcaddr); 
   $wcports[$#wcaddr] = $wcport; 
   $wc[$#wcaddr]{I} = $bcaddr;

}

sub selectDevice {

  errorExit("No Whozz Calling Ethernet Link Devices were found\n") if ! @wcaddr;
  
  my $savepos = $pos;
  my $num;
  my $msgbuf;
  my ($wcAddrP1,$wcAddrP2,$wcAddrP3,$wcAddrP4);
  my $def;

  if ($#wcaddr>1 || $forceSelect) {
     print "\nSelect the device you want to work with:\n\n"; 

     logMsg(1, " #        IP Address   Port#  Unit#               Serial#         MAC Address\n");
     logMsg(1, " -     --------------- -----  -----           ---------------  -----------------\n");
     
     for ($pos = 0; $pos < $#wcaddr + 1; $pos++) {
         $num = $pos +1;
         $def = $savepos eq $pos ? "***" : "";
         if ($wcaddr[$pos] eq $bcaddr) {
            $msgbuf=sprintf("%2d %3s ALL DEVICES\n",$num, $def);
         } else {
           if (!$wc[$pos]{I}) {
              ($wcAddrP1, $wcAddrP2, $wcAddrP3, $wcAddrP4) = split(/\./, $wcaddr[$pos]);
              $msgbuf=sprintf("%2d %3s %3d.%3d.%3d.%3d %5d  %s\n",
              $num,$def,$wcAddrP1,$wcAddrP2,$wcAddrP3,$wcAddrP4,
            $wcports[$pos],"DEVICE NOT FOUND");
           } else {
             ($wcAddrP1, $wcAddrP2, $wcAddrP3, $wcAddrP4) = split(/\./, $wc[$pos]{I});
             $msgbuf=sprintf("%2d %3s %3d.%3d.%3d.%3d %5d  %-14.14s  %s  %s\n",
             $num,$def,$wcAddrP1,$wcAddrP2,$wcAddrP3,$wcAddrP4,
             $wc[$pos]{T},$wc[$pos]{U},$wc[$pos]{S},$wc[$pos]{M});
           }
         }
         logMsg(1, $msgbuf);	   
     }

     my $invalid = 1;
     while ($invalid) {
        print "\nEnter your selection (1-$num) or <ENTER> for default (***):";
        my $tmp=(<STDIN>);
        chomp($tmp);
        if ((length($tmp)) eq 0 || ($tmp-1 eq $savepos)) {
           $pos=$savepos;
           logMsg(1, "No change, still connected to " . &whichDeviceIP . "\n");
           $invalid = 0;
        } else {
          if (&is_integer($tmp) && $tmp && defined $wcaddr[$tmp-1] &&
             ($tmp-1 ne $savepos) && $wc[$tmp-1]{I}) {
           $select->remove($wcsock);
           $wcsock->close();
           $pos=$tmp-1;
           &connectWC;
           $wcipaddr = sockaddr_in($wcports[$pos], inet_aton($wcaddr[$pos]));
           logMsg(1, "\nNow connected to " . &whichDeviceIP . "\n");
           $invalid = 0;
           } else {
             print "\n***** INVALID ENTRY *****\n";
           }
        }
      }
   }  
}

sub dec2hex {

   print "\nEnter decimal number or an IP address in the form nnn.nnn.nnn.nnn:";
   my $tmp=(<STDIN>);
   chomp($tmp);
   my @decimals = split(/\./,$tmp);
   my $hexResult ="";

   foreach (@decimals) {
     $hexResult = $hexResult . &integerToMultiByteString(0,$_);
   }  

   print "'$tmp' converted to hex is '",uc(unpack('H*',$hexResult)),"'\n";
   
}	 


#http://stackoverflow.com/questions/12647/how-do-i-tell-if-a-variable-has-a-numeric-value-in-perl
sub is_integer {
   defined $_[0] && $_[0] =~ /^[+-]?\d+$/;
}

sub whichDeviceIP {
    return $wcaddr[$pos] eq $bcaddr ? "ALL DEVICES" : "$wcaddr[$pos]:$wcports[$pos]";
}

sub resetWC {
  # Reset the Whozz Calling Ethernet Link Device.

  $wclines = 0;
  $wcCmd = "^^Id-R";
  send($wcsock, $wcCmd, 0, $wcipaddr);
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcports[$pos]\n");
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
  logMsg(1, "WC-$num has $wclines telephone lines\n");
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
    $wcipaddr = sockaddr_in($wcports[$pos], inet_aton($addr));
    send($wcsock, $wcCmd, 0, $wcipaddr);
    logMsg(1, "Sent \"$wcCmd\" to $addr:$wcports[$pos]\n");
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

  $wcipaddr = sockaddr_in($wcports[$pos], inet_aton($wcaddr[$pos]));

  # reset the WC to get total number of telephone lines supported
  &resetWC;
  if (!$wclines) { errorExit("Could not reset WC-$num"); return; }

  # use the unit number to store the number of telephone lines
  $wcCmd = "^^IdU00000000000$wclines\r";
  send($wcsock, $wcCmd, 0, $wcipaddr);
  $wcCmd =~ s/\r$//;
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcports[$pos]\n");
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
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcports[$pos]\n");
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
  $wcipaddr = sockaddr_in($wcports[$pos], inet_aton($wcaddr[$pos]));
  $wcCmd = "^^IdX";
  send($wcsock, $wcCmd, 0, $wcipaddr);
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcports[$pos]\n");
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
      push(@missingwc, "WC-$num ($wcaddr[$pos])");
      return;
    }
  }

  # WC device was found
  &decodePacket;
  push(@gotwc, "WC-$num ($wcaddr[$pos])");

  $wcCmd = "^^Id-V";
  send($wcsock, $wcCmd, 0, $wcipaddr);
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcports[$pos]\n");
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
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcports[$pos]\n");
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
  $wcports[$pos] = $foundWC[0]{T};

  $wcipaddr = sockaddr_in($wcports[$pos], inet_aton($wcaddr[$pos]));
  $wcCmd = "^^IdX";
  send($wcsock, $wcCmd, 0, $wcipaddr);
  logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcports[$pos]\n");
  &getPacket;
  errorExit("No response from Whozz Calling\n") if ! @ready;
}

# open a socket to receive packets from one or more WC Ethernet Link Devices
sub connectWC {
  $wcsock = IO::Socket::INET->new(
    Proto     => 'udp',
    LocalPort => $wcports[$pos]
  );

  # $wcsock undefined if could not connect to server
  errorExit("ERROR in WC Socket Creation : $!") if !defined $wcsock;

  #When waiting for responses to a broadcast command (like '^^IdX'), the
  #port# used by connectWC needs to match the port# used when creating the
  #broadcast socket. Port# (e.g., 4000) isn't important as long as it matches.
  #
  #When waiting for responses from a device where the socket is tied to a 
  #specific (non-broadcast) IP address, use the device's configured 'T' port.
  
  logMsg(1, "Opened Whozz Calling Ethernet Link Device port: $wcports[$pos]\n");

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
        $gotdata = 1;
        # only one response wanted
        last;
    }
  } else {
     # if called in a loop until a timeout, do not show the end timeout
     if ($gotdata) {
        $gotdata = 0;
     } else {
       my $msg;
       if (length($wcCmd)) { $msg= "command \"$wcCmd\" timed out with ";}
       $msg = $msg . "no data received in $timeout seconds\n";
       logMsg(1, $msg);
     }
  }
}

sub getDiscoverReadOnlyPackets {
  @ready = $select->can_read($timeout);
  foreach $rh (@ready) { 
    $rh->recv($wcdata, 90, 0);
    logMsg(1, "Received response from \"$wcCmd\" command\n");
    if ('$' eq substr($wcdata, 21, 1)) {$wcline = substr($wcdata, 22);}
    else {$wcline = substr($wcdata, 21);}
    $pos++;
    &decodePacket;
    $wcaddr[$pos]=$wc[$pos]{I};
    $wcports[$pos]=$wc[$pos]{T};
    my $f = new Data::HexDump;
    $f->data($wcdata);
    logMsg(4, "Packet size: " . length($wcdata) . "\n" . $f->dump . "\n");
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
    PeerPort  => $wcports[$pos],
    LocalPort => $wcports[$pos]
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
        logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcports[$pos]\n");
        &getPacket;
    }
    if ($wc[$pos]{F} =~ /.*D.*/) {
        $wcCmd = "^^Id-d";
        send($wcsock, $wcCmd, 0, $wcipaddr);
        logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcports[$pos]\n");
        &getPacket;
    }
    if ($wc[$pos]{F} =~ /.*a.*/) {
        $wcCmd = "^^Id-A";
        send($wcsock, $wcCmd, 0, $wcipaddr);
        logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcports[$pos]\n");
        &getPacket;
    }
    if ($wc[$pos]{F} =~ /.*O.*/) {
        $wcCmd = "^^Id-o";
        send($wcsock, $wcCmd, 0, $wcipaddr);
        logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcports[$pos]\n");
        &getPacket;
    }
    if ($wc[$pos]{F} =~ /.*t.*/) {
        $wcCmd = "^^Id-T";
        send($wcsock, $wcCmd, 0, $wcipaddr);
        logMsg(1, "Sent \"$wcCmd\" to $wcaddr[$pos]:$wcports[$pos]\n");
        &getPacket;
    }
    $ignoreTO = 0;
}

sub integerToMultiByteString {
    my $l = shift; # length, if zero use as many bytes as needed to 'fit' number
    my $d = shift; # decimal to convert
    my $m = ""; # resulting multibyte string
    my $fit;

    if ($l) {
       # length is known
       $fit = 0; 
       $l--;
    } else {
       # length is unknown
       if ($d eq 0) {return "\x00";}
       $fit = 1;
       $l = 8; # we shouldn't need more than 8 bytes
    }

    for (my $i = $l; $i >= 0; $i--) {
        my $temp = int($d/(256**$i));
        if ($fit && $temp eq 0 && length($m) eq 0) {next;} # loop until first dividend is non-zero
        $m = $m . pack('C', $temp);
        $d = $d - $temp*(256**$i);
        if ($fit && $d lt 0) {last;}
    }

    return $m
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

sub errorExit {
    logMsg(1, "@_");
    if ($pid) {
        unlink($pidfile);
        logMsg(1, "Removed $pidfile\n");
    }
    my $date = strftime("%m/%d/%Y %H:%M:%S", localtime);
    logMsg(1, "\nTerminated: $date\n");
    close(LOGFILE);
    exit(-1);
}

=head1 NAME

wct - Whozz Calling Ethernet Link Device interactive tool

=head1 SYNOPSIS

wct [--debug|-D]
    [--help|-h]
    [--logfile-append|-l <filename>]
    [--logfile-overwrite|-L <filename>]
    [--configfile|-C <filename>]
    [--man|-m]
    [--set-wc]
    [--pidfile|-p <filename>]
    [--discover|--discovery|-d]
    [--discover-loop|--discovery-loop <secs>]
    [--verbose|-v <1-9>]
    [--version|-V]
    [--wchost|-w <address1>[,address2][,...]

=head1 DESCRIPTION

This script allows you to interact with a Whozz Calling device in
order to view or change its configuration. This script is generic
as configuration settings vary depending on the Whozz Calling
model and firmware version.

Enter the commands one per line, or simply hit <ENTER> alone
to see if there are pending responses.

DO NOT type the '^^Id' prefix as it will be included automatically.

=head1 OPTIONS

=over 2

=item -w <address1[,address2][,...]>, --wchost=<address1[,address2],[,...]>

Specifies the Whozz Calling Ethernet Link Device or devices.
Multiple addresses for devices are comma separated.

Input must be <address> or <address1,address2,etc>.

Default: 192.168.0.90

This option is ignored if --discover or --discover-loop is
in effect.

=item -D, --debug

Debug mode, displays all messages that go into the log file.

=item -h, --help

Prints the help message and exits.

=item -m, --man

Prints the manual page and exits.

=item -C, --configfile=<filename>

Specifies the configuration file to use.  The program will still run if
a configuration file is not found.

If --discover or --discover-loop is in effect, the configuration
file will still be processed but any "wcaddr" addresses will be
ignored.

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

This option is ignored if --discover or --discover-loop is
in effect.

=item -l, --logfile-append=<filename>

=item -L, --logfile-overwrite=<filename>

Specifies the logfile name to write.  The program will still run if
it does not have permission to write to it.

If both options are present, --logfile-append takes precedence.

Default: Append to wct.log in your current directory.

=item -p, --pidfile=<filename>

Specifies the pidfile name to write. The program will still run if
it does not have permission to write a pidfile. The pid filename that
should be used is /var/run/wc2ncid.pid.

Default: no pidfile

=item -d, --discover, --discovery
=item --discover-loop <secs>, --discovery-loop <secs>

Force discovery of all powered-on Whozz Calling Ethernet Link Devices.
IP addresses in the configuration file, or on the command line, will be
ignored.

Using --discover-loop causes continuous looping with a new discovery
("^^IdX") being sent every <secs> seconds.

Normal invocation of this script functions the same as wc2ncid, including
the initialization of each device's configuration "toggles." Use the
--discover or --discover-loop options if you want to bypass this
initialization.

=item -v, --verbose <1-9>

Output information, used for the logfile and the debug option.  Set
the level to a higher number for more information.  Levels range from
1 to 9, but not all levels are used.

Default: verbose = 1

=item -V, --version

Displays the version.

=back

=head1 EXAMPLES

=over 2

=item Start wct and look for all powered-on devices:

wct -d

=item Start wct, set IP address to 192.168.1.90 from command
line, set the beginning line number automatically, and set the
sending Ethernet port to 3520 (the default):

wct --set-wc --wchost 192.168.1.90

=back

=head1 INTERACTIVE COMMAND MODE

=over 2

=item d2h

Decimal-to-hex conversion. 

User will be asked for the decimal number to be converted to hex.

An IP address may also be typed (e.g., 192.168.1.90) to show the
proper hex digits for the 'D' and 'I' commands.

=item help

Displays this interactive command mode help. Press letter 'q'
to return to the command prompt at any time.

=item select

When multiple Whozz Calling Ethernet Link Devices are being used,
allows selecting which one to interact with.

A special "ALL DEVICES" choice is also available, meaning all typed
commands will be broadcast to all devices. For example, selecting "ALL
DEVICES" and then typing the Z command will cause all powered on devices
to be reset to their factory defaults. Use "ALL DEVICES" with care
because you could set all devices to have the same IP address, same
MAC address, etc.

=item 1-9

Entering a single digit changes the verbosity level on-the-fly.

=back

Not all of the commands below are supported by all WC devices.

=head2 Single character commands

=over 8

=item N

Set destination IP and MAC addresses to THIS computer.

=item X

Show unit#, serial#, network settings. This command can be used
to discover all powered-on WC devices. It is the same as runnning 
wct with the --discover command line option.

=item Z

Reset unit# to '123' and network settings to factory defaults;
does NOT change: toggles, block/pass numbers in memory, date/time or
the device's starting line#. See also "Other ways to reset a device" on the
last page of this manual.

Settings changed by this command will not be reflected under the 'select'
menu until the next time you do an 'X' to discover all available devices.

=back

=head2 Two character commands

=over 8

=item -@

Causes a device to respond with "#" sign. Can be used for establishing 
device communication.

=item -J

Show contents of block/pass numbers stored in memory. Be sure to first
set the verbose level to 4 or greater to see the actual numbers.

=item -R

Perform power-on reset and sets all toggles to uppercase. Leaves
network configuration, and block/pass memory, and the device's starting 
line# unchanged. See also "Other ways to reset a device" on the last
page of this manual.

=item -t

Where 't' is any single toggle, case sensitive (e.g., -E, -b).

Uppercase usually means the feature/setting is OFF, lowercase means it is ON.

=over 2

 E, e   Command echo
 C, c   Leading '$' and dashes in numbers (wc2ncid and wct
        always strip both)
 X, x   Comprehensive (X) or limited (x) data format
 U, u   Use phone numbers in internal block/pass memory
 D, d   Detail information (rings, hook on/off/flash)
 A, a   Data sent at start AND end of a call
 S, s   See below
 O, o   Only inbound (O) calls reported, or inbound and 
        outbound (o)
 B, b   Suppress first ring (B) or always pass through (b)
 K, k   See below
 T, t   Inbound DTMF monitoring

 The 'U' and 'A' toggles each have a companion toggle as
 described below.
 
 If 'U' is set, blocking/passing is turned OFF and toggles
 'K' and 'k' are ignored.
 
 If 'u' is set, blocking/passing is turned ON. The toggle 'K'
 will pass all calls by default (i.e., only the phone numbers
 in the internal memory will be blocked) and 'k' will block
 all calls by default (i.e., only the phone numbers in the 
 internal memory will be passed through).
 
 If 'A' is set, data is sent at the start AND end of a call, 
 and toggles 'S' and 's' are ignored.
 
 If 'a' is set, data is sent only at start(S) or end(s) of a
 call.

=back

=back
 
=over 8
 
=item -V

Show processor version, all toggles, line# of channel 1, date, time.

=item -v

Show internal jumper settings.

=back

=head2 Multiple character commands requiring HEX digits.

Numbers in parens () indicate required number of hex digits.

Commands I, T and U are typically the only ones that will be
used.

Hex digits A - F may be entered in lowercase or uppercase.

=over 8

=item Chhhhhhhhhhhh

Set destination MAC address (12) of the computer to receive WC data
(use all 'F's for entire LAN).

=item Dhhhhhhhh

Set destination IP address (8) of the computer to receive WC data
(use all 'F's for entire LAN).

=item Ihhhhhhhh

Set device IP address (8).

Changing the IP address will not be reflected under the 'select' menu
until the next time you do an 'X' to discover all available devices.

=item Mhhhhhhhhhhhh

Set device MAC address (12).

Changing the MAC address will not be reflected under the 'select' menu
until the next time you do an 'X' to discover all available devices.

=item Phhhh

Set destination port number (4 hex digits) of the computer to receive
WC data. This is normally 0DC0, or 3520 in decimal.

It is very rare that this command would be used. You most likely would
want to use 'Thhhh' instead.

=item Thhhh

Set device port number (4 hex digits). This is normally 0DC0, or 3520
in decimal.

Changing the port number will not be reflected under the 'select' menu
until the next time you do an 'X' to discover all available devices.

=item Uhhhhhhhhhhhh

Set unit number (12).

Changing the unit number will not be reflected under the 'select' menu
until the next time you do an 'X' to discover all available devices.

Note that wc2ncid will change and use the unit number to track the
number of telephone lines (2, 4, or 8) that can be connected to the
device. This is used when establishing the starting line# of channel#1,
i.e., the "L=xx" parameter seen when executing the '-V' command.

=back

=head2 Multiple character commands requiring DECIMAL digits.

Normally these require a terminating carriage return character, 
but the wct script takes care of this for you by sending a
terminating carriage return after all commands.

=over 8

=item -Nnnnnnnnnnnnn

Add a 7 to 12 digit phone number to block/pass memory, maximum of 
40 phone numbers.

The WC device will not check to see if the number you're adding is
already stored in memory. It lets you add duplicates.

If the memory becomes full, additional numbers will be silently
ignored.

=item -N66

Add Out-of-area callers to block/pass memory. '-J' command will
list as the letter 'O' ("oh") and not '66'. This counts against
the maximum of 40 phone numbers.

=item -N77

Add Private callers to block/pass memory. '-J' command will list
as the letter 'P' and not '77'. This counts against the maximum
of 40 phone numbers.

=item -N00000077nn

Special undocumented command to set line# of channel#1 instead of
using the 'Line No. Select' button on back of the device. And unlike the
'Line No. Select' button, you're not restricted to increments of four.
'nn' is base 16 but accepts digits only (no letters 'A' to 'F').
For example, '-N0000007710' sets line# to '16' not '10'.

The echo toggle ('E') must be OFF for this setting to be saved in the 
device's memory.

You should wait at least 9 seconds after sending this command before 
sending the next one. Otherwise, the next command sent may be ignored.

Unlike the other uses of '-N', this special command does not affect 
the internal block/pass memory.

=item -Wnn

If toggle 'u' is set, block or pass the real-time inbound call on 
logical line 'nn'. Note that this is NOT the physical channel# that 
a phone line is hooked into.

=item -Zmmddhhmm

Manually set date and time (24 hour format). Normally the date and
time are set automatically by the first incoming ring.

=back

=head2 Other ways to reset a device

The download section at CallerID.com has a Windows program called 
"EL Config". To use wct to emulate the EL Config reset options, do 
the following commands:

Config->Reset Unit Defaults

    -N0000007701
    -R

=over 4      
      
The above sets the line# of channel#1 ('N') to be 1, followed by 
a power-on reset ('R') that sets all toggles to uppercase. It does 
not change the network settings nor the block/pass memory.

=back
      
Config->Reset Ethernet Defaults      

    DFFFFFFFF
    U000000000001
    IC0A8005A
    CFFFFFFFFFFFF
    T0DC0

=over 4
      
The above will set the destination IP address ('D') to be the entire
LAN, the unit number ('U') to 1, the device's IP address ('I') to 
192.168.0.90, the destination MAC address ('C') to be the entire LAN, 
and the device's port# ('T') to 3520. It does not change the device 
toggles, nor the block/pass memory, nor the device's starting 
line#.

=back
      
=head1 REQUIREMENTS

perl 5.6 or higher,
perl(Config::Simple),
perl(Data::HexDump)

=head1 FILES

/etc/ncid/wc2ncid.conf

=head1 SEE ALSO

ncidd.8,
wc2ncid.8,
wc2ncid.conf.5

=cut

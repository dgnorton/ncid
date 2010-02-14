#!/usr/bin/perl

# Copyright (c) 2006 by Clayton O'Neill
# Copyright (c) 2006, 2007, 2008, 2009, 2010
# by John L. Chmielewski <jlc@users.sourceforge.net>

# ncidsip is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# any later version.

# ncidsip is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA

use strict;
use warnings;

use Net::Pcap;
use POSIX qw(strftime);
use IO::Socket::INET;
use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case_always);
use Pod::Usage;

our $VERSION = "(NCID) XxXxX";

my ($host, $port) = ('localhost', 3333);
my ($siphost, $sipport) = ('', 10000);
my $dumpfile;
my $interface;
my $debug = 0;
my $verbose = '';
my ($help, $version);
my $sock = undef;
my $test = 0;
my @locals;
my $listdevs = 0;
my $pidfile = "";
my $savepid;
my $pid = 0;
my @callids;
my $callid;
my @tcallids;
my $tcallid;

my $result = GetOptions("ncid=s" => \$host,
               "dumpfile|d=s" => \$dumpfile,
               "interface=s" => \$interface,
               "sip=s" => \$siphost,
               "debug|D" => \$debug,
               "help" => \$help,
               "usage" => \$help,
               "verbose|v" => \$verbose,
               "version|V" => \$version,
               "test" => \$test,
               "listdevs" => \$listdevs,
               "pidfile|p=s" => \$pidfile
             ) || pod2usage(2);

die "ncidsip $VERSION\n" if $version;

pod2usage(-verbose => 2) if $help;

$port = $1 if $host =~ s/:(\d+)//;
$sipport = $1 if $siphost =~ s/:(\d+)//;

if ($listdevs) {
  my $err = 0;
  my @devs;
  my %devinfo;
  @devs = Net::Pcap::findalldevs(\%devinfo, \$err);
  for my $dev (@devs) {
    print "$dev : $devinfo{$dev}\n";
  }
  exit 0;
}

if ($test) {
  $verbose = 1;
  $debug = 1;
} else {
  # Only create a PID file if $pidfile is set to one.
  if ($pidfile ne "") {
    if (-e $pidfile) {
      # only one instance per computer permitted
      unless (open(PIDFILE, $pidfile)) {
        die "pidfile exists and is unreadable: $pidfile\n";
      }
      $savepid = <PIDFILE>;
      close(PIDFILE);
      chop $savepid;
      if (-d "/proc/$savepid") {
        die "Process ($savepid) already running: $pidfile\n";
      } else {
        print "Found stale pidfile: $pidfile\n" if $verbose;
      }
    }

    if (open(PIDFILE, ">$pidfile")) {
      print(PIDFILE "$$\n");
      $pid = $$;
      close(PIDFILE);
      print "Wrote pid $pid in $pidfile\n" if $verbose;
    }else{
      print "Could not write pidfile: $pidfile\n" if $verbose;
    }
  }

  &connectNCID;
  errorExit("Could not connect to NCID server: $!\n") if !defined $sock;
}

my ($err, $pcap);
if (defined $dumpfile) {
  $pcap = Net::Pcap::open_offline($dumpfile, \$err);
  errorExit("Could not open $dumpfile: $err\n") if defined $err;
} else {
  if (!defined $interface) {
    $interface = Net::Pcap::lookupdev(\$err);
      errorExit("No interface name provided and was unable to find one: $err\n")
        if defined $err;
  }
  print "Opening '$interface'\n" if $verbose;
  $pcap = Net::Pcap::open_live($interface, 1500, 1, 100, \$err);
  errorExit ("Could not open $interface: $!\n") if defined $err;

  my ($net, $mask);
  Net::Pcap::lookupnet($interface, \$net, \$mask, \$err);
  errorExit("Could not get interface information: $!\n") if defined $err;

  my $filter;
  my $filter_str = "host $siphost and port $sipport and udp";
  if (!$siphost =~ /\w/) { $filter_str =~ s/.*(port.*)/$1/; }
  print "filter: $filter_str\n" if $verbose;

  my $res = Net::Pcap::compile($pcap, \$filter, $filter_str, 0, $mask);
  $err = Net::Pcap::geterr($pcap);
  errorExit("Could not compile filter: $err\n") if $res != 0;
  Net::Pcap::setfilter($pcap, $filter);
}

$SIG{'HUP'} = 'sigHandle';
$SIG{'INT'} = 'sigHandle';
$SIG{'QUIT'} = 'sigHandle';
$SIG{'TERM'} = 'sigHandle';

Net::Pcap::loop($pcap, -1, \&processPacket, undef);

sub processPacket {
  my ($userdata, $header, $packet) = @_;
  my $ip = substr($packet, 14);
  my $iplen = (unpack('C', $ip) & 0x0F) * 4;
  my $udp = substr($ip, $iplen);
  my $sip = substr($udp, 8);
  my $name;
  my $number;
  my $tonumber;
  my $line;
  my $toline;
  my $msg;

  print $sip,"\n" if $debug;

  if (!$test) {
    if (defined $sock) {while (<$sock>) {print if $verbose;}}
    # $! (errno) == 0 if server disconnected
    # $sock undefined if could not connect to server
    if ($! == 0 || !defined $sock) {&connectNCID};
    return if !defined $sock;
  }

  my $date = strftime("%m%d%H%M", localtime($header->{tv_sec}));
  if ($sip =~ /^CSeq:\s+\d+\s+INVITE/imo) {
      # Start of Call
      if (!$sip =~ /^SIP\/.*Request Terminated/imo) {return}
      if ($sip =~ /^Call-ID: ([0-9_@.]+)/imo) {
        $callid = $1;
      } else {print "No INVITE Call-ID found in packet\n" if ($debug);}

      if (grep(/$callid/, @callids)) {
        # Call already processed
        return;
      } else {
        # New Call
        push(@callids, $callid);
        print "Adding $callid to CallID list\n" if ($debug);
      }

      if ($sip =~ /^To:\s+<sip:(.+)(\w\w\w\w)@/imo) {
        $tonumber = "$1$2";
        $toline = $2;
      } else {$line = "UNKNOWN";}

      if ($sip =~ /^From:\s+\"?(.+?)"?\s+<sip:/imo) {
        $name = $1;
      } else {$name = "NO NAME";}

      if ($sip =~ /^From:.*<sip:(.+)(\w\w\w\w)@/imo) {
        ($number) = "$1$2";
        $line = $2;
        } else {$number = "NO NUMBER";}

      if (grep(/^$number$/, @locals)) {
        # Outgoing Call
        $msg = sprintf("CALLINFO: ###CALLED...DATE%s...LINE%s...NMBR%s+++",
                        $date, $line, $tonumber);
      } else {
        # Incoming Call
        $msg = sprintf("CALL: ###DATE%s...LINE%s...NMBR%s...NAME%s+++",
                        $date, $toline, $number,$name);
      }

      print $msg, "\n" if $verbose;
      if (!$test) { print $sock $msg, "\r\n"; }

  } elsif ($sip =~ /^CSeq:\s+\d+\s+CANCEL/imo) {
      # Hangup before answer
      if ($sip =~ /^Call-ID:(.+)@/imo) {
        $callid = $1;
      } else {print "No CANCEL Call-ID found in packet\n" if ($debug);}
      @tcallids = @callids;
      @callids = ();
      foreach $tcallid (@tcallids) {
        if ($tcallid ne $callid) {
          push (@callids, $tcallid);
        } else {
          if ($sip =~ /^From:.*<sip:(.+)(\w\w\w\w)@/imo) {
            ($number) = "$1$2";
            $line = $2;
          } else {$number = "NO NUMBER";}

          if ($sip =~ /^To:.*<sip:(.+)(\w\w\w\w)@/imo) {
            ($tonumber) = "$1$2";
            $toline = $2;
          } else {$tonumber = "NO NUMBER";}

          if (grep(/^$number$/, @locals)) {
            # number is in the To line instead of From line
            $msg = sprintf("CALLINFO: ###CANCEL...DATE%s...LINE%s...NMBR%s+++",
                            $date, $line, $tonumber);
          } else {
            $msg = sprintf("CALLINFO: ###CANCEL...DATE%s...LINE%s...NMBR%s+++",
                            $date, $toline, $number);
          }

          print "Removed $callid from CallID list\n" if ($debug);
          print $msg, "\n" if $verbose;
          if (!$test) { print $sock $msg, "\r\n"; }
        }
      }

  } elsif ($sip =~ /^CSeq:\s+\d+\s+BYE/imo) {
      # Hangup After answer
      if ($sip =~ /^Call-ID:(.+)@/imo) {
        $callid = $1;
      } else {print "No BYE Call-ID found in packet\n" if ($debug);}
      @tcallids = @callids;
      @callids = ();
      foreach $tcallid (@tcallids) {
        if ($tcallid ne $callid) {
          push (@callids, $tcallid);
        } else {
          if ($sip =~ /^From:.*<sip:(.+)(\w\w\w\w)@/imo) {
            ($number) = "$1$2";
            $line = $2;
          } else {$number = "NO NUMBER";}

          if ($sip =~ /^To:.*<sip:(.+)(\w\w\w\w)@/imo) {
            ($tonumber) = "$1$2";
            $toline = $2;
          } else {$number = "NO NUMBER";}

          if (grep(/^$number$/, @locals)) {
            # number is in the To line instead of From line
            $msg = sprintf("CALLINFO: ###BYE...DATE%s...LINE%s...NMBR%s+++",
                            $date, $line, $tonumber);
          } else {
            $msg = sprintf("CALLINFO: ###BYE...DATE%s...LINE%s...NMBR%s+++",
                            $date, $toline, $number);
          }

          print "Removed $callid from CallID list\n" if ($debug);
          print $msg, "\n" if $verbose;
          if (!$test) { print $sock $msg, "\r\n"; }
        }
      }

  } elsif ($sip =~ /^CSeq:\s+\d+\s+REGISTER/imo) {
      $sip =~ /^Contact:\s+.*?<sip:(.+?)@/imo;
      if (!grep(/^$1$/, @locals)) {
        push(@locals, $1);
        print "Adding $1 to local number list\n" if ($debug);
      }
  }
}

sub connectNCID {
  print "NCIDsip Version $VERSION\n" if $verbose;
  print "Connecting to NCID server on $host:$port\n" if $verbose;
  $sock = IO::Socket::INET->new(PeerAddr => $host,
                 PeerPort => $port,
                 Proto => 'tcp',
               );
  defined $sock || return;

  my $greeting = <$sock>;
  print "Connected: $greeting" if $verbose;

  $sock->blocking(0);
  while (<$sock>) {print if $verbose;}
}

sub sigHandle {
    my $sig = shift;
    print "Terminating: Caught SIG$sig\n" if $verbose;
    if ($pid != 0) {unlink($pidfile);}
    exit(0);
}

sub errorExit {
    printf "@_";
    if ($pid != 0)
    {
        unlink($pidfile);
        print "Removed $pidfile\n" if $verbose;
    }
    exit(-1);
}

=head1 NAME

ncidsip - Inject CID info by snooping SIP invites

=head1 SYNOPSIS

ncidsip [--sip|-s <[host][:port]>] [--ncid|-n <host[:port]>] [--debug|-D] [--dumpfile|-d <filename>] [--interface|-i <interface>] [--help|-h] [--version|-V] [--verbose|-v] [--test|-t] [--usage|-u] [--listdevs|-l] [--pidfile|p <filename>]

=head1 DESCRIPTION

Snoops SIP INVITES via libpcap and injects the caller id information
found to the NCID server specified.  Uses L<Net::Pcap> to interface
with the libpcap library and snoops only udp traffic on the specified
SIP host and port.

=head1 OPTIONS

=over 2

=item -D, --debug

Display the payload of all packets that matched the libpcap filter.

=item -d, --dumpfile <filename>

Read packets from a libpcap capture file instead of the network.
Mostly only useful for development purposes.

=item -h, --help

Prints this help

=item -i, --interface=<interface>

Specifies the network interface to snoop on.  If this is not specified
then libpcap will pick a network interface.  This will generally be
the first ethernet interface found.

=item -l, --listdevs

Returns a list of all network device names that can be used.

=item -n, --ncid=<host[:port]>

Specifies the NCID server to connect to.  Port may be specified by
suffixing the hostname with :<port>.  By default it will connect to
port C<3333> on C<localhost>.

=item -s, --sip=<[host][:port]>

Specifies the hostname of the SIP devie to snoop.  You may also
specify the UDP port by suffixing the hostname with :<port>, or
if no hostname wanted, just :<port>.  If you do not specify a host,
it defaults to the network interface.  If you do not specify a port,
it defaults to <5061> (Vonage default).

=item -p, --pidfile=<filename>

Specifies the pidfile name to write.  The program will still run if
it does not have permission to write a pidfile.
The default pidfile name is /var/run/ncidsip.pid.

=item -t, --test

Test for SIP packets.  This option is used to check if SIP packets
exist without starting the NCID server.  It will display the Caller
ID line generated when a call comes in, and a CANCEL line if cancel
was generated.

=item -u, --usage

Prints this help

=item -V, --version

Displays the version

=item -v, --verbose

Displays status.  Use this option to run interactive.

=back

=head1 REQUIREMENTS

perl 5.6 or higher

L<Net::Pcap>

=head1 BUGS

This program takes a rather ad-hoc approach to parsing UDP datagrams
to avoid additional module dependencies.  As a result, it very likely
doesn't handle VLANs correctly.  If anyone actually wants it to work
with VLANS, feel free to email me and I'll take a look at it.

=head1 AUTHOR

Clayton O'Neill <claytononeill@users.sourceforge.net>

=cut

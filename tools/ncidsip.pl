#!/usr/bin/perl

use strict;
use warnings;

use Net::Pcap;
use POSIX qw(strftime);
use IO::Socket::INET;
use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case_always);
use Pod::Usage;

our $VERSION = "0.2.0";

my ($host, $port) = ('localhost', 3333);
my ($siphost, $sipport) = ('', 5061);
my $dumpfile;
my $interface;
my $debug = 0;
my $verbose = '';
my ($help, $version);
my $sock = undef;

my $result = GetOptions("ncid=s" => \$host,
               "dumpfile=s" => \$dumpfile,
               "interface=s" => \$interface,
               "sip=s" => \$siphost,
               "debug" => \$debug,
               "help" => \$help,
               "usage" => \$help,
               "verbose|v" => \$verbose,
               "version|V" => \$version,
             ) || pod2usage(2);

die "ncid-sipinject: version $VERSION\n" if $version;

pod2usage(-verbose => 2) if $help;

$port = $1 if $host =~ s/:(\d+)//;
$sipport = $1 if $siphost =~ s/:(\d+)//;

&connectNCID;
die "Could not connect to NCID server: $!\n" if !defined $sock;

my ($err, $pcap);
if (defined $dumpfile) {
  $pcap = Net::Pcap::open_offline($dumpfile, \$err);
  die "Could not open $dumpfile: $err\n" if defined $err;
} else {
  if (!defined $interface) {
    $interface = Net::Pcap::lookupdev(\$err);
    if (defined $err) {
      die "No interface name provided and was unable to find one: $err\n";
    }
  }
  print "Opening '$interface'\n" if $verbose;
  $pcap = Net::Pcap::open_live($interface, 1500, 1, 100, \$err);
  die "Could not open $interface: $!\n" if defined $err;

  my ($net, $mask);
  Net::Pcap::lookupnet($interface, \$net, \$mask, \$err);
  die "Could not get interface information: $!\n" if defined $err;

  my $filter;
  my $filter_str = "host $siphost and port $sipport and udp";
  if (!$siphost =~ /\w/) { $filter_str =~ s/.*(port.*)/$1/; }
  print "filter: $filter_str\n" if $verbose;

  my $res = Net::Pcap::compile($pcap, \$filter, $filter_str, 0, $mask);
  $err = Net::Pcap::geterr($pcap);
  die "Could not compile filter: $err\n" if $res != 0;
  Net::Pcap::setfilter($pcap, $filter);
}

Net::Pcap::loop($pcap, -1, \&processPacket, undef);

sub processPacket {
  my ($userdata, $header, $packet) = @_;
  my $ip = substr($packet, 14);
  my $iplen = (unpack('C', $ip) & 0x0F) * 4;
  my $udp = substr($ip, $iplen);
  my $sip = substr($udp, 8);

  print $sip,"\n" if $debug;

  if (defined $sock) {while (<$sock>) {print if $verbose;}}
  # $! (errno) == 0 if server disconnected
  # $sock undefined if could not connect to server
  if ($! == 0 || !defined $sock) {&connectNCID};
  return if !defined $sock;

  return if $sip !~ /^INVITE/o;

  if ($sip =~ /^From:\s+\"?(.+?)"?\s+<sip:(.+?)@/imo) {
    my ($name, $number) = ($1, $2);

    if ($sip =~ /^To:\s+<sip:.+(\d\d\d\d)@/imo) {
      my $line = $1;

      my $date = strftime("%m%d%H%M", localtime($header->{tv_sec}));
      my $msg = sprintf("CID: ###DATE%s...LINE%s...NMBR%s...NAME%s+++",
          $date, $line, $number,$name);

      print $msg, "\n" if $verbose;
      print $sock $msg, "\r\n"
    } else { print "To: failed to find number called\n" if $debug; }
  } else { print "From: failed to find name and number\n" if $debug; }
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

=head1 NAME

ncidsip - Inject CID info by snooping SIP invites

=head1 SYNOPSIS

ncidsip [--sip|-s <[host][:port]>] [--ncid|-n <host[:port]>] [--debug] [--dumpfile <filename>] [-i|--interface <interface>] [--help|-h] [--version|-V] [--verbose|-v]

=head1 DESCRIPTION

Snoops SIP INVITES via libpcap and injects the caller id information
found to the NCID server specified.  Uses L<Net::Pcap> to interface
with the libpcap library and snoops only udp traffic on the specified
SIP host and port.

=head1 OPTIONS

=over 2

=item -s, --sip=<[host][:port]>

Specifies the hostname of the SIP devie to snoop.  You may also
specify the UDP port by suffixing the hostname with :<port>, or
if no hostname wanted, just :<port>.  If you do not specify a host,
it defaults to the network interface.  If you do not specify a port,
it defaults to <5061> (Vonage default).

=item -n, --ncid=<host[:port]>

Specifies the NCID server to connect to.  Port may be specified by
suffixing the hostname with :<port>.  By default it will connect to
port C<3333> on C<localhost>.

=item -i, --interface=<interface>

Specifies the network interface to snoop on.  If this is not specified
then libpcap will pick a network interface.  This will generally be
the first ethernet interface found.

=item -h, --help

Prints this help

=item --debug

Display the payload of all packets that matched the libpcap filter.

=item --dumpfile <filename>

Read packets from a libpcap capture file instead of the network.
Mostly only useful for development purposes.

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
/*
 * Copyright 2007, 2008, 2009, 2010, 2011
 * by  John L. Chmielewski <jlc@cfl.rr.com>
 *
 * sip2ncid.h is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * sip2ncid.h is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 */

#include <stdio.h>
#include <getopt.h>
#include <string.h>
#include <signal.h>
#include <errno.h>
#include <unistd.h>
#include <netdb.h>
#include <pcap.h>
#include <sys/fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in_systm.h> /* needed for FreeBSD */
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <time.h>
#include "config.h"
#include "version.h"

#define SHOWVER     "%s %s\n"
#define DESC        "%s - Inject CID info by snooping SIP invites\n"
#define NOOPT       "%s: not a option: %s\n"
#define USAGE       "\
Usage:   %s [options]\n\
Options: [-C configfile      | --config configfile]\n\
         [-D                 | --DEBUG]\n\
         [-h                 | --help]\n\
         [-i <interface>     | --interface <interface>]\n\
         [-l                 | --listdevs]\n\
         [-L <filename>      | --logfile <filename>]\n\
         [-n <[host][:port]> | --ncid <[host][:port]>]\n\
         [-P <filename>      | --pidfile <filename>]\n\
         [-r <dumpfile>      | --readfile <dumpfile>]\n\
         [-s <[host][:port]> | --sip <[host][:port].]\n\
         [-T                 | --testall]\n\
         [-t                 | --testudp]\n\
         [-u                 | --usage]\n\
         [-V                 | --version]\n\
         [-v 1-9             | --verbose 1-9]\n\
         [-w <dumpfile>      | --writefile <dumpfile>]\n\
         [-W 0/1             | --warn 0/1]\n\
\n\
"

#define NCIDPORT    3333
#define SIPPORT     10000
#define LOCALHOST   "127.0.0.1"

#define MAXLEVEL    8
#define MAXLINE     10
#define FATAL       1
#define NONFATAL    0
#define WITHYEAR    1
#define NOYEAR      2
#define ONLYTIME    4
#define MAXCALL     30
#define NUMSIZ      50
#define CIDSIZ      75
#define SIPSIZ      2048
#define PKTWAIT     120

/* ethernet headers are always exactly 14 bytes */
#define SIZE_ETHERNET 14

/* pcap_open_live(): wait after packet received in ms */
#define PCAPWAIT    1

#ifndef PIDFILE
#define PIDFILE     "/var/run/sip2ncid.pid"
#endif

#ifndef LOGFILE
#define LOGFILE     "/var/log/sip2ncid.log"
#endif

#define NODESC      "No description available"
#define LOOPBACK    "Loopback device"
#define VIRBR       "Virtual bridge"

/* strings to search for in packet */
#define SIPVER      "SIP/2"
#define REGISTER    "REGISTER"
#define INVITE      "INVITE"
#define CANCEL      "CANCEL"
#define NOTIFY      "NOTIFY"
#define ACK         "ACK"
#define BYE         "BYE"
#define OK          "OK"
#define TRYING      "Trying"
#define RINGING     "Ringing"
#define REQTERM     "Request Terminated"
#define REQCAN      "Request Cancelled"
#define CSEQ        "CSeq:"
#define SIPNUM      "<sip:"
#define SIPAT       '@'
#define SIPTAG      ";tag="
#define FROM        "From:"
#define TO          "To:"
#define CALLID      "Call-ID:"
#define CONTACT     "Contact:"
#define PROXY       "Proxy-Authenticate:"
#define AGENT       "User-Agent:"
#define SERVER      "Server:"
#define MESSAGES    "Message-Waiting:"
#define QUOTE       '"'
#define NL          '\n'

#define NONAME      "NO NAME"
#define BADNAME     "BAD NAME"
#define NONUMBER    "NO NUMBER"
#define BADNUMBER   "BAD NUMBER"
#define CALLOUT     "OUT"
#define CALLIN      "IN" 

#define CIDCAN      "CALLINFO: ###CANCEL...DATE%s...CALL%s...LINE%s...NMBR%s+++\r\n"
#define CIDBYE      "CALLINFO: ###BYE...DATE%s...CALL%s...LINE%s...NMBR%s+++\r\n"
#define CIDLINE     "CALL: ###DATE%s...CALL%s...LINE%s...NMBR%s...NAME%s+++\r\n"
#define REGLINE     "Registered Line Number"

enum
{
    LEVEL1 = 1,
    LEVEL2,
    LEVEL3,
    LEVEL4,
    LEVEL5,
    LEVEL6,
    LEVEL7,
    LEVEL8,
    LEVEL9
};

extern int ncidport, sipport, warn, rmdups;
extern char *device, *pidfile, *ncidhost, *siphost;

extern void logMsg(int level, char *message);

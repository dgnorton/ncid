/*
 * Copyright 2007 John L. Chmielewski <jlc@cfl.rr.com>
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
#include <time.h>
#include <pcap.h>
#include <sys/fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in_systm.h> /* needed for FreeBSD */
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include "config.h"

#define VERSION     "0.5 (NCID 0.69)"
#define SHOWVER     "%s: Version 0.5 (NCID 0.69)\n"
#define DESC        "%s - Inject CID info by snooping SIP invites\n"
#define USAGE       "\
Usage:   %s [options]\n\
\n\
Options: [-C configfile      | --config configfile]\n\
         [-D                 | --DEBUG]\n\
         [-h                 | --help]\n\
         [-i <interface>     | --interface <interface>]\n\
         [-l                 | --listdevs]\n\
         [-n <[host][:port]> | --ncid <[host][:port]>]\n\
         [-p <filename>      | --pidfile <filename>]\n\
         [-r <dumpfile>      | --readfile <dumpfile>]\n\
         [-s <[host][:port]> | --sip <[host][:port].]\n\
         [-T                 | --testall]\n\
         [-t                 | --testudp]\n\
         [-u                 | --usage]\n\
         [-V                 | --version]\n\
         [-v 1-9             | --verbose 1-9]\n\
         [-w <dumpfile>      | --writefile <dumpfile>]\n\
\n\
"

#define NCIDPORT    3333
#define SIPPORT     10000
#define LOCALHOST   "localhost"

#define MAXLEVEL    9
#define MAXLINENUM  10
#define FATAL       1
#define NONFATAL    0
#define WITHYEAR    1
#define NOYEAR      0

/* ethernet headers are always exactly 14 bytes */
#define SIZE_ETHERNET 14

#ifndef PIDFILE
#define PIDFILE     "/var/run/sip2ncid.pid"
#endif

#define NODESC      "No description available"
#define LOOPBACK    "Loopback device"
#define VIRBR       "Virtual bridge"

/* strings to search for in packet */
#define PKTINV      "INVITE "
#define PKTCAN      "CANCEL "
#define PKTSIP      "SIP/2.0 200 OK"
#define PKTACK      "ACK "
#define CSEQ        "CSeq:"
#define CSEQREG     "REGISTER"
#define CSEQINV     "INVITE"
#define CSEQCAN     "CANCEL"
#define CSEQBYE     "BYE"
#define SIPNUM      "<sip:"
#define FROM        "From:"
#define TO          "To:"
#define CONTACT     "Contact:"
#define SIPAT       '@'
#define QUOTE       '"'
#define ENDLINE     '\n'

#define CIDCAN      "CIDINFO: ###CANCEL...NMBR%s...DATE%s+++\r\n"
#define CIDBYE      "CIDINFO: ###BYE...NMBR%s...DATE%s+++\r\n"
#define CIDLINE     "CID: ###DATE%s...LINE%s...NMBR%s...NAME%s+++\r\n"
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

extern int ncidport, sipport;
extern char *device, *pidfile, *ncidhost, *siphost;

extern void logMsg(int level, char *message);

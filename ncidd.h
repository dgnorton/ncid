/*
 * Copyright (c) 2002, 2003, 2004, 2005, 2006
 * by John L. Chmielewski <jlc@users.sourceforge.net>
 *
 * ncidd.h is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * ncidd.h is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 */

#include <stdio.h>
#include "nciddconf.h"
#include "nciddalias.h"

#if (defined(__MACH__) || \
     defined(__USLC__) || \
     defined(__svr4)   || \
     defined(_M_XENIX) || \
     defined(__FreeBSD__))
# include "getopt_long.h"
#else
# include <getopt.h>
#endif

#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

#if (defined(__MACH__))
# include "poll.h"
#else
# include <sys/poll.h>
#endif

#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <netinet/in.h>
#include <signal.h>
#include <errno.h>
#include <time.h>

#if (!defined(O_SYNC))
# define O_SYNC 0
#endif

#define VERSION     "0.66"
#define SHOWVER     "%s: Version %s\n"
#define DESC        "%s - Network CallerID Server\n"
#define USAGE       "\
Usage: %s [-A aliasfile  | --alias aliasfile]\n\
             [-C configfile | --config configfile]\n\
             [-c calllog    | --cidlog calllog]\n\
             [-D            | --debug]\n\
             [-d logfile    | --datalog logfile]\n\
             [-h            | --help]\n\
             [-I modemstr   | --initstr modemstr]\n\
             [-i cidstr     | --initcid cidstr]\n\
             [-L logfile    | --logfile logfile]\n\
             [-l lockfile   | --lockfile lockfile]\n\
             [-N 0/1        | --noserial 0/1]\n\
             [-n 0/1        | --nomodem 0/1]\n\
             [-p portnumber | --port portnumber]\n\
             [-S ttyspeed   | --ttyspeed ttyspeed]\n\
             [-s datatype   | --send cidlog|cidinfo]\n\
             [-T 0/1        | --sttyclocal 0/1]\n\
             [-t ttyport    | --ttyport ttyport]\n\
             [-V            | --version]\n\
             [-v 1-9        | --verbose 1-9]\n\
"

#ifndef TTYPORT
#define TTYPORT     "/dev/modem"
#endif
#ifndef CIDLOG
#define CIDLOG      "/var/log/cidcall.log"
#endif
#ifndef DATALOG
#define DATALOG     "/var/log/ciddata.log"
#endif
#ifndef LOGFILE
#define LOGFILE     "/var/log/ncidd.log"
#endif

#define STDOUT      1
#define BUFSIZE     512
#define CHARWAIT    2       /* deciseconds */
#define INITWAIT    100000  /* microseconds */
#define INITTRY     10      /* number of times to INITWAIT for a character */
#define MODEMTRY    6
#define TTYSPEED    B19200
#define LOCKFILE    "/var/lock/LCK.."
#define ANNOUNCE    "200 Network CallerID Server Version "
#define INITSTR     "AT Z S0=0 E1 V1 Q0"
#define INITCID1    "AT+VCID=1"
#define INITCID2    "AT#CID=1"
#define PORT        3333
#define CONNECTIONS 15
#define TIMEOUT     200
#define RINGWAIT    25
#define CRLF        "\r\n"
#define NL          "\n"
#define CR          "\r"

#define NONAME      "NO NAME"
#define NONUMB      "NO NUMBER"
#define NOMESG      "NONE"
#define LOGMAX      90000
#define LOGMSG      "MSG: Caller ID Logfile too big to get: (%d > %d) bytes%s"
#define TOOMSG      "MSG: Too many clients connected"

#define CIDLINE     "CID: "
#define MSGLINE     "MSG: "
#define LOGLINE     "LOG: "
#define LINETYPE    25
#define ONELINE     "-"

#define DATE        "*DATE*"
#define TIME        "*TIME*"
#define NMBR        "*NMBR*"
#define MESG        "*MESG*"
#define NAME        "*NAME*"
#define LINE        "*LINE*"
#define STAR        "*"

#define CIDINFO     "CIDINFO: "
#define RING        "*RING*"

#define O            "OUT-OF-AREA"
#define A            "ANONYMOUS"
#define P            "PRIVATE"

#define CIDSIZE      25
#define CIDDATE      0x01
#define CIDTIME      0x02
#define CIDNMBR      0x04
#define CIDNAME      0x08
#define CIDMESG      0x10
#define CIDALL3      0x07
#define CIDALT3      0x0B
#define CIDALL4      0x0F

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

extern char *ttyport, *TTYspeed;
extern char *cidlog, *datalog, *initstr, *initcid, *lockfile, *ttyport;
extern int setcid, port, sendlog, sendinfo, clocal, nomodem, ttyspeed, verbose;
extern int noserial;
extern int logMsg(int level, char *message);

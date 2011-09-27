/*
 * Copyright (c) 2002-2011
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
#include "nciddhangup.h"

#include <getopt.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

#if (defined(__MACH__))
# include "poll.h"
#else
#include <sys/poll.h>
#endif

#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <netinet/in.h> /* needed for TiVo Series1 */
#include <arpa/inet.h>
#include <signal.h>
#include <errno.h>
#include <time.h>
#include <ctype.h>
#include "version.h"

#if (!defined(O_SYNC))
# define O_SYNC 0
#endif

#define SHOWVER     "%s %s\n"
#define DESC        "%s - Network CallerID Server\n"
#define NOOPT       "%s: not a option: %s\n"
#define USAGE       "\
Usage:   %s [options]\n\
Options: [-A aliasfile  | --alias <file>]\n\
         [-B blacklist  | --blacklist <file>]\n\
         [-C configfile | --config <file>]\n\
         [-c calllog    | --cidlog <file>]\n\
         [-D            | --debug]\n\
         [-d logfile    | --datalog <file>]\n\
         [-e lineid     | --lineid <identifier>]\n\
         [-g 0/1        | --gencid 0/1]\n\
         [-h            | --help]\n\
         [-H 0/1        | --hangup 0/1]\n\
         [-I modemstr   | --initstr <initstring>]\n\
         [-i cidstr     | --initcid <cidstring>]\n\
         [-L logfile    | --logfile <file>]\n\
         [-l lockfile   | --lockfile <file>]\n\
         [-M MaxBytes   | --cidlogmax <MaxBytes>]\n\
         [-N 0/1        | --noserial 0/1]\n\
         [-n 0/1        | --nomodem 0/1]\n\
         [-P pidfile    | --pidfile <file>]\n\
         [-p portnumber | --port <portnumber>]\n\
         [-S ttyspeed   | --ttyspeed <ttyspeed>]\n\
         [-s datatype   | --send cidlog|cidinfo|cidout]\n\
         [-T 0/1        | --sttyclocal 0/1]\n\
         [-t ttyport    | --ttyport <ttyport>]\n\
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
#ifndef PIDFILE
#define PIDFILE     "/var/run/ncidd.pid"
#endif
#ifndef LOCKFILE
#define LOCKFILE    "/var/lock/LCK.."
#endif

#define STDOUT      1
#define BUFSIZE     512
#define CHARWAIT    2       /* deciseconds */
#define READWAIT    100000  /* microseconds */
#define READTRY     10      /* number of times to INITWAIT for a character */
#define MODEMTRY    6
#define TTYSPEED    B19200

#define ANNOUNCE    "200 Server:"
#define LOGEND      "300 end of call log"

#define INITSTR     "AT Z S0=0 E1 V1 Q0"
#define INITCID1    "AT+VCID=1"
#define INITCID2    "AT#CID=1"

#define PORT        3333
#define CONNECTIONS 25
#define TIMEOUT     200     /* poll() timeout in milliseconds */
#define RINGWAIT    29      /* number of poll() timeouts to wait for RING */

#define CRLF        "\r\n"
#define NL          "\n"
#define CR          "\r"

#define WITHSEP     1       /* MM/DD/YYYY HH:MM:SS */
#define NOSEP       2       /* MMDDYYYY HHMM */
#define ONLYTIME    4       /* HH:MM:SS */
#define LOGFILETIME 8       /* HH:MM:SS.ssss */

#define NONAME      "NO NAME"
#define NONUMB      "NO NUMBER"
#define NOCID       "No Caller ID"
#define NOMESG      "NONE"

#define LOGMAX      110000
#define LOGMAXNUM   100000000
#define LOGMSG      "MSG: Caller ID Logfile too big: (%lu > %lu) bytes%s"
#define TOOMSG      "MSG: Too many clients connected"

#define HANGUPMSG   "Calls in the blacklist file will be terminated"
#define IGNORE1     "Leading 1 from a call must not be in an alias definition"
#define INCLUDE1    "Leading 1 from a call required in an alias definition"

#define CIDLINE     "CID: "
#define MSGLINE     "MSG: "
#define LOGLINE     "LOG: "
#define OUTLINE     "OUT: "
#define HUPLINE     "HUP: "

#define LINETYPE    25
#define ONELINE     "-"

#define CALLOUT     "CALLOUT"
#define CALLIN      "CALLIN"

#define DATE        "*DATE*"
#define TIME        "*TIME*"
#define NMBR        "*NMBR*"
#define MESG        "*MESG*"
#define NAME        "*NAME*"
#define LINE        "*LINE*"
#define STAR        "*"

#define CIDINFO     "CIDINFO: "
#define RING        "*RING*"

#define CALL        "CALL: "
#define CALLINFO    "CALLINFO: "
#define CANCEL      "CANCEL"
#define BYE         "BYE"

#define O            "OUT-OF-AREA"
#define A            "ANONYMOUS"
#define P            "PRIVATE"

#define CIDSIZE      50
#define CIDDATE      0x01
#define CIDTIME      0x02
#define CIDNMBR      0x04
#define CIDNAME      0x08
#define CIDMESG      0x10
#define CIDALL3      0x07   /* Date, Time, Nmbr */
#define CIDALT3      0x0B   /* Date, Time, Nmbr, Name */
#define CIDALL4      0x0F   /* Date, Time, Name */
#define CIDALT4      0x17   /* Date, Time, Nmbr, Mesg */

#define MAXLEVEL     9
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
extern char *initstr, *initcid;
extern char *cidlog, *datalog, *lineid, *lockfile, *pidfile;
extern int setcid, port, clocal, ttyspeed, ttyfd, hangup;
extern int sendlog, sendinfo, ignore1;
extern int nomodem, noserial, gencid, verbose;
extern long unsigned int cidlogmax;
extern void logMsg();
extern int errorExit(), CheckForLockfile(), openTTY(), doTTY(), initModem();
extern struct termios rtty, ntty;

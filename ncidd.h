/*
 * Copyright (c) 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010
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

#include <getopt.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <sys/poll.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <netinet/in.h>
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
Options: [-A aliasfile  | --alias aliasfile]\n\
         [-C configfile | --config configfile]\n\
         [-c calllog    | --cidlog calllog]\n\
         [-D            | --debug]\n\
         [-d logfile    | --datalog logfile]\n\
         [-e lineid     | --lineid identifier]\n\
         [-g 0/1        | --gencid 0/1]\n\
         [-h            | --help]\n\
         [-I modemstr   | --initstr modemstr]\n\
         [-i cidstr     | --initcid cidstr]\n\
         [-L logfile    | --logfile logfile]\n\
         [-l lockfile   | --lockfile lockfile]\n\
         [-M MaxBytes   | --cidlogmax MaxBytes]\n\
         [-N 0/1        | --noserial 0/1]\n\
         [-n 0/1        | --nomodem 0/1]\n\
         [-P pidfile    | --pidfile pidfile]\n\
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
#ifndef PIDFILE
#define PIDFILE     "/var/run/ncidd.pid"
#endif

#define STDOUT      1
#define BUFSIZE     512
#define CHARWAIT    2       /* deciseconds */
#define INITWAIT    100000  /* microseconds */
#define INITTRY     10      /* number of times to INITWAIT for a character */
#define MODEMTRY    6
#define TTYSPEED    B19200
#define LOCKFILE    "/var/lock/LCK.."
#define ANNOUNCE    "200 Server:"
#define LOGEND      "300 end of call log"
#define INITSTR     "AT Z S0=0 E1 V1 Q0"
#define INITCID1    "AT+VCID=1"
#define INITCID2    "AT#CID=1"
#define PORT        3333
#define CONNECTIONS 25
#define TIMEOUT     200     /* poll() timeout in milliseconds */
#define RINGWAIT    25      /* number of poll() timeouts to wait for RING */
#define CRLF        "\r\n"
#define NL          "\n"
#define CR          "\r"
#define WITHSEP     1
#define NOSEP       2
#define ONLYTIME    4

#define NONAME      "NO NAME"
#define NONUMB      "NO NUMBER"
#define NOCID       "No Caller ID"
#define NOMESG      "NONE"
#define LOGMAX      110000
#define LOGMAXNUM   100000000
#define LOGMSG      "MSG: Caller ID Logfile too big: (%lu > %lu) bytes%s"
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

#define CALL        "CALL: "
#define CALLINFO    "CALLINFO: "
#define CALLED      "CALLED"
#define CANCEL      "CANCEL"
#define BYE         "BYE"

#define O            "OUT-OF-AREA"
#define A            "ANONYMOUS"
#define P            "PRIVATE"

#define CIDSIZE      25
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
extern int setcid, port, clocal, ttyspeed;
extern int sendlog, sendinfo;
extern int nomodem, noserial, gencid, verbose;
extern unsigned long cidlogmax;
extern void logMsg();
extern int errorExit();

/*
 * ncid2ncid.h - This file is part of ncid2ncid.
 *
 * Copyright (c) 2005-2013
 * by John L. Chmielewski <jlc@users.sourceforge.net>
 *
 * ncid2ncid is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * ncid2ncid is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with ncid2ncid.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <getopt.h>
#include <string.h>
#include <signal.h>
#include <errno.h>
#include <unistd.h>
#include <netdb.h>
#include <pcap.h>             /* needed for TiVo Series1 */
#include <sys/fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in_systm.h> /* needed for FreeBSD */
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <sys/poll.h>
#include <time.h>
#include "version.h"

#define SHOWVER     "%s %s\n"
#define DESC        "%s - NCID server to NCID server gateway\n"
#define NOOPT       "%s: not a option: %s\n"
#define USAGE       "\
Usage:   %s [options]\n\
Options: [-C configfile      | --config configfile]\n\
         [-D                 | --DEBUG]\n\
         [-f <[host][:port]> | --fromhost <[host][:port]>]\n\
         [-h                 | --help]\n\
         [-L <filename>      | --logfile <filename>]\n\
         [-t <[host][:port]> | --tohost <[host][:port]>]\n\
         [-P <filename>      | --pidfile <filename>]\n\
         [-u                 | --usage]\n\
         [-V                 | --version]\n\
         [-v 1-9             | --verbose 1-9]\n\
         [-W 0/1             | --warn 0/1]\n\
         [--osx-launchd]\n\
"

#define HOST      "127.0.0.1"
#define PORT        3333

#define MAXLEVEL    7
#define FATAL       1
#define NONFATAL    0
#define WITHYEAR    1
#define NOYEAR      2
#define ONLYTIME    4

#define SERVERS     5          /*number of receiving and sending servers */
#define TIMEOUT     30 * 1000  /* poll() timeout in milliseconds */

#define NOSEND      "Missing Sending host 1, use"
#define REQOPT      " -f host:[port] || --fromhost host:[port]"

#ifndef PIDFILE
#define PIDFILE     "/var/run/ncid2ncid.pid"
#endif

#ifndef LOGFILE
#define LOGFILE     "/var/log/ncid2ncid.log"
#endif

#ifndef CONFIG
#define CONFIG      "/usr/local/etc/ncid/ncid2ncid.conf"
#endif

#define NL          '\n'

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

#define WORDZERO    0x00
#define WORDSTR     0x10
#define WORDNUM     0x20
#define WORDFONT    0x40
#define WORDFLAG    0x80

#define ON           1
#define OFF          0

#define ERRCMD      "unknown command:"
#define ERRWORD     "unknown word:"
#define ERRARG      "missing argument for word:"
#define ERREQA      "missing '=' after word:"
#define ERREQB      "missing '=' before word:"
#define ERRMISS     "missing:"
#define ERRNUM      "invalid number:"

struct setword
{
    char *word;
    int type;
    char **buf;
    int *value;
    int min;
    int max;
};

struct server
{
    char *name;
    char *host;
    int port;
    int sd;
};

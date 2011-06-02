/*
 * ncidd - Network Caller ID Daemon
 *
 * Copyright (c) 2002-2011
 * by John L. Chmielewski <//jlc@users.sourceforge.net>
 *
 * This file is part of ncidd, a caller-id program for your TiVo.
 *
 * ncidd is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * ncidd is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 */

#include "ncidd.h"

/* globals */
char *cidlog  = CIDLOG;
char *datalog = DATALOG;
char *ttyport = TTYPORT;
char *initstr = INITSTR;
char *initcid = INITCID1;
char *logfile = LOGFILE;
char *pidfile;
char *lineid  = ONELINE;
char *lockfile, *name;
char *TTYspeed;
int ttyspeed = TTYSPEED;
int port = PORT;
int debug, conferr, setcid, locked, sendlog, sendinfo, callout;
int ttyfd, pollpos, pollevents;
int ring, ringwait, lastring, clocal, nomodem, noserial, gencid = 1;
int cidsent, verbose = 1, hangup, ignore1;
unsigned long cidlogmax = LOGMAX;
pid_t pid;

char ipaddr[CONNECTIONS][25];
char ringline[CIDSIZE] = "-";

struct pollfd polld[CONNECTIONS + 2];
struct termios otty, rtty, ntty;
FILE *logptr;

struct cid
{
    int status;
    char ciddate[CIDSIZE];
    char cidtime[CIDSIZE];
    char cidnmbr[CIDSIZE];
    char cidname[CIDSIZE];
    char cidmesg[CIDSIZE];
    char cidline[CIDSIZE];
} cid = {0, "", "", "", "", NOMESG, ONELINE};

char *strdate();
#ifndef __CYGWIN__
    extern char *strsignal();
#endif

void exit(), finish(), free(), reload(), ignore(), doPoll(), formatCID(),
     writeClients(), writeLog(), sendLog(), builtinAlias(), userAlias(),
     sendInfo(), logMsg(), cleanup();

int getOptions(), doConf(), errorExit(), doAlias(), doTTY(), CheckForLockfile(),
    addPoll(), tcpOpen(), doModem(), initModem(), gettimeofday(), doPID(),
    tcpAccept(), openTTY();

int main(int argc, char *argv[])
{
    int events, mainsock, argind, i, fd, errnum;
    char *ptr;
    struct stat statbuf;
    char msgbuf[BUFSIZ];

    signal(SIGHUP,  finish);
    signal(SIGINT,  finish);
    signal(SIGQUIT, finish);
    signal(SIGABRT, finish);
    signal(SIGSEGV, finish);
    signal(SIGALRM, finish);
    signal(SIGTERM, finish);

    signal(SIGPIPE, ignore);

    /* global containing name of program */
    name = strrchr(argv[0], (int) '/');
    name = name ? name + 1 : argv[0];

    /* process options from the command line */
    argind = getOptions(argc, argv);

    /* should not be any arguments */
    if (argc - argind != 0)
    {
        fprintf(stderr, NOOPT, name, argv[argind]);
        fprintf(stderr, USAGE, name);
        exit(0);
    }

    /* open or create logfile */
    logptr = fopen(logfile, "a");
    errnum = errno;

    sprintf(msgbuf, "Started: %s\nServer: %s %s\n",strdate(WITHSEP),
            name, VERSION);
    logMsg(LEVEL1, msgbuf);

    /* check status of logfile */
    if (logptr)
    {
        /* logfile opened */
        sprintf(msgbuf, "logfile: %s\n", logfile);
        logMsg(LEVEL1, msgbuf);
    }
    else
    {
        /* logfile open failed */
        sprintf(msgbuf, "%s: %s\n", logfile, strerror(errnum));
        logMsg(LEVEL1, msgbuf);
    }

    /* log command line and any options on separate lines */
    sprintf(msgbuf, "Command line: %s", argv[0]);
    for (i = 1; i < argc; i++)
    {
        if (*argv[i] == '-')
            strcat(strcat(msgbuf, "\n              "), argv[i]);
        else strcat(strcat(msgbuf, " "), argv[i]);
    }
    strcat(msgbuf, NL);
    logMsg(LEVEL1, msgbuf);

    /*
     * read config file, if present, exit on any errors
     * do not override any options set on the command line
     */
    if (doConf()) errorExit(-104, 0, 0);

    sprintf(msgbuf, "Verbose level: %d\n", verbose);
    logMsg(LEVEL1, msgbuf);

    if (nomodem && hangup)
    {
    sprintf(msgbuf,
        "The nomodem option cannot be used with the hangup option.");
        errorExit(-110, "Fatal", msgbuf);
    }

    /*
     * indicate what is configured to send to the clients
     */
    for (i = 0; sendclient[i].word; i++)
        if (*sendclient[i].value)
        {
            sprintf(msgbuf, "Configured to send '%s' to clients.\n",
                sendclient[i].word);
            logMsg(LEVEL1, msgbuf);
        }

    /*
     * read alias file, if present, exit on any errors
     */
    if (doAlias()) errorExit(-109, 0, 0);
    sprintf(msgbuf, "%s\n", ignore1 ? IGNORE1 : INCLUDE1);
    logMsg(LEVEL1, msgbuf);

    /* read blacklist file, if hangup option given, exit on any errors */
    if (hangup)
    {
        sprintf(msgbuf, "%s\n", HANGUPMSG);
        logMsg(LEVEL1, msgbuf);
        if (doBlacklist()) errorExit(-114, 0, 0);
    }

    if (stat(cidlog, &statbuf) == 0)
    {
      sprintf(msgbuf, "CID logfile: %s\nCID logfile maximum size: %lu bytes\n",
        cidlog, cidlogmax);
      logMsg(LEVEL1, msgbuf);
    }
    else
    {
        /* Create the call log file if not present */
        if ((fd = open(cidlog, O_WRONLY | O_APPEND | O_CREAT,
             S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)) < 0)
        {
            sprintf(msgbuf, "%s: %s\n", cidlog, strerror(errno));
            logMsg(LEVEL1, msgbuf);
        }
        else
        {
          close(fd);
          sprintf(msgbuf,
            "Created CID logfile: %s\nCID logfile maximum size: %lu bytes\n",
            cidlog, cidlogmax);
          logMsg(LEVEL1, msgbuf);
        }
    }

    if (stat(datalog, &statbuf) == 0)
    {
        sprintf(msgbuf, "Data logfile: %s\n", datalog);
        logMsg(LEVEL1, msgbuf);
    }
    else
    {
        sprintf(msgbuf, "Data logfile not present: %s\n", datalog);
        logMsg(LEVEL1, msgbuf);
    }

    sprintf(msgbuf, "Telephone Line Identifier: %s\n", lineid);
    logMsg(LEVEL1, msgbuf);

    /*
     * noserial = 1: serial port not used
     * noserial = 0: serial port used for Caller ID
     */

    if (!noserial || hangup)
    {
        /*
        * If the tty port speed was set, map it to the correct integer.
        */
        if (TTYspeed)
        {
            if (!strcmp(TTYspeed, "38400")) ttyspeed = B38400;
            else if (!strcmp(TTYspeed, "19200")) ttyspeed = B19200;
            else if (!strcmp(TTYspeed, "9600")) ttyspeed = B9600;
            else if (!strcmp(TTYspeed, "4800")) ttyspeed = B4800;
            else errorExit(-108, "Invalid TTY port speed set in config file",
                TTYspeed);
        }

        /* Create lock file name from TTY port device name */
        if (!lockfile)
        {
            if ((ptr = strrchr(ttyport, '/'))) ptr++;
            else ptr = ttyport;

            if ((lockfile = (char *) malloc(strlen(LOCKFILE)
                + strlen(ptr) + 1)))
                strcat(strcpy(lockfile, LOCKFILE), ptr);
            else errorExit(-1, name, 0);
        }

        /* check TTY port lock file */
        if (CheckForLockfile())
            errorExit(-102, "Exiting - TTY lockfile exists", lockfile);

        /* Open tty port; exit program if it fails */
        if (openTTY() < 0) errorExit(-1, ttyport, 0);

        switch(ttyspeed)
        {
            case B4800:
                TTYspeed = "4800";
                break;
            case B9600:
                TTYspeed = "9600";
                break;
            case B19200:
                TTYspeed = "19200";
                break;
            case B38400:
                TTYspeed = "38400";
                break;
        }

        sprintf(msgbuf, "TTY port opened: %s\n", ttyport);
        logMsg(LEVEL1, msgbuf);
        sprintf(msgbuf, "TTY port speed: %s\n", TTYspeed);
        logMsg(LEVEL1, msgbuf);
        sprintf(msgbuf, "TTY lock file: %s\n", lockfile);
        logMsg(LEVEL1, msgbuf);
        sprintf(msgbuf, "TTY port control signals %s\n",
            clocal ? "disabled" : "enabled");
        logMsg(LEVEL1, msgbuf);

        if (noserial)
        {
            sprintf(msgbuf,
                "CallerID from gateways\n");
            logMsg(LEVEL1, msgbuf);
        }
        else if (nomodem)
        {
            sprintf(msgbuf,
                "CallerID from serial device and optional gateways\n");
            logMsg(LEVEL1, msgbuf);
        }
        else
        {
            sprintf(msgbuf, "CallerID from AT Modem and optional gateways\n");
            logMsg(LEVEL1, msgbuf);

            if (gencid)
            {
            sprintf(msgbuf, "Handles modem calls without Caller ID\n");
            logMsg(LEVEL1, msgbuf);
            }
            else
            {
            sprintf(msgbuf, "Does not handle modem calls without Caller ID\n");
            logMsg(LEVEL1, msgbuf);
            }
        }

        if (!noserial)
        {
            /* Save tty port settings */
            if (tcgetattr(ttyfd, &otty) < 0) return -1;

            /* initialize tty port */
            if (doTTY() < 0) errorExit(-1, ttyport, 0);
        }
    }
    else if (noserial)
    {
        sprintf(msgbuf, "CallerID from Gateway\n");
        logMsg(LEVEL1, msgbuf);
    }

    if (hangup)
    {
        if (noserial)
        {
            (void) close(ttyfd);
            ttyfd = 0;
            sprintf(msgbuf,
                "Modem port closed, modem only used to terminate calls\n");
        }
        else sprintf(msgbuf, "Modem used to terminate calls on blacklist\n");
        logMsg(LEVEL1, msgbuf);
    }

    sprintf(msgbuf, "Network Port: %d\n", port);
    logMsg(LEVEL1, msgbuf);

    if (debug)
    {
        sprintf(msgbuf, "Debug Mode\n");
        logMsg(LEVEL1, msgbuf);
    }
    else
    {
        /* fork and exit parent */
        if(fork() != 0) return 0;

        /* close stdin, and  and make fd 0 unavailable */
        close(0);
        if (open("/dev/null",  O_WRONLY | O_SYNC) < 0)
        {
            errorExit(-1, "/dev/null", 0);
        }

        /* become session leader */
        setsid();
    }

    /* reload alias and blacklist files on SIGHUP */
    signal(SIGHUP, reload);

    /*
     * Create a pid file
     */
    if (doPID())
    {
        sprintf(msgbuf,"%s already exists", pidfile);
        errorExit(-110, "Fatal", msgbuf);
    }

    if (!noserial) {
            pollpos = addPoll(ttyfd);
            sprintf(msgbuf,"%s is fd %d\n",
                    nomodem ? "Caller ID Device" : "Modem", ttyfd);
            logMsg(LEVEL3, msgbuf);
        }

    /* initialize server socket */
    if ((mainsock = tcpOpen(port)) < 0) errorExit(-1, "socket", 0);

    addPoll(mainsock);

    /* Read and display data */
    while (1)
    {
        switch (events = poll(polld, CONNECTIONS + 2, TIMEOUT))
        {
            case -1:    /* error */
                if (errno != EINTR) /* No error for SIGHUP */
                    errorExit(-1, "poll", 0);
                break;
            case 0:        /* time out, without an event */
                if (ring > 0)
                {
                    /* ringing detected  */
                    if (ringwait < RINGWAIT) ++ringwait;
                    else
                    {
                            sprintf(msgbuf, "lastring: %d ring: %d time: %s\n",
                                lastring, ring, strdate(ONLYTIME));
                            logMsg(LEVEL4, msgbuf);
                        if (lastring == ring)
                        {
                            /* ringing stopped */
                            ring = lastring = ringwait = cidsent = 0;
                            sendInfo(mainsock);
                        }
                        else
                        {
                            /* ringing */
                            ringwait = 0;
                            lastring = ring;
                        }
                    }
                }
                /* if no serial port, skip TTY code */
                if (!noserial)
                {
                    /* TTY port lockfile */
                    if (CheckForLockfile())
                    {
                        if (!locked)
                        {
                            /* lockfile just found */

                            /* save TTY events */
                            pollevents = polld[pollpos].events;
                            /* remove TTY poll events */
                            polld[pollpos].events = polld[pollpos].revents = 0;
                            polld[pollpos].fd = 0;
                            close(ttyfd);
                            sprintf(msgbuf, "TTY in use: releasing modem %s\n",
                                strdate(WITHSEP));
                            logMsg(LEVEL1, msgbuf);
                            locked = 1;
                            ringwait = 0;
                        }
                    }
                    else if (locked)
                    {
                        /* lockfile just went away */
                        sprintf(msgbuf, "TTY free: using modem again %s\n",
                            strdate(WITHSEP));
                        logMsg(LEVEL1, msgbuf);
                        if (openTTY() < 0) errorExit(-1, ttyport, 0);
                        if (doTTY() < 0)
                        {
                            sprintf(msgbuf,
                                "%sCannot init TTY, Terminated %s",
                                MSGLINE, strdate(WITHSEP));
                            writeClients(mainsock, msgbuf);
                            tcsetattr(ttyfd, TCSANOW, &otty);
                            errorExit(-111, "Fatal", "Cannot init TTY");
                        }
                        locked = 0;
                        /* restore tty poll events */
                        polld[pollpos].fd = ttyfd;
                        polld[pollpos].events = pollevents;
                    }
                }
                break;
            default:    /* 1 or more events */
                doPoll(events, mainsock);
                break;
        }
    }
}

int getOptions(int argc, char *argv[])
{
    int c, num;
    int option_index = 0;
    static struct option long_options[] = {
        {"alias", 1, 0, 'A'},
        {"blacklist", 1, 0, 'B'},
        {"config", 1, 0, 'C'},
        {"cidlog", 1, 0, 'c'},
        {"cidlogmax", 1, 0, 'M'},
        {"datalog", 1, 0, 'd'},
        {"debug", 0, 0, 'D'},
        {"gencid", 1, 0, 'g'},
        {"help", 0, 0, 'h'},
        {"hangup", 1, 0, 'H'},
        {"initcid", 1, 0, 'i'},
        {"initstr", 1, 0, 'I'},
        {"lineid", 1, 0, 'e'},
        {"lockfile", 1, 0, 'l'},
        {"logfile", 1, 0, 'L'},
        {"nomodem", 1, 0, 'n'},
        {"noserial", 1, 0, 'N'},
        {"pidfile", 1, 0, 'P'},
        {"port", 1, 0, 'p'},
        {"send", 1, 0, 's'},
        {"ttyspeed", 1, 0, 'S'},
        {"ttyclocal", 1, 0, 'T'},
        {"ttyport", 1, 0, 't'},
        {"verbose", 1, 0, 'v'},
        {"version", 0, 0, 'V'},
        {0, 0, 0, 0}
    };

    while ((c = getopt_long (argc, argv, "c:d:e:g:hi:l:n:p:s:t:v:A:B:C:DH:I:L:M:N:P:S:T:V",
        long_options, &option_index)) != -1)
    {
        switch (c)
        {
            case 'A':
                if (!(cidalias = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("cidalias")) >= 0) setword[num].type = 0;
                break;
            case 'B':
                if (!(blacklist = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("blacklist")) >= 0) setword[num].type = 0;
                break;
            case 'C':
                if (!(cidconf = strdup(optarg))) errorExit(-1, name, 0);
                break;
            case 'D':
                ++debug;
                break;
            case 'H':
                hangup = atoi(optarg);
                if (strlen(optarg) != 1 ||
                    (!(hangup == 0 && *optarg == '0') && hangup != 1))
                    errorExit(-107, "Invalid number", optarg);
                if ((num = findWord("hangup")) >= 0) setword[num].type = 0;
                break;
            case 'I':
                if (!(initstr = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("initstr")) >= 0) setword[num].type = 0;
                break;
            case 'L':
                if (!(logfile = strdup(optarg))) errorExit(-1, name, 0);
                break;
            case 'M':
                cidlogmax = atoi(optarg);
                if ((num = findWord("cidlogmax")) >= 0)
                {
                    if (cidlogmax < (unsigned) setword[num].min ||
                        cidlogmax > (unsigned) setword[num].max)
                        errorExit(-107, "Invalid number", optarg);
                    setword[num].type = 0;
                }
                break;
            case 'N':
                noserial = atoi(optarg);
                if (strlen(optarg) != 1 ||
                    (!(noserial == 0 && *optarg == '0') && noserial != 1))
                    errorExit(-107, "Invalid number", optarg);
                if ((num = findWord("noserial")) >= 0) setword[num].type = 0;
                break;
            case 'P':
                if (!(pidfile = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("pidfile")) >= 0) setword[num].type = 0;
                break;
            case 'S':
                if (!(TTYspeed = strdup(optarg))) errorExit(-1, name, 0);
                if (!strcmp(TTYspeed, "38400")) ttyspeed = B38400;
                else if (!strcmp(TTYspeed, "19200")) ttyspeed = B19200;
                else if (!strcmp(TTYspeed, "9600")) ttyspeed = B9600;
                else if (!strcmp(TTYspeed, "4800")) ttyspeed = B4800;
                else errorExit(-108, "Invalid TTY port speed", TTYspeed);
                if ((num = findWord("ttyspeed")) >= 0) setword[num].type = 0;
                break;
            case 'T':
                clocal = atoi(optarg);
                if (strlen(optarg) != 1 ||
                    (!(clocal == 0 && *optarg == '0') && clocal != 1))
                    errorExit(-107, "Invalid number", optarg);
                if ((num = findWord("sttyclocal")) >= 0) setword[num].type = 0;
                break;
            case 'V': /* version */
                fprintf(stderr, SHOWVER, name, VERSION);
                exit(0);
            case 'c':
                if (!(cidlog = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("cidlog")) >= 0) setword[num].type = 0;
                break;
            case 'd':
                if (!(datalog = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("datalog")) >= 0) setword[num].type = 0;
                break;
            case 'e':
                if (!(lineid = strdup(optarg))) errorExit(-1, name, 0);
                if (strlen(lineid) > CIDSIZE -1)
                    errorExit(-113, "string too long", optarg);
                if ((num = findWord("lineid")) >= 0) setword[num].type = 0;
                break;
            case 'g':
                gencid = atoi(optarg);
                if (strlen(optarg) != 1 ||
                    (!(gencid == 0 && *optarg == '0') && gencid != 1))
                    errorExit(-107, "Invalid number", optarg);
                if ((num = findWord("gencid")) >= 0) setword[num].type = 0;
                break;
            case 'h': /* help message */
                fprintf(stderr, DESC, name);
                fprintf(stderr, USAGE, name);
                exit(0);
            case 'i':
                if (!(initcid = strdup(optarg))) errorExit(-1, name, 0);
                ++setcid;
                if ((num = findWord("initcid")) >= 0) setword[num].type = 0;
                break;
            case 'l':
                if (!(lockfile = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("lockfile")) >= 0) setword[num].type = 0;
                break;
            case 'n':
                nomodem = atoi(optarg);
                if (strlen(optarg) != 1 ||
                    (!(nomodem == 0 && *optarg == '0') && nomodem != 1))
                    errorExit(-107, "Invalid number", optarg);
                if ((num = findWord("nomodem")) >= 0) setword[num].type = 0;
                break;
            case 'p':
                if((port = atoi(optarg)) == 0)
                    errorExit(-101, "Invalid port number", optarg);
                if ((num = findWord("port")) >= 0) setword[num].type = 0;
                break;
            case 's':
                if ((num = findSend(optarg)) < 0)
                    errorExit(-106, "Invalid send data type", optarg);
                ++(*sendclient[num].value);
                break;
            case 't':
                if (!(ttyport = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("ttyport")) >= 0) setword[num].type = 0;
                break;
            case 'v':
                verbose = atoi(optarg);
                /* valid range: 1-9 */
                if (strlen(optarg) != 1 || (verbose == 0))
                {
                    verbose = 1;
                    errorExit(-107, "Invalid number", optarg);
                }
                if ((num = findWord("verbose")) >= 0) setword[num].type = 0;
                break;
            case '?': /* bad option */
                fprintf(stderr, USAGE, name);
                errorExit(-100, 0, 0);
        }
    }
    return optind;
}

/*
 * Open tty port; tries to make sure the open does
 * not hang if port in use, or not restored after use
 */

int openTTY()
{
    if ((ttyfd = open(ttyport, O_RDWR | O_NOCTTY | O_NDELAY)) < 0)
         return -1;
    if (fcntl(ttyfd, F_SETFL, fcntl(ttyfd, F_GETFL, 0) & ~O_NDELAY) < 0)
        return -1;

    return 0;
}

int doTTY()
{
    char msgbuf[BUFSIZ];

    /* Setup tty port in raw mode */
    if (tcgetattr(ttyfd, &rtty) < 0) return -1;
    rtty.c_lflag     &= ~(ICANON | ECHO | ECHOE | ISIG);
    rtty.c_oflag     &= ~OPOST;
    rtty.c_iflag = (IGNBRK | IGNPAR);
    rtty.c_cflag = (ttyspeed | CS8 | CREAD | HUPCL | CRTSCTS);
    if (clocal) rtty.c_cflag |= CLOCAL;
    rtty.c_cc[VEOL] = '\r';
    rtty.c_cc[VMIN]  = 0;
    rtty.c_cc[VTIME] = CHARWAIT;
    if (tcflush(ttyfd, TCIOFLUSH) < 0) return -1;
    if (tcsetattr(ttyfd, TCSANOW, &rtty) < 0) return -1;

    if (!nomodem)
    {
        /* initialize modem for CID */
        if (doModem() < 0) errorExit(-1, ttyport, 0);
    }

    /* take tty port out of raw mode */
    if (tcgetattr(ttyfd, &ntty) < 0) return -1;
    ntty.c_lflag = (ICANON);
    if (tcsetattr(ttyfd, TCSANOW, &ntty) < 0) return -1;

    if (nomodem)
    {
        sprintf(msgbuf, "CallerID TTY port initialized.\n");
        logMsg(LEVEL1, msgbuf);
    }

    return 0;
}

/*
 * Configure the modem
 * returns:  0 if successful
 *          -1 if cannot read from or write to modem
 * exits program if major problem
 */
int doModem()
{
    int cnt, ret = 2;
    char msgbuf[BUFSIZ];

    if (*initstr)
    {
        /*
        * Try to initialize modem, sometimes the modem
        * fails to respond the 1st time, so try multiple
        * times on a no response return code, before
        * indicating no modem.
        */
        for (cnt = 0; ret == 2 && cnt < MODEMTRY; ++cnt)
        {
            if ((ret = initModem(initstr, READTRY)) < 0) return -1;
            sprintf(msgbuf, "Try %d to init modem: return = %d.\n",
                    cnt + 1, ret);
            logMsg(LEVEL3, msgbuf);
        }

        if (ret)
        {
            tcsetattr(ttyfd, TCSANOW, &otty);
            if (ret == 1) errorExit(-103, "Unable to initialize modem",
                                    ttyport);
            else errorExit(-105, "No modem found", ttyport);
        }

        sprintf(msgbuf, "Modem initialized.\n");
        logMsg(LEVEL1, msgbuf);
    }
    else
    {
        /* initstr is null */
        sprintf(msgbuf, "Initialization string for modem is null.\n");
        logMsg(LEVEL1, msgbuf);
    }

    if (!noserial && *initcid)
    {
        /* try to initialize modem for CID */
        if ((ret = initModem(initcid, READTRY)) < 0) return -1;

        if (ret && !setcid)
        {
            /*default init string 1 failed, try default init string 2 */
            initcid = INITCID2;
            if ((ret = initModem(initcid, READTRY)) < 0) return -1;
        }

        if (ret)
        {
            /* CID initialization failed */
            tcsetattr(ttyfd, TCSANOW, &otty);
            errorExit(-103, "Unable to set modem CallerID", ttyport);
        }
        else
        {
            /* CID initialization succeeded */
            sprintf(msgbuf, "Modem set for CallerID.\n");
            logMsg(LEVEL1, msgbuf);
        }
    }
    else if (*initcid == '\0')
    {
        /* initcid is null */
        sprintf(msgbuf, "CallerID initialization string for modem is null.\n");
        logMsg(LEVEL1, msgbuf);
    }

    return 0;
}

/*
 * Initialize modem
 * expects:  initialization string
 * returns:  0 if successful
 *           1 if modem returns "ERROR"
 *           2 if no response, or unexpected response from modem
 *          -1 if cannot read from or write to modem
 */
int initModem(char *ptr, int maxtry)
{
    int num, size, try, ret = 2;
    char buf[BUFSIZ], *bufp;
    char msgbuf[BUFSIZ];

    /* send string to modem */
    strcat(strncpy(buf, ptr, BUFSIZ - 2), CRLF);
    size = strlen(buf);
    if ((num = write(ttyfd, buf, size)) < 0) return -1;
    sprintf(msgbuf, "Sent Modem %d of %d characters: \n%s", num, size, buf);
    logMsg(LEVEL3, msgbuf);

    /* read until OK or ERROR response detected or number of tries exceeded */
    for (size = try = 0; try < maxtry; try++)
    {
        usleep(READWAIT);
        if ((num = read(ttyfd, buf + size, BUFSIZ - size - 1)) < 0) return -1;
        size += num;
        if (size)
        {
            /* check response */
            buf[size] = 0;
            if (strstr(buf, "OK"))
            {
                ret = 0;
                break;
            }
            if (strstr(buf, "ERROR"))
            {
                ret = 1;
                break;
            }
        }
    }
    buf[size] = 0;

    if (size)
    {
        sprintf(msgbuf,
          "Modem response: %d characters in %d %s:\n%s",
            size, try > maxtry ? try -1 : try + 1,
            try == 0 ? "read" : "reads", buf);
        logMsg(LEVEL3, msgbuf);

        /* Remove CRLF at end of string */
        if (buf[size - 1] == '\n' || buf[size - 1] == '\r')
            buf[size - 1] = '\0';
        if (buf[size - 2] == '\r' || buf[size - 2] == '\n')
            buf[size - 2] = '\0';
    }
    else
    {
        sprintf(msgbuf, "No Modem Response\n");
        logMsg(LEVEL3, msgbuf);
    }

    return ret;
}

int tcpOpen(int mainsock)
{
    int     sd, ret, optval;
    static struct  sockaddr_in bind_addr;
    int socksize = sizeof(bind_addr);

    optval = 1;
    bind_addr.sin_family = PF_INET;
    bind_addr.sin_addr.s_addr = 0;    /*  0.0.0.0  ==  this host  */
    memset(bind_addr.sin_zero, 0, 8);
    bind_addr.sin_port = htons(mainsock);
    if ((sd = socket(PF_INET, SOCK_STREAM, 0)) < 0)
        return sd;
    if((ret = setsockopt(sd, SOL_SOCKET, SO_REUSEADDR,
        &optval, sizeof(optval))) < 0)
        return ret;
    if((ret = setsockopt(sd, SOL_SOCKET, SO_KEEPALIVE,
        &optval, sizeof(optval))) < 0)
        return ret;
    if ((ret = bind(sd, (struct sockaddr *)&bind_addr, socksize)) < 0)
    {
        close(sd);
        return ret;
    }
    if ((ret = listen(sd, CONNECTIONS)) < 0)
    {
        close(sd);
        return ret;
    }
    return sd;
}

int  tcpAccept(int sock)
{
    int sd;
    char *ptr;

    struct  sockaddr_in sa;
    unsigned int sa_len = sizeof(sa);

    if ((sd = accept(sock, (struct sockaddr *) &sa, &sa_len)) != -1)
    {
        ptr = ipaddr[sd];
        strcpy(ptr, inet_ntoa(sa.sin_addr));
    }

    return sd;
}

int addPoll(int pollfd)
{
    int added, pos;

    for (added = pos = 0; pos < CONNECTIONS + 2; ++pos)
    {
        if (polld[pos].fd) continue;
        polld[pos].revents = 0;
        polld[pos].fd = pollfd;
        polld[pos].events = (POLLIN | POLLPRI);
        ++added;
        break;
    }
    return added ? pos : -1;
}

void doPoll(int events, int mainsock)
{
  int num, pos, sd = 0, ret, cnt = 0;
  char buf[BUFSIZ], msgbuf[BUFSIZ];
  char *sptr, *eptr;

  /*
   * Poll is configured for POLLIN and POLLPRI events
   * POLLERR, POLLHUP, POLLNVAL events can also happen
   * Poll is not configured for the POLLOUT event
   */

  for (pos = 0; events && pos < CONNECTIONS + 2; ++pos)
  {
    if (!polld[pos].revents) continue; /* no events */

    /* log event flags */
    sprintf(msgbuf, "polld[%d].revents: 0x%X, fd: %d\n",
      pos, polld[pos].revents, polld[pos].fd);
    logMsg(LEVEL9, msgbuf);

    if (polld[pos].revents & POLLHUP) /* Hung up */
    {
      if (!noserial && polld[pos].fd == ttyfd)
      {
        sprintf(buf, "%sSerial device Hung Up, Terminated  %s",
          MSGLINE, strdate(WITHSEP));
        writeClients(mainsock, buf);
        errorExit(-112, "Fatal", "Serial device hung up");
      }
      sprintf(msgbuf, "Hung Up, sd: %d\n", polld[pos].fd);
        logMsg(LEVEL2, msgbuf);
      close(polld[pos].fd);
      polld[pos].fd = polld[pos].events = polld[pos].revents = 0;
    }

    if (polld[pos].revents & POLLERR) /* Poll Error */
    {
      if (!noserial && polld[pos].fd == ttyfd)
      {
        sprintf(buf, "%sSerial device error, Terminated  %s",
          MSGLINE, strdate(WITHSEP));
        writeClients(mainsock, buf);
        errorExit(-112, "Fatal", "Serial device error");
      }
        sprintf(msgbuf, "Poll Error, closed client %d.\n", polld[pos].fd);
        logMsg(LEVEL1, msgbuf);
        close(polld[pos].fd);
        polld[pos].fd = polld[pos].events = polld[pos].revents = 0;
    }

    if (polld[pos].revents & POLLNVAL) /* Invalid Request */
    {
    if (!noserial && polld[pos].fd == ttyfd)
      {
        sprintf(buf, "%sInvalid Request from Serial device, Terminated  %s",
          MSGLINE, strdate(WITHSEP));
        writeClients(mainsock, buf);
        errorExit(-112, "Fatal", "Invalid Request from Serial device");
      }
      sprintf(msgbuf, "Removed client %d, invalid request.\n",
        polld[pos].fd);
      logMsg(LEVEL1, msgbuf);
      polld[pos].fd = polld[pos].events = polld[pos].revents = 0;
    }

    if (polld[pos].revents & POLLOUT) /* Write Event */
    {
      sprintf(msgbuf, "Removed client %d, write event not configured.\n",
        polld[pos].fd);
      logMsg(LEVEL1, msgbuf);
      polld[pos].fd = polld[pos].events = polld[pos].revents = 0;
    }

    if (polld[pos].revents & (POLLIN | POLLPRI))
    {
      if (!noserial && polld[pos].fd == ttyfd)
      {
        if (!locked)
        {
          /* Modem or device has data to read */
          if ((num = read(ttyfd, buf, BUFSIZ-1)) < 0)
          {
            sprintf(msgbuf, "Serial device %d read error: %s\n", ttyfd,
                    strerror(errno));
            errorExit(-112, "Fatal", msgbuf);
          }

          /* Modem or device returned no data */
          else if (!num)
          {
            sprintf(msgbuf, "Serial device %d returned no data.\n", ttyfd);
            logMsg(LEVEL2, msgbuf);
            cnt++;

            /* if no data 10 times in a row, something wrong */
            if (cnt == 10)
            {
              sprintf(buf,
                      "%sSerial device %d returns no data, Terminated  %s",
                MSGLINE, ttyfd, strdate(WITHSEP));
              writeClients(mainsock, buf);
              errorExit(-112, "Fatal", "Serial device returns no data");
            }
          }
          else
          {
            /* Modem or device returned data */

            char *ptr;

            cnt = 0;

            /* Terminate String */
            buf[num] = '\0';

            /* strip <CR> and <LF> */
            if ((ptr = strchr(buf, '\r'))) *ptr = '\0';
            if ((ptr = strchr(buf, '\n'))) *ptr = '\0';

            writeLog(datalog, buf);
            formatCID(mainsock, buf);
          }
        }
      }
      else if (polld[pos].fd == mainsock)
      {
        /* TCP/IP Client Connection */
        if ((sd = tcpAccept(mainsock)) < 0)
        {
          sprintf(msgbuf, "Connect Error: %s, sd: %d\n", strerror(errno), sd);
          logMsg(LEVEL1, msgbuf);
        }
        else
        {
          /* Client connected */

          if (fcntl(sd, F_SETFL, O_NONBLOCK) < 0)
          {
            sprintf(msgbuf, "NONBLOCK Error: %s, sd: %d\n",
              strerror(errno), sd);
            logMsg(LEVEL1, msgbuf);
            close(sd);
          }
          else
          {
            sprintf(buf, "%s %s %s%s", ANNOUNCE, name, VERSION, CRLF);
            ret = write(sd, buf, strlen(buf));
            if (addPoll(sd) < 0)
            {
              sprintf(msgbuf, "%s\n", TOOMSG);
              logMsg(LEVEL1, msgbuf);
              sprintf(buf, "%s: %d%s", TOOMSG, CONNECTIONS, CRLF);
              ret = write(sd, buf, strlen(buf));
              close(sd);
            }
            if (sendlog)
            {
              /* Client connect message in sendLog() */
              sendLog(sd, buf);
            }
            else
            {
              /* Client connected, CID log not sent */
              sprintf(msgbuf, "Client %d from %s connected.\n", sd, ipaddr[sd]);
              logMsg(LEVEL3, msgbuf);
            }
          }
        }
      }
      else
      {
        if (polld[pos].fd)
        {
          if ((num = read(polld[pos].fd, buf, BUFSIZ-1)) < 0)
          {
            sprintf(msgbuf, "Client %d read error (%d): %s\n", polld[pos].fd,
                    errno, strerror(errno));
            logMsg(LEVEL1, msgbuf);
            if (errno != EAGAIN)
            {
                sprintf(msgbuf, "Client %d removed.\n", polld[pos].fd);
                logMsg(LEVEL1, msgbuf);
                close(polld[pos].fd);
                polld[pos].fd = polld[pos].events = polld[pos].revents = 0;
            }
            logMsg(LEVEL1, msgbuf);
          }
          /* read will return 0 for a disconnect */
          if (num == 0)
          {
            /* TCP/IP Client End Connection */
            sprintf(msgbuf, "Client %d disconnected.\n", polld[pos].fd);
              logMsg(LEVEL3, msgbuf);
            close(polld[pos].fd);
            *ipaddr[sd] = '\0';
            polld[pos].fd = polld[pos].events = polld[pos].revents = 0;
          }
          else
          {
            /*
             * Client sent message to server
             */

            char *ptr;

            /* Terminate String */
            buf[num] = '\0';

            /* strip <CR> and <LF> */
            if ((ptr = strchr(buf, '\r'))) *ptr = '\0';
            if ((ptr = strchr(buf, '\n'))) *ptr = '\0';

            /*
             * Check first character is a 7-bit unsigned char value
             * if not, assume entire line is not wanted.  This may
             * need to be improved, but this gets rid of telnet binary.
             */
             if (isascii((int) buf[0]) == 0)
             {
                buf[0] = '\0';
                sprintf(msgbuf, "Message deleted, not 7-bit ASCII, sd: %d\n",
                  polld[pos].fd);
                logMsg(LEVEL3, msgbuf);
             }

            /* Make sure there is data in the message line */
            if (strlen(buf) != 0)
            {

              /* Look for CALL, CALLINFO, or MSG lines */
              if (strncmp(buf, CALL, strlen(CALL)) == 0)
              {
                /*
                 * Found a CALL Line
                 * See comments for formatCID for line format
                 */

                sprintf(msgbuf, "Gateway (sd %d) sent CALL data.\n",
                  polld[pos].fd);
                logMsg(LEVEL3, msgbuf);

                writeLog(datalog, buf);
                formatCID(mainsock, buf + strlen(CALL));
              }
              else if (strncmp(buf, CALLINFO, strlen(CALLINFO)) == 0)
              {
                /*
                 * Found a CALLINFO Line
                 *
                 * CALLINFO Line Format:
                 *  CALLINFO: ###CANCEL...DATE%s...CALLIN...LINE%s...NMBR%s+++
                 *  CALLINFO: ###CANCEL...DATE%s...CALLOUT...LINE%s...NMBR%s+++
                 *  CALLINFO: ###BYE...DATE%s...CALLIN...LINE%s...NMBR%s+++
                 *  CALLINFO: ###BYE...DATE%s...CALLOUT...LINE%s...NMBR%s+++
                 */

                sprintf(msgbuf, "Gateway (sd %d) sent CALLINFO:\n",
                        polld[pos].fd);
                logMsg(LEVEL3, msgbuf);

                writeLog(datalog, buf);

                /* get the line label */
                if ((sptr = strstr(buf, "LINE")) == NULL)
                    strcpy(ringline, "-");
                else
                {
                    *(eptr = index(sptr + 4, (int) '.')) = '\0';
                    strcpy(ringline, sptr + 4);
                    /* Restore buffer by replacing '\0' with '.' */
                    *eptr = '.';
                }

                if (strstr(buf, CANCEL))
                {
                ring = -1;
                sendInfo(mainsock);
                ring = 0;
                }
                else if (strstr(buf, BYE))
                {
                ring = -2;
                sendInfo(mainsock);
                ring = 0;
                }
              }
              else if (strncmp(buf, CIDLINE, strlen(CIDLINE)) == 0)
              {
                /*
                 * Found a CID: line from another NCID server
                 *
                 * record the CID: line in the cidcall file
                 * write line to cidlog and send line to clients
                 */

                 sprintf(msgbuf, "Gateway (sd %d) sent CID:\n",
                         polld[pos].fd);
                 logMsg(LEVEL3, msgbuf);
                 writeLog(cidlog, buf);
                 writeClients(mainsock, buf);
              }
              else if (strncmp(buf, CIDINFO, strlen(CIDINFO)) == 0)
              {
                /*
                 * Found a CIDINFO: line from another NCID server
                 *
                 * record the CIDINFO: line in the ciddata file
                 * write line to datalog and send line to clients
                 */
                 sprintf(msgbuf, "Gateway (sd %d) sent CIDINFO:\n",
                         polld[pos].fd);
                 logMsg(LEVEL3, msgbuf);
                 writeLog(datalog, buf);
                 writeClients(mainsock, buf);
              }
              else if (strncmp(buf, MSGLINE, strlen(MSGLINE)) == 0)
              {
                /*
                 * Found a MSG: line
                 * Write message to cidlog and all clients
                 */

                sprintf(msgbuf, "Client %d sent text message.\n",
                        polld[pos].fd);
                logMsg(LEVEL3, msgbuf);
                writeLog(cidlog, buf);
                writeClients(mainsock, buf);
              }
              else
              {
                /*
                 * Found unknown data
                 */

                sprintf(msgbuf, "Client %d sent unknown data.\n",
                        polld[pos].fd);
                logMsg(LEVEL3, msgbuf);
              }
            }
            else
            {
              /*
               * Found empty line
               */

                sprintf(msgbuf, "Client %d sent empty line.\n",
                        polld[pos].fd);
                logMsg(LEVEL8, msgbuf);
            }
          }
        }
        /* file descripter 0 treated as empty slot */
        else polld[pos].fd = polld[pos].events = 0;
      }
    }

    polld[pos].revents = 0;
    --events;
  }
}

/*
 * Format of data from modem:
 *
 * DATE = 0330            -or-  DATE=0330
 * TIME = 1423            -or-  TIME=1423
 * NMBR = 4075551212      -or-  NMBR=4075551212
 * NAME = WIRELESS CALL   -or-  NAME=WIRELESS CALL
 *
 * Format of EXTRA line passed to TCP/IP clients by python cidd (not used)
 *
 * EXTRA: *DATE*0330*TIME*1423*NUMBER*4075551212*MESG*NONE*NAME*WIRELESS CALL*
 *
 * Format of CID line passed to TCP/IP clients by ncidd:
 *
 * CID: *DATE*03302002*TIME*1423*LINE*-*NMBR*4075551212*MESG*NONE*NAME*CALL*
 *
 * Format of data from NetCallerID for three types of calls and a message
 *
 * ###DATE03301423...NMBR4075551212...NAMEWIRELESS CALL+++\r
 * ###DATE03301423...NMBR...NAME-UNKNOWN CALLER-+++\r
 * ###DATE03301423..NMBR...NAME+++\r
 * ###DATE...NMBR...NAME   -MSG OFF-+++\r
 *
 * Gateway CALL Line Format:
 *
 * ###DATEmmddhhss...CALL<IN|OUT>...LINEidentifier...NMBRnumber...NAMEwords+++\r
 */

void formatCID(int mainsock, char *buf)
{
    int hup = 0;
    char cidbuf[BUFSIZ], *ptr, *sptr, *linelabel;
    time_t t;

    /*
     * All Caller ID information is between the 1st and 2nd ring
     *
     * if RING is indicated, clear any Caller ID info received,
     * if NUMBER is not received
     */
    if (strncmp(buf, "RING", 4) == 0)
    {
        /*
         * If distinctive ring, save line indicator, it will be
         * "RING A", "RING B", etc.
         */
         if (strlen(buf) == 6) strncpy(cid.cidline, buf + 5, 1);

        /*
         * If ring information is wanted, send it to the clients.
         */
        if (sendinfo)
        {
            ++ring;
            sendInfo(mainsock);
        }

        if ((cid.status & CIDALL3) == CIDALL3)
        {
            /*
            * date, time, and number were received
            * indicate No NAME, and process
            */
            strncpy(cid.cidname, NONAME, CIDSIZE - 1);
            cid.status |= CIDNAME;
        }
        else if ((cid.status & CIDALT3) == CIDALT3)
        {
            /*
            * date, time, and name were received
            * indicate No Number, and process
            */
            strncpy(cid.cidnmbr, NONUMB, CIDSIZE - 1);
            cid.status |= CIDNMBR;
        }
        else if (cid.status & (CIDNMBR | CIDNAME))
        {
            /*
             * number, name or both received but no date and time
             * add missing data and process
             */
            if (!(cid.status & CIDNMBR))
            {
                strncpy(cid.cidnmbr, NONUMB, CIDSIZE - 1);
                cid.status |= CIDNMBR;
            }
            else if (!(cid.status & CIDNAME))
            {
                strncpy(cid.cidname, NONAME, CIDSIZE - 1);
                cid.status |= CIDNAME;
            }
            ptr = strdate(NOSEP);     /* returns: MMDDYYYY HHMM */
            for(sptr = cid.ciddate; *ptr && *ptr != ' ';) *sptr++ = *ptr++;
            *sptr = '\0';
            for(sptr = cid.cidtime, ptr++; *ptr;) *sptr++ = *ptr++;
            *sptr = '\0';
            cid.status |= (CIDDATE | CIDTIME);
        }
        else if (gencid && cidsent == 0 && ring == 2 )
        {
            /*
             * gencid = 1: generate a Caller ID if non received
             * gencid = 0: do not generate a Caller ID if non received
             *
             * CID information always received between before RING 2
             * no CID information received, so create one.
             */
            ptr = strdate(NOSEP);     /* returns: MMDDYYYY HHMM */
            for(sptr = cid.ciddate; *ptr && *ptr != ' ';) *sptr++ = *ptr++;
            *sptr = '\0';
            for(sptr = cid.cidtime, ptr++; *ptr;) *sptr++ = *ptr++;
            *sptr = '\0';
            strncpy(cid.cidnmbr, "RING", CIDSIZE - 1);
            strncpy(cid.cidname, NOCID, CIDSIZE - 1);
            cid.status = (CIDDATE | CIDTIME | CIDNMBR | CIDNAME);
        }
        else
        {
            /*
             * At a RING
             * CID already processed or is incomplete
             * Make sure status is clear
             */
            cid.status = 0;
            return;
        }
    }

    /*
     * A Mac Mini Motorola Jump  modem sends "^PR^PX\n\n" before the CID
     * information.  It also sends "^P.^XNAME"
     */
     if ((ptr = strstr(buf, "\020R\020X")))
     {
        cid.status = 0;
     }

    /* Process Caller ID information */
    if (strncmp(buf, "###", 3) == 0)
    {
        /*
         * Found a NetCallerID box, or a Gateway
         * All information received on one line
         * The Gateway creates a CID Message Line
         * The Gateway contains a LINE and a CALL field
         * The NetCallerID box does not have a LINE or CALL field
         */

        /* Make sure the status field and cidsent is zero */
        cid.status = cidsent = 0;

        if ((ptr = strstr(buf, "DATE")))
        {
            if (*(ptr + 4) == '.')
            {
                /* no date and time, create both */
                ptr = strdate(NOSEP);
                strncpy(cid.ciddate, ptr, 8);
                cid.ciddate[8] = 0;
                cid.status |= CIDDATE;
                strncpy(cid.cidtime, ptr + 9, 4);
                cid.cidtime[4] = 0;
                cid.status |= CIDTIME;
            }
            else
            {
                strncpy(cid.cidtime, ptr + 8, 4);
                cid.cidtime[4] = 0;
                cid.status |= CIDTIME;

                strncpy(cid.ciddate, ptr + 4, 4);
                cid.ciddate[4] = 0;

                /* need to generate year */
                t = time(NULL);
                ptr = ctime(&t);
                *(ptr + 24) = 0;
                strncat(cid.ciddate, ptr + 20,
                        CIDSIZE - strlen(cid.ciddate) - 1);
                cid.status |= CIDDATE;
            }
        }
        if ((ptr = strstr(buf, "CALLOUT")))
        {
            /*
             * this field is only from a Gateway
             * will be either CALLIN or CALLOUT
             * only interested in CALLOUT
             */
             ++callout; /* this is a outgiing call */
            
        }
        if ((ptr = strstr(buf, "LINE")))
        {
            /* this field is only from a Gateway */
            if (*(ptr + 5) == '.') strncpy(cid.cidline, lineid, CIDSIZE - 1);
            else
            {
                strncpy(cid.cidline, ptr + 4, CIDSIZE -1);
                ptr = strchr(cid.cidline, '.');
                if (ptr) *ptr = 0;
            }
        }
        if ((ptr = strstr(buf, "NMBR")))
        {
            if (*(ptr + 5) == '.') strncpy(cid.cidnmbr, NONUMB, CIDSIZE - 1);
            else
            {
                strncpy(cidbuf, ptr + 4, BUFSIZ -1);
                ptr = strchr(cidbuf, '.');
                if (ptr) *ptr = 0;
                builtinAlias(cid.cidnmbr, cidbuf);
            }
            cid.status |= CIDNMBR;
        }
        if ((ptr = strstr(buf, "NAME")))
        {
            if (*(ptr + 5) == '+') strncpy(cid.cidname, NONAME, CIDSIZE - 1);
            else
            {
                strncpy(cidbuf, ptr + 4, BUFSIZ -1);
                ptr = strchr(cidbuf, '+');
                if (ptr) *ptr = 0;
                builtinAlias(cid.cidname, cidbuf);
            }
            cid.status |= CIDNAME;
        }
    }
    else if (strncmp(buf, "DATE", 4) == 0)
    {
        strncpy(cid.ciddate, buf[4] == '=' ? buf + 5 : buf + 7, CIDSIZE - 1);
        t = time(NULL);
        ptr = ctime(&t);
        *(ptr + 24) = 0;
        strncat(cid.ciddate, ptr + 20, CIDSIZE - strlen(cid.ciddate) - 1);
        cid.status |= CIDDATE;
        cidsent = 0;
    }
    else if (strncmp(buf, "TIME", 4) == 0)
    {
        strncpy(cid.cidtime, buf[4] == '=' ? buf + 5 : buf + 7, CIDSIZE - 1);
        cid.status |= CIDTIME;
        cidsent = 0;
    }
    /*
     * Using strstr() instead of strncmp() becuse some modems send
     * DDN_NMBR instead of just NMBR.  This will catch both cases.
     */
    else if ((ptr = strstr(buf, "NMBR")))
    {
        /* some telcos send NMBR = ##########, then NMBR = O to mask it */
        if (!(cid.status & CIDNMBR))
        {
            builtinAlias(cid.cidnmbr, *(ptr + 4) == '=' ? ptr + 5 : ptr + 7);
            cid.status |= CIDNMBR;
            cidsent = 0;
        }
    }
    /*
     * Using strstr() instead of strncmp() because a Mac
     * Mini Jump modem sent '^P.^PXNAME' instead of 'NAME'.
     * At this point the string was converted to '?.?XNAME'
     */
    else if ((ptr = strstr(buf, "NAME")))
    {
        /* if NAME already sent, discard the second one */
        if (!(cid.status & CIDNAME))
        {
            /* remove any trailing spaces */
            for (sptr = buf; *sptr; ++sptr);
            for (--sptr; *sptr && *sptr == ' '; --sptr) *sptr = 0;

            builtinAlias(cid.cidname, *(ptr + 4) == '=' ? ptr + 5 : ptr + 7);
            cid.status |= CIDNAME;
            cidsent = 0;
        }
    }
    else if (strncmp(buf, "MESG", 4) == 0)
    {
        strncpy(cid.cidmesg, buf[4] == '=' ? buf + 5 : buf + 7, CIDSIZE - 1);
        cid.status |= CIDMESG;
        cidsent = 0;
    }

    if ((cid.status & CIDALL4) == CIDALL4)
    {
        /*
         * All Caller ID or outgoing call information received.
         *
         * Create the CID (Caller ID), OUT (outgoing call),
         * or HUP (hungup call) text line
         *
         * For OUT text lines (outgoing calls):
         *     the MESG field is not used
         *     the NAME field will be generic if no alias
         *
         * For HUP text lines (hungup call):
         * The CID label is replaced by a HUP label
         */

        userAlias(cid.cidnmbr, cid.cidname, cid.cidline);

        linelabel = CIDLINE;
        if (callout) linelabel = OUTLINE;
        else if (hangup)
        {
            /* hangup phone if on blacklist */
            if (hup = doHangup(cid.cidname, cid.cidnmbr)) linelabel = HUPLINE;
        }

        sprintf(cidbuf, "%s%s%s%s%s%s%s%s%s%s%s%s%s%s",
            linelabel,
            DATE, cid.ciddate,
            TIME, cid.cidtime,
            LINE, cid.cidline,
            NMBR, cid.cidnmbr,
            MESG, cid.cidmesg,
            NAME, cid.cidname,
            STAR);

        /* Log the CID, OUT, or HUP text line */
        writeLog(cidlog, cidbuf);

        /*
         * Send the CID, OUT, or HUP text line to clients
         */
        writeClients(mainsock, cidbuf);

        /*
         * Reset mesg, line, and status
         * Set sent indicator
         * Reset call out indicator if it was set
         */
        strncpy(cid.cidmesg, NOMESG, CIDSIZE - 1); /* default message */
        strcpy(cid.cidline, lineid); /* default line indicator */
        cid.status = 0;
        cidsent = 1;
        if (callout) callout = 0;
    }
}

/*
 * Built-in Aliases for O, P, and A
 */

void builtinAlias(char *to, char *from)
{
    if (!strcmp(from, "O")) strncpy(to, O, CIDSIZE - 1);
    else if (!strcmp(from, "P")) strncpy(to, P, CIDSIZE - 1);
    else if (!strcmp(from, "A")) strncpy(to, A, CIDSIZE - 1);
    else strncpy(to, from, CIDSIZE - 1);
}

/*
 * User defined aliases.
 */

void userAlias(char *nmbr, char *name, char *line)
{
    int i;

    /* we may want to skip the leading 1, if present */
    if (ignore1 && *nmbr == '1') ++nmbr;

    for (i = 0; i < ALIASSIZE && alias[i].type; ++i)
    {
        switch (alias[i].type)
        {
            case NMBRNAME:
                if (!strcmp(nmbr, alias[i].from)) strcpy(nmbr, alias[i].to);
                if (!strcmp(name, alias[i].from)) strcpy(name, alias[i].to);
                break;
            case NMBRONLY:
                if (!strcmp(nmbr, alias[i].from)) strcpy(nmbr, alias[i].to);
                break;
            case NMBRDEP:
                if (!strcmp(name, alias[i].depend) &&
                    (!strcmp(nmbr, alias[i].from) ||
                    !strcmp(alias[i].from, "*")))
                    strcpy(nmbr, alias[i].to);
                break;
            case NAMEONLY:
                if (!strcmp(name, alias[i].from)) strcpy(name, alias[i].to);
                break;
            case NAMEDEP:
                if (!strcmp(nmbr, alias[i].depend) &&
                    (!strcmp(name, alias[i].from) ||
                    !strcmp(alias[i].from, "*")))
                    strcpy(name, alias[i].to);
                break;
            case LINEONLY:
                if (!strcmp(line, alias[i].from) ||
                   !strcmp(alias[i].from, "*")) strcpy(line, alias[i].to);
                break;
        }
    }
}

/*
 * Send string to all TCP/IP CID clients.
 */

void writeClients(int mainsock, char *inbuf)
{
    int pos, ret;
    char buf[BUFSIZ];

    strcat(strcpy(buf, inbuf), CRLF);
    for (pos = 0; pos < CONNECTIONS + 2; ++pos)
    {
        if (polld[pos].fd == 0 || polld[pos].fd == ttyfd ||
            polld[pos].fd == mainsock)
            continue;
        ret = write(polld[pos].fd, buf, strlen(buf));
    }
}

/*
 * Send log, if log file exists.
 */

void sendLog(int sd, char *logbuf)
{
    struct stat statbuf;
    char *iptr = 0, *optr, input[BUFSIZ], msgbuf[BUFSIZ];
    FILE *fp;
    int ret, len;

    if (stat(cidlog, &statbuf) == 0)
    {
        if ((unsigned) statbuf.st_size > cidlogmax)
        {
            sprintf(logbuf, LOGMSG, statbuf.st_size, cidlogmax, CRLF);
            ret = write(sd, logbuf, strlen(logbuf));
            sprintf(msgbuf, LOGMSG, statbuf.st_size, cidlogmax, NL);
            logMsg(LEVEL1, msgbuf);
            return;
        }
    }

    if ((fp = fopen(cidlog, "r")) == NULL)
    {
        sprintf(msgbuf, "cidlog: %s\n", strerror(errno));
        logMsg(LEVEL4, msgbuf);
        return;
    }

    /*
     * read each line of file, one line at a time
     * add "LOG" to line tag (CID: becomes CIDLOG:)
     * send line to clients
     */
    while (fgets(input, BUFSIZ - sizeof(LINETYPE), fp) != NULL)
    {
        /* strip <CR> and <LF> */
        if ((iptr = strchr( input, '\r')) != NULL) *iptr = 0;
        if ((iptr = strchr( input, '\n')) != NULL) *iptr = 0;

        optr = logbuf;
        if (strstr(input, ": ") != NULL)
        {
            /* copy line tag, skip ": " */
            for(iptr = input; *iptr != ':';) *optr++ = *iptr++;
            iptr += 2;
        }
        else iptr = input;
        strcat(strcat(strcpy(optr, LOGLINE), iptr), CRLF);
        len = strlen(logbuf);
        ret = write(sd, logbuf, len);

        optr = logbuf;
        while ((ret != -1 && ret != len) ||
               (ret == -1 && (errno == EAGAIN || errno == EWOULDBLOCK)))
        {
            /* short write or resource busy, need to attempt subsequent write */

            if (ret != -1 && ret != len)
            {
               /* short write, */
               len -= ret;
               optr += ret;
            }

            /* short delay before trying to rewrite line or rest of line */
            usleep(READWAIT);
            ret = write(sd, optr, len);
        }

        if (ret == -1)
        {
            /* write error */
            sprintf(msgbuf, "sending log: %d %s\n", errno, strerror(errno));
            logMsg(LEVEL1, msgbuf);
        }
    }

    (void) fclose(fp);

    /* Determine if a Call Log was sent */
    if (iptr)
    {
        /* Indicate end of the Call Log */
        sprintf(msgbuf, "%s%s", LOGEND, CRLF);
        ret = write(sd, msgbuf, strlen(msgbuf));
    }

    sprintf(msgbuf, "Client %d from %s connected, sent call log: %s\n",
            sd, ipaddr[sd], cidlog);
    logMsg(LEVEL3, msgbuf);
}

/*
 * Write log, if logfile exists.
 */

void writeLog(char *logf, char *logbuf)
{
    int logfd, ret;
    char msgbuf[BUFSIZ];

    if ((logfd = open(logf, O_WRONLY | O_APPEND)) < 0)
    {
        sprintf(msgbuf, "%s: %s\n", logf, strerror(errno));
        logMsg(LEVEL4, msgbuf);
    }
    else
    {
        /* write log entry */
        sprintf(msgbuf, "%s\n", logbuf);
        ret = write(logfd, msgbuf, strlen(msgbuf));
        close(logfd);

        /* log to server log */
        logMsg(LEVEL3, msgbuf);
    }
}

/*
 * Send call information
 *
 * Format of CIDINFO line passed to TCP/IP clients by ncidd:
 *
 * CIDINFO: *LINE*-*RING*1*
 */

void sendInfo(int mainsock)
{
    char buf[BUFSIZ], *ptr;

    userAlias("", "", ringline);
    sprintf(buf, "%s%s%s%s%d%s%s%s",CIDINFO, LINE, ringline, \
            RING, ring, TIME, strdate(ONLYTIME), STAR);
    writeClients(mainsock, buf);

    strcat(buf, NL);
    logMsg(LEVEL3, buf);
}

/*
 * Returns the current date and time as a string in the format:
 *      WITHSEP:     MM/DD/YYYY HH:MM:SS
 *      NOSEP:       MMDDYYYY HHMM
 *      ONLYTIME:    HH:MM:SS
 *      LOGFILETIME: HH:MM:SS.ssss
 */
char *strdate(int separator)
{
    static char buf[BUFSIZ];
    struct tm *tm;
    struct timeval tv;

    (void) gettimeofday(&tv, 0);
    tm = localtime((time_t *) &(tv.tv_sec));
    if (separator & WITHSEP)
        sprintf(buf, "%.2d/%.2d/%.4d %.2d:%.2d:%.2d", tm->tm_mon + 1,
            tm->tm_mday, tm->tm_year + 1900, tm->tm_hour, tm->tm_min,
            tm->tm_sec);
    else if (separator & NOSEP)
        sprintf(buf, "%.2d%.2d%.4d %.2d%.2d", tm->tm_mon + 1, tm->tm_mday,
            tm->tm_year + 1900, tm->tm_hour, tm->tm_min);
    else if (separator & ONLYTIME)
        sprintf(buf, "%.2d:%.2d:%.2d",  tm->tm_hour, tm->tm_min, tm->tm_sec);
    else /* LOGFILETIME */
        sprintf(buf, "%.2d:%.2d:%.2d.%.4ld",  tm->tm_hour, tm->tm_min,
                tm->tm_sec, tv.tv_usec / 100);
    return buf;
}

/*
 * if PID file exists, and PID in process table, ERROR
 * if PID file exists, and PID not in process table, replace PID file
 * if no PID file, write one
 * if write a pidfile failed, OK
 * If pidfile == 0, do not write PID file
 */
int doPID()
{
    struct stat statbuf;
    char msgbuf[BUFSIZ];
    FILE *pidptr;
    pid_t curpid, foundpid = 0;
    int ret;

    /* if pidfile == 0, no pid file is wanted */
    if (pidfile == 0)
    {
        logMsg(LEVEL1, "Not using PID file, there was no '-P' option.\n");
        return 0;
    }

    /* check PID file */
    curpid = getpid();
    if (stat(pidfile, &statbuf) == 0)
    {
        if ((pidptr = fopen(pidfile, "r")) == NULL) return(1);
        ret = fscanf(pidptr, "%u", &foundpid);
        fclose(pidptr);
        if (foundpid) ret = kill(foundpid, 0);
        if (ret == 0 || (ret == -1 && errno != ESRCH)) return(1);
        sprintf(msgbuf, "Found stale pidfile: %s\n", pidfile);
        logMsg(LEVEL1, msgbuf);
    }

    /* create logfile */
    if ((pidptr = fopen(pidfile, "w")) == NULL)
    {
        sprintf(msgbuf, "Cannot write %s: %s\n", pidfile, strerror(errno));
        logMsg(LEVEL2, msgbuf);
    }
    else
    {
        pid = curpid;
        fprintf(pidptr, "%d\n", pid);
        fclose(pidptr);
        sprintf(msgbuf, "Wrote pid %d in pidfile: %s\n", pid, pidfile);
        logMsg(LEVEL1, msgbuf);
    }

    return(0);
}

/*
 * Check if lockfile present and has an active process number in it
 * ret == 0 if lockfile is not present or lockfile has stale process number
 * ret == 1 if lockfile present and process number active, or error
 */

int CheckForLockfile()
{
    int kret, ret = 0, lockp;
    static unsigned int sentmsg = 0;
    FILE *fp;
    char lockbuf[BUFSIZ];
    char msgbuf[BUFSIZ];
    struct stat statbuf;

    if (lockfile != 0)
    {
        if (stat(lockfile, &statbuf) == 0)
        {
            ret = 1;
            if ((fp = fopen(lockfile, "r")) == NULL)
            {
                if (!(sentmsg & 1))
                {
                    sprintf(msgbuf, "%s: %s\n", lockfile, strerror(errno));
                    logMsg(LEVEL1, msgbuf);
                    sentmsg |= 1;
                }
            }
            else
            {
                if (fgets(lockbuf, BUFSIZ - 1, fp) != NULL)
                {
                    lockp = atoi(lockbuf);
                    if (lockp)
                    {
                        /* lockfile contains a process number */
                        kret = kill(lockp, 0);
                        if (kret && errno != EPERM)
                        {
                            /* the error is not permission denied */
                            if (unlink(lockfile))
                            {
                                if (!(sentmsg & 2))
                                {
                                    sprintf(msgbuf,
                                        "Failed to remove stale lockfile: %s\n",
                                        lockfile);
                                    logMsg(LEVEL1, msgbuf);
                                    sentmsg |= 2;
                                }
                            }
                            else
                            {
                                sprintf(msgbuf, "Removed stale lockfile: %s\n",
                                        lockfile);
                                logMsg(LEVEL1, msgbuf);
                                ret = 0;
                            }
                        }
                    }
                    fclose(fp);
                }
            }
        }
    }

/* clear all locally latched failures if lockfile no longer present */
if (ret == 0) sentmsg = 0;

return ret;
}

/*
 * Close all file descriptors and restore tty parameters.
 */

void cleanup()
{
    int pos;

    /* restore tty parameters */
    if (ttyfd > 2)
    {
        tcflush(ttyfd, TCIOFLUSH);
        tcsetattr(ttyfd, TCSANOW, &otty);
    }

    /* close open files */
    for (pos = 0; pos < CONNECTIONS + 2; ++pos)
        if (polld[pos].fd != 0) close(polld[pos].fd);

    /* close log file, if open */
    if (logptr) fclose(logptr);
}

/* signal exit */
void finish(int sig)
{
    char msgbuf[BUFSIZ];

    /* remove pid file, if it was created */
    if (pid)
    {
        unlink(pidfile);
        sprintf(msgbuf, "Removed pidfile: %s\n", pidfile);
        logMsg(LEVEL1, msgbuf);
    }

    sprintf(msgbuf, "Received Signal %d: %s\nTerminated: %s\n",
            sig, strsignal(sig), strdate(WITHSEP));
    logMsg(LEVEL1, msgbuf);

    cleanup();

    /* allow signal to terminate the process */
    signal (sig, SIG_DFL);
    raise (sig);
}

/* reload signal */
void reload(int sig)
{
    char msgbuf[BUFSIZ];

    sprintf(msgbuf,
      "Received Signal %d: %s\nReloading alias %s: %s\n",
      sig, strsignal(sig), hangup ? "and blacklist files" : "file",
      strdate(WITHSEP));
    logMsg(LEVEL1, msgbuf);

    /*
     * Decided not to do a reconfig because it seems like too much work
     * for a small gain:
     *   - open configurable files need to be closed and opened again
     *   - configuration verbose indicators, need to be output again
     * if (doConf()) errorExit(-104, 0, 0);
     */

    /* remove existing aliases to free memory used */
    rmaliases();

    /* remove existing blacklist entries to free memory used */
    rmbl();

    /* reload alias file, but quit on error */
    if (doAlias()) errorExit(-109, 0, 0);

    /* reload blacklist file if hangup option given, but quit on error */
    if (hangup && doBlacklist()) errorExit(-114, 0, 0);
}

/* ignored signals */
void ignore(int sig)
{
    char msgbuf[BUFSIZ];

    sprintf(msgbuf, "Received Signal %d: %s\nIgnored: %s\n",
            sig, strsignal(sig), strdate(WITHSEP));
    logMsg(LEVEL1, msgbuf);
}

int errorExit(int error, char *msg, char *arg)
{
    char msgbuf[BUFSIZ];

    if (error == -1)
    {
        /* should not happen */
        if (msg == 0) msg = "oops";

        /*
         * system error
         * print msg, arg should be zero
         */
        error = errno;
        sprintf(msgbuf, "%s: %s\n", msg, strerror(errno));
        logMsg(LEVEL1, msgbuf);
    }
    else
    {
        /* should not happen */
        if (msg != 0 && arg == 0) arg = "oops";

        /*
         * internal program error
         * print msg and arg if both are not 0
         */
        if (msg != 0 && arg != 0)
        {
            sprintf(msgbuf, "%s: %s\n", msg, arg);
            logMsg(LEVEL1, msgbuf);
        }
    }

    /* remove pid file, if it was created */
    if (pid)
    {
        unlink(pidfile);
        sprintf(msgbuf, "Removed pidfile: %s\n", pidfile);
        logMsg(LEVEL1, msgbuf);
    }

    /* do not print terminated message, or cleanup, if option error */
    if (error != -100 && error != -101 && error != -106 && error != -107 &&
        error != -108 && error != -113)
    {
        sprintf(msgbuf, "Terminated:  %s\n", strdate(WITHSEP));
        logMsg(LEVEL1, msgbuf);
        cleanup();
    }

    exit(error);
}

/*
 * log messages, and print messages in debug mode
 */
void logMsg(int level, char *message)
{
    /* write to stdout in debug mode */
    if (debug && verbose >= level) fputs(message, stdout);

    /* write to logfile */
    if (logptr && verbose >= level)
    {
        fputs(message, logptr);
        fflush(logptr);
    }
}
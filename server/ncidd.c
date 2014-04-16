/*
 * ncidd.c - This file is part of ncidd.
 *
 * Copyright (c) 2005-2014
 * by John L. Chmielewski <jlc@users.sourceforge.net>
 *
 * ncidd is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * ncidd is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with ncidd.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "ncidd.h"

/* globals */
char *cidlog  = CIDLOG;
char *datalog = DATALOG;
char *ttyport = TTYPORT;
char *initstr = INITSTR;
char *initcid = INITCID1;
char *logfile = LOGFILE;
char *pidfile, *fnptr;
char *lineid  = ONELINE;
char *lockfile, *name;
char *TTYspeed;
int ttyspeed = TTYSPEED;
int port = PORT;
int debug, conferr, setcid, locked, sendlog, sendinfo, calltype, cidnoname;
int ttyfd, mainsock, pollpos, pollevents, update_call_log = 0;
int ring, ringwait, lastring, clocal, nomodem, noserial, gencid = 1;
int cidsent, verbose = 1, hangup, ignore1, OSXlaunchd;
long unsigned int cidlogmax = LOGMAX;
pid_t pid;

char tmpIPaddr[MAXIPADDR];
char IPaddr[MAXCONNECT][MAXIPADDR];
char infoline[CIDSIZE] = ONELINE;

struct pollfd polld[MAXCONNECT];
struct termios otty, rtty, ntty;
FILE *logptr;

/* ack[pos] is for same client/gateway as in polld[pos] */
int ack[MAXCONNECT]; /* only for clients */

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

struct mesg
{
    char date[CIDSIZE];
    char time[CIDSIZE];
    char nmbr[CIDSIZE];
    char name[CIDSIZE];
    char line[CIDSIZE];
} mesg;

struct end
{
    char htype[CIDSIZE];
    char ctype[CIDSIZE];
    char  date[CIDSIZE];
    char  time[CIDSIZE];
    char scall[CIDSIZE];
    char ecall[CIDSIZE];
    char  line[CIDSIZE];
    char  nmbr[CIDSIZE];
    char  name[CIDSIZE];
} endcall;

/* All line labels of interest to a client, new types must be added */
char *lineTags[] =
{
    CIDLINE,
    MSGLINE,
    OUTLINE,
    HUPLINE,
    BLKLINE,
    PIDLINE,
    NOTLINE,
    ENDLINE,
    "NULL"
};

char *strdate();
#ifndef __CYGWIN__
    extern char *strsignal();
#endif

void exit(), finish(), free(), reload(), ignore(), doPoll(), formatCID(),
     writeClients(), writeLog(), sendLog(), sendInfo(), logMsg(), cleanup(),
     update_cidcall_log(), getINFO(), getField();

int getOptions(), doConf(), errorExit(), doAlias(), doTTY(), CheckForLockfile(),
    addPoll(), tcpOpen(), doModem(), initModem(), gettimeofday(), doPID(),
    tcpAccept(), openTTY();

int main(int argc, char *argv[])
{
    int events, argind, i, fd, errnum, ret;
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
    logptr = fopen(logfile, "a+");
    errnum = errno;

    sprintf(msgbuf, "Started: %s\nServer: %s %s\n",strdate(WITHSEP),
            name, VERSION);
    logMsg(LEVEL1, msgbuf);

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

    /* check status of logfile */
    if (logptr)
    {
        /* logfile opened */
        sprintf(msgbuf, "Logfile: %s\n", logfile);
        logMsg(LEVEL1, msgbuf);
    }
    else
    {
        /* logfile open failed */
        sprintf(msgbuf, "%s: %s\n", logfile, strerror(errnum));
        logMsg(LEVEL1, msgbuf);
    }

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

    if (cidnoname)
    {
        sprintf(msgbuf,
            "Configured to receive a CID without a NAME\n");
        logMsg(LEVEL1, msgbuf);
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
     * indicate location of helper scripts
     */
    sprintf(msgbuf, "Helper tools:\n    %s\n    %s\n", NCIDUPDATE, NCIDUTIL);
    logMsg(LEVEL1, msgbuf);

    /*
     * read alias file, if present, exit on any errors
     */
    if (doAlias()) errorExit(-109, 0, 0);
    sprintf(msgbuf, "%s\n", ignore1 ? IGNORE1 : INCLUDE1);
    logMsg(LEVEL1, msgbuf);

    if (hangup)
    {
        /* read blacklist and whitelist files, exit on any errors */
        sprintf(msgbuf, "%s\n", BLMSG);
        logMsg(LEVEL1, msgbuf);
        if (doList(blacklist, blklist)) errorExit(-114, 0, 0);

        sprintf(msgbuf, "%s\n", WLMSG);
        logMsg(LEVEL1, msgbuf);
        if (doList(whitelist, whtlist)) errorExit(-114, 0, 0);
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

    /*
     * lineid could have been changed in either ncidd.conf or ncidd.alias
     * this sets cid.cidline  and infoline to lineid after any changes to it
     */
    strncpy(cid.cidline, lineid, CIDSIZE - 1);
    strncpy(infoline, lineid, CIDSIZE - 1);

    sprintf(msgbuf, "Maximum number of clients/gateways: %d\n",
            noserial ? MAXCLIENTS + 1 : MAXCLIENTS);
    logMsg(LEVEL1, msgbuf);

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
        sprintf(msgbuf, "Hangup option set %s on a blacklisted call\n",
        hangup == 1 ? "hangup" : "answer as a FAX then hangup");
        logMsg(LEVEL1, msgbuf);
        if (noserial)
        {
            (void) close(ttyfd);
            ttyfd = 0;
            sprintf(msgbuf, "Modem only used to terminate calls\n");
        }
        else sprintf(msgbuf, "Modem used for CID and to terminate calls\n");
        logMsg(LEVEL1, msgbuf);
    }

    sprintf(msgbuf, "Network Port: %d\n", port);
    logMsg(LEVEL1, msgbuf);

    if (debug || OSXlaunchd)
    {
        if (debug) sprintf(msgbuf, "Debug Mode\n");
        else sprintf(msgbuf, "OSX Launchd Mode\n"); 
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

    /* reload files on SIGHUP */
    signal(SIGHUP, reload);

    /* replace CID call log file on SIGUSR1 */
    signal (SIGUSR1, update_cidcall_log);

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
    if ((mainsock = tcpOpen()) < 0) errorExit(-1, "socket", 0);

    ret = addPoll(mainsock);
    sprintf(msgbuf,"NCID connection socket is sd %d pos %d\n", mainsock, ret);
    logMsg(LEVEL3, msgbuf);

    /* Read and display data */
    while (1)
    {
        switch (events = poll(polld, MAXCONNECT, TIMEOUT))
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
                            sendInfo();
                        }
                        else
                        {
                            /* ringing */
                            ringwait = 0;
                            lastring = ring;
                        }
                    }
                }
                if (update_call_log)
                {
                    update_call_log = 0;
                    sprintf (msgbuf, "%s.new", cidlog);
                    if (access (msgbuf, F_OK) == 0)
                    {
                        rename (msgbuf, cidlog);
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
                            ttyfd = 0;
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
                            writeClients(msgbuf);
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
                doPoll(events);
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
        {"whitelist", 1, 0, 'W'},
        {"osx-launchd", 0, 0, '0'},
        {0, 0, 0, 0}
    };

    while ((c = getopt_long (argc, argv, "c:d:e:g:hi:l:n:p:s:t:v:A:B:C:DH:I:L:M:N:P:S:T:VW:",
        long_options, &option_index)) != -1)
    {
        switch (c)
        {
            case '0':
                ++OSXlaunchd;
                break;
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
                    (!(hangup == 0 && *optarg == '0') && hangup > 2))
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
            case 'W':
                if (!(whitelist = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("whitelist")) >= 0) setword[num].type = 0;
                break;
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
    {
        ttyfd = 0; 
        return -1;
    }
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
    char buf[BUFSIZ];
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

int tcpOpen()
{
    int     sd, ret, optval;
    static struct  sockaddr_in bind_addr;
    int socksize = sizeof(bind_addr);

    optval = 1;
    bind_addr.sin_family = PF_INET;
    bind_addr.sin_addr.s_addr = 0;    /*  0.0.0.0  ==  this host  */
    memset(bind_addr.sin_zero, 0, 8);
    bind_addr.sin_port = htons(port);
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
    if ((ret = listen(sd, MAXCONNECT)) < 0)
    {
        close(sd);
        return ret;
    }
    return sd;
}

int  tcpAccept()
{
    int sd;

    struct  sockaddr_in sa;
    unsigned int sa_len = sizeof(sa);

    if ((sd = accept(mainsock, (struct sockaddr *) &sa, &sa_len)) != -1)
        strcpy(tmpIPaddr, inet_ntoa(sa.sin_addr));

    return sd;
}

int addPoll(int pollfd)
{
    int added = 0, pos;

    for (added = pos = 0; pos < MAXCONNECT; ++pos)
    {
        if (polld[pos].fd) continue;
        ack[pos] = 0;
        polld[pos].revents = 0;
        polld[pos].fd = pollfd;
        polld[pos].events = (POLLIN | POLLPRI);
        ++added;
        break;
    }
    return added ? pos : -1;
}

void doPoll(int events)
{
  int num, pos, sd = 0, ret, cnt = 0;
  char buf[BUFSIZ], tmpbuf[BUFSIZ], msgbuf[BUFSIZ];
  char *sptr, *eptr, *label;

  /*
   * Poll is configured for POLLIN and POLLPRI events
   * POLLERR, POLLHUP, POLLNVAL events can also happen
   * Poll is not configured for the POLLOUT event
   */

  for (pos = 0; events && pos < MAXCONNECT; ++pos)
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
        writeClients(buf);
        errorExit(-112, "Fatal", "Serial device hung up");
      }
      sprintf(msgbuf, "Client %d pos %d Hung Up\n", polld[pos].fd, pos);
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
        writeClients(buf);
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
        writeClients(buf);
        errorExit(-112, "Fatal", "Invalid Request from Serial device");
      }
      sprintf(msgbuf, "Removed client %d, invalid request.\n", polld[pos].fd);
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
              writeClients(buf);
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
            formatCID(buf);
          }
        }
      }
      else if (polld[pos].fd == mainsock)
      {
        /* TCP/IP Client Connection */
        if ((sd = tcpAccept()) < 0)
        {
          sprintf(msgbuf, "Connect Error: %s\n", strerror(errno));
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
            if ((ret = addPoll(sd)) < 0)
            {
              sprintf(msgbuf, "Client trying to connect.\n");
              logMsg(LEVEL1, msgbuf);
              sprintf(msgbuf, NOLOGSENT NL);
              logMsg(LEVEL1, msgbuf);
              sprintf(msgbuf, TOOMSG, noserial ? MAXCLIENTS + 1 : MAXCLIENTS,
                      strdate(WITHSEP), NL);
              logMsg(LEVEL1, msgbuf);
              sprintf(buf, NOLOGSENT CRLF);
              ret = write(sd, buf, strlen(buf));
              sprintf(buf, TOOMSG, noserial ? MAXCLIENTS + 1 :MAXCLIENTS,
                      strdate(WITHSEP), CRLF);
              ret = write(sd, buf, strlen(buf));
              close(sd);
            }
            else
            {
              /* ret is pos in polld for the added sd */
              strcpy(IPaddr[ret], tmpIPaddr);
              sprintf(msgbuf, "Client %d pos %d from %s connected.\n", sd,
                      ret, IPaddr[ret]);
              logMsg(LEVEL3, msgbuf);
              if (sendlog)
              {
                sendLog(sd, buf);
              }
              else
              {
                /* CID log not sent */
                sprintf(msgbuf, "%s%s", NOLOGSENT, CRLF);
                ret = write(sd, msgbuf, strlen(msgbuf));
                sprintf(msgbuf, "Call log not sent: %s\n", cidlog);
                logMsg(LEVEL3, msgbuf);
              }
              if (hangup)
              { 
                sprintf (msgbuf, OPTLINE "hangup" CRLF);
                ret = write (sd, msgbuf, strlen(msgbuf));
                sprintf(msgbuf, "Sent 'hangup' option to client\n");
                logMsg(LEVEL3, msgbuf);
              }
              if (ignore1)
              { 
                sprintf (msgbuf, OPTLINE "ignore1" CRLF);
                ret = write (sd, msgbuf, strlen(msgbuf));
                sprintf(msgbuf, "Sent 'ignore1' option to client\n");
                logMsg(LEVEL3, msgbuf);
              }
              /* End of startup messages */
              sprintf(msgbuf, "%s%s", ENDSTARTUP, CRLF);
              ret = write(sd, msgbuf, strlen(msgbuf));
              sprintf(msgbuf, "%s%s", ENDSTARTUP, NL);
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
            sprintf(msgbuf, "Client %d pos %d read error %d: %s\n",
                    polld[pos].fd, pos, errno, strerror(errno));
            logMsg(LEVEL1, msgbuf);
            if (errno != EAGAIN)
            {
                sprintf(msgbuf, "Client %d pos %d removed.\n", polld[pos].fd, pos);
                logMsg(LEVEL1, msgbuf);
                close(polld[pos].fd);
                polld[pos].fd = polld[pos].events = polld[pos].revents = 0;
            }
          }
          /* read will return 0 for a disconnect */
          else if (num == 0)
          {
            /* TCP/IP Client End Connection */
            sprintf(msgbuf, "Client %d pos %d disconnected.\n", polld[pos].fd, pos);
            logMsg(LEVEL3, msgbuf);
            close(polld[pos].fd);
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
                if (ack[pos])
                {
                    sprintf(msgbuf, "%s%s%s", ACKLINE, buf, CRLF);
                    ret = write(polld[pos].fd, msgbuf, strlen (msgbuf));
                    sprintf(msgbuf, "(sd %d) %s%s%s", polld[pos].fd, ACKLINE, buf, NL);
                    logMsg(LEVEL3, msgbuf);
                }
                formatCID(buf + strlen(CALL));
              }
              else if (strncmp(buf, CALLINFO, strlen(CALLINFO)) == 0)
              {
                /*
                 * Found a CALLINFO Line
                 *
                 * CALLINFO Line Format:
                 *  CALLINFO: ###CANCEL...DATE%s...SCALL%S...ECALL%s...CALLIN...LINE%s...NMBR%s...NAME%s+++
                 *  CALLINFO: ###CANCEL...DATE%s...SCALL%S...ECALL%s...CALLOUT...LINE%s...NMBR%s...NAME%s+++
                 *  CALLINFO: ###BYE...DATE%s...SCALL%S...ECALL%s...CALLIN...LINE%s...NMBR%s...NAME%s+++
                 *  CALLINFO: ###BYE...DATE%s...SCALL%S...ECALL%s...CALLOUT...LINE%s...NMBR%s...NAME%s+++
                 */

                sprintf(msgbuf, "Gateway (sd %d) sent CALLINFO:\n",
                        polld[pos].fd);
                logMsg(LEVEL3, msgbuf);

                writeLog(datalog, buf);

                /* get and process end of call termination */
                if (strstr(buf, CANCEL))
                {
                    strcpy(endcall.htype, CANCEL);
                    ring = -1;
                    sendInfo();
                    ring = 0;
                }
                else if (strstr(buf, BYE))
                {
                    strcpy(endcall.htype, BYE);
                    ring = -2;
                    sendInfo();
                    ring = 0;
                }
                else strcpy(endcall.htype, "-");

                /* get end of call date and time */
                label = "DATE";
                if ((sptr = strstr(buf, label)) != NULL)
                {
                    /* points to MMDDYYYYHHMM */
                    sptr += (strlen(label) + 4); /* HHMM */
                    if (!(eptr = strstr(sptr, "...")))
                        eptr = strstr(sptr, "+++");
                    strncpy(endcall.time, sptr, eptr - sptr);
                    endcall.time[eptr - sptr] = '\0';

                    ptr = strdate(NOSEP);   /* returns: MMDDYYYY HHMM */
                    strcpy(endcall.date, ptr);
                    endcall.date[8] = '\0';     /* MMDDYYYY */
                    
                }
                else
                {
                    strcpy(endcall.date, "-");
                    strcpy(endcall.time, "-");
                }

                /* get end of call start date and extended time */
                label = "SCALL";
                if ((sptr = strstr(buf, label)) != NULL)
                {
                    sptr += strlen(label);
                    if (!(eptr = strstr(sptr, "...")))
                        eptr = strstr(sptr, "+++");
                    strncpy(endcall.scall, sptr, eptr - sptr);
                    endcall.scall[eptr - sptr] = '\0';
                }
                else  strcpy(endcall.scall, "-");

                /* get end of call end date and extended time */
                label = "ECALL";
                if ((sptr = strstr(buf, label)) != NULL)
                {
                    sptr += strlen(label);
                    if (!(eptr = strstr(sptr, "...")))
                        eptr = strstr(sptr, "+++");
                    strncpy(endcall.ecall, sptr, eptr - sptr);
                    endcall.ecall[eptr - sptr] = '\0';
                }
                else  strcpy(endcall.ecall, "-");

                /* get end of call type */
                label = ".CALL";
                if ((sptr = strstr(buf, label)) != NULL)
                {
                    sptr += strlen(label);
                    if (!(eptr = strstr(sptr, "...")))
                        eptr = strstr(sptr, "+++");
                    strncpy(endcall.ctype, sptr, eptr - sptr);
                    endcall.ctype[eptr - sptr] = '\0';
                }
                else  strcpy(endcall.ctype, "-");
                

                /* get end of call line label */
                label = "LINE";
                if ((sptr = strstr(buf, label)) != NULL)
                {
                    sptr += strlen(label);
                    if (!(eptr = strstr(sptr, "...")))
                        eptr = strstr(sptr, "+++");
                    strncpy(endcall.line, sptr, eptr - sptr);
                    endcall.line[eptr - sptr] = '\0';
                    strcpy(infoline, endcall.line);
                }
                else
                {
                    strcpy(infoline, lineid);
                    strcpy(endcall.line, "-");
                }

                /* get end of call telephone number */
                label = "NMBR";
                if ((sptr = strstr(buf, label)) != NULL)
                {
                    sptr += strlen(label);
                    if (!(eptr = strstr(sptr, "...")))
                        eptr = strstr(sptr, "+++");
                    strncpy(endcall.nmbr, sptr, eptr - sptr);
                    endcall.nmbr[eptr - sptr] = '\0';
                }
                else  strcpy(endcall.nmbr, "-");

                /* get end of call name */
                label = "NAME";
                if ((sptr = strstr(buf, label)) != NULL)
                {
                    sptr += strlen(label);
                    if (!(eptr = strstr(sptr, "...")))
                        eptr = strstr(sptr, "+++");
                    strncpy(endcall.name, sptr, eptr - sptr);
                    endcall.name[eptr - sptr] = '\0';
                }
                else  strcpy(endcall.name, "-");

                userAlias(endcall.nmbr, endcall.name, endcall.line);

                sprintf(msgbuf, "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s",
                    ENDLINE,
                    HTYPE, endcall.htype,
                    DATE,  endcall.date,
                    TIME,  endcall.time,
                    SCALL, endcall.scall,
                    ECALL, endcall.ecall,
                    CTYPE, endcall.ctype,
                    LINE,  endcall.line,
                    NMBR,  endcall.nmbr,
                    NAME,  endcall.name,
                    STAR);

                /* Log the end of call "END:" line */
                writeLog(cidlog, msgbuf);
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
                 writeClients(buf);
              }
              else if (strncmp(buf, HUPLINE, strlen(HUPLINE)) == 0)
              {
                /*
                 * Found a HUP: line from another NCID server
                 *
                 * record the HUP: line in the cidcall file
                 * write line to cidlog and send line to clients
                 */

                 sprintf(msgbuf, "Gateway (sd %d) sent HUP:\n",
                         polld[pos].fd);
                 logMsg(LEVEL3, msgbuf);
                 writeLog(cidlog, buf);
                 writeClients(buf);
              }
              else if (strncmp(buf, OUTLINE, strlen(OUTLINE)) == 0)
              {
                /*
                 * Found a OUT: line from another NCID server
                 *
                 * record the OUT: line in the cidcall file
                 * write line to cidlog and send line to clients
                 */

                 sprintf(msgbuf, "Gateway (sd %d) sent OUT:\n",
                         polld[pos].fd);
                 logMsg(LEVEL3, msgbuf);
                 writeLog(cidlog, buf);
                 writeClients(buf);
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
                 writeClients(buf);
              }
              else if (strncmp(buf, MSGLINE, strlen(MSGLINE)) == 0)
              {
                /*
                 * Found a MSG: line
                 * MSG: <message> ###DATE*mmddyyyy*TIME*hhmm*NAME*<name>*NMBR*<number>*LINE*<id>*
                 * Write message to cidlog and all clients
                 */

                sprintf(msgbuf, "Client %d sent text message.\n", polld[pos].fd);
                logMsg(LEVEL3, msgbuf);
                writeLog(datalog, buf);
                getINFO(buf);
                sprintf(tmpbuf, MESSAGE, buf, mesg.date, mesg.time, mesg.name, mesg.nmbr, mesg.line);
                writeLog(cidlog, tmpbuf);
                writeClients(tmpbuf);
              }
              else if (strncmp(buf, NOTLINE, strlen(NOTLINE)) == 0)
              {
                /*
                 * Found a NOT: (remote notification) line from a cell phone
                 * NOT: <message> ###DATE*mmddyyyy*TIME*hhmm*NAME*<name>*NMBR*<number>*LINE*<id>*
                 * Write notice to cidlog and all clients
                 */

                sprintf(msgbuf, "Gateway (sd %d) sent a notice.\n", polld[pos].fd);
                logMsg(LEVEL3, msgbuf);
                writeLog(datalog, buf);
                if (ack[pos])
                {
                    sprintf(msgbuf, "%s%s%s", ACKLINE, buf, CRLF);
                    ret = write(polld[pos].fd, msgbuf, strlen (msgbuf));
                    sprintf(msgbuf, "(sd %d) %s%s%s", polld[pos].fd, ACKLINE, buf, NL);
                    logMsg(LEVEL3, msgbuf);
                }
                getINFO(buf);
                sprintf(tmpbuf, MESSAGE, buf, mesg.date, mesg.time, mesg.name, mesg.nmbr, mesg.line);
                writeLog(cidlog, tmpbuf);
                writeClients(tmpbuf);
              }
              else if (strncmp (buf, REQLINE, strlen(REQLINE)) == 0)
              {
                /* 
                 * Found a REQ: line
                 * Perform the requested action and send a response
                 * back to the client
                 */
                 strcat(strcpy(msgbuf, buf), NL);
                 logMsg(LEVEL2, msgbuf);
                 if (strstr(buf, RELOAD))
                 {
                    long position = 0;

                    if (logptr) {
                        position = ftell (logptr);
                    }
                    reload (1);
                    if (logptr)
                    {
                       *buf = 0;
                       cnt = 0;
                       fseek (logptr, position, SEEK_SET);
                       while (fgets (tmpbuf, sizeof (tmpbuf), logptr) != 0)
                       {
                           cnt += sizeof (INFOLINE) + strlen (tmpbuf);
                           if ((unsigned)cnt >= sizeof (buf) - 2) break;
                           strcat (buf, INFOLINE);
                           strcat (buf, tmpbuf);
                       }
                    }
                    else
                    {
                       strcpy (buf, INFOLINE RELOADED NL);
                    }
                    ret = write (polld[pos].fd, BEGIN_DATA CRLF,
                                 strlen (BEGIN_DATA CRLF));
                    logMsg(LEVEL2, BEGIN_DATA NL);
                    ret = write (polld[pos].fd, buf, strlen(buf));
                    logMsg(LEVEL2, buf);
                    ret = write (polld[pos].fd, END_DATA CRLF,
                                 strlen (END_DATA CRLF));
                    logMsg(LEVEL2, END_DATA NL);
                 }
                 else if (strstr (buf, UPDATE))
                 {
                   /* can be UPDATE or UPDATES */
                    FILE        *respHandle;
                    char        *multi = "", *noone = "", *ignore;

                    if (strstr (buf, UPDATES)) multi = "--multi";
                    if (ignore1) noone = "--ignore1";
                    sprintf (tmpbuf, DOUPDATE, cidalias, cidlog, multi, noone);
                    respHandle = popen (tmpbuf, "r");
                    strcat(tmpbuf, "\n");
                    logMsg(LEVEL2, tmpbuf);
                    strcpy (msgbuf, INFOLINE);
                    ptr = msgbuf + sizeof (INFOLINE) - 1;
                    cnt = sizeof (msgbuf) - sizeof (INFOLINE);
                    ignore = fgets (ptr, cnt, respHandle);
                    if (strstr(msgbuf, NOCHANGES) || strstr(msgbuf, DENIED))
                    {
                        /* There were no changes to the call log */
                        ret = write (polld[pos].fd, BEGIN_DATA CRLF,
                                     strlen (BEGIN_DATA CRLF));
                        logMsg(LEVEL2, BEGIN_DATA NL);
                        ret = write (polld[pos].fd, msgbuf, strlen (msgbuf));
                        logMsg(LEVEL2, msgbuf);
                    }
                    else
                    {
                        /* There were changes to the call log */
                        ret = write (polld[pos].fd, BEGIN_DATA1 CRLF,
                                     strlen (BEGIN_DATA1 CRLF));
                        logMsg(LEVEL2, BEGIN_DATA1 NL);
                        ret = write(polld[pos].fd, msgbuf, strlen(msgbuf));
                        logMsg(LEVEL2, msgbuf);
                        while (fgets(ptr, cnt, respHandle))
                        {
                            ret = write(polld[pos].fd, msgbuf, strlen(msgbuf));
                            logMsg(LEVEL2, msgbuf);
                        }
                    }
                    ret = write(polld[pos].fd, END_DATA CRLF,
                                strlen (END_DATA CRLF));
                    pclose (respHandle);
                    logMsg(LEVEL2, END_DATA NL);
                 }
                 else if (strstr(buf, REREAD))
                 {
                    sendLog(polld[pos].fd, buf);
                 }
                 else if (strstr(buf, ACK))
                 {
                    ack[pos] = 1;
                    sprintf(msgbuf, "(sd %d) sent %s\n", polld[pos].fd, buf);
                    logMsg(LEVEL3, msgbuf);
                    sprintf(msgbuf, "%s%s%s", ACKLINE, buf, CRLF);
                    ret = write(polld[pos].fd, msgbuf, strlen (msgbuf));
                    sprintf(msgbuf, "(sd %d) %s%s%s", polld[pos].fd, ACKLINE, buf, NL);
                    logMsg(LEVEL3, msgbuf);
                 }
                 else 
                 {
                    char *filename = "", *ptr, *type = "", multi[BUFSIZ];

                    multi[0] = '\0';
                    ptr = buf + strlen(REQLINE);
                    if (strncmp(ptr, BLK_LST , strlen(BLK_LST)) == 0)
                    {
                       filename = blacklist;
                       ptr += strlen(BLK_LST);
                       type = "Blacklist";
                    }
                    else if (strncmp(ptr, ALIAS_LST , strlen(ALIAS_LST)) == 0)
                    {
                       filename = cidalias;
                       ptr += strlen(ALIAS_LST);
                       type = "Alias";
                       if (hangup) sprintf
                           (multi, "--multi \"%s %s\"", blacklist, whitelist);
                    }
                    else if (strncmp(ptr, WHT_LST , strlen(WHT_LST)) == 0)
                    {
                       filename = whitelist;
                       ptr += strlen(WHT_LST);
                       type = "Whitelist";
                    }
                    else if (strncmp(ptr, INFO_REQ, strlen(INFO_REQ)) == 0)
                    {
                       /* found a REQ: INFO <nmbr>&&<name>&&<line> line */
                       char  name[CIDSIZE], number[CIDSIZE], line[CIDSIZE], *temp;
                       int   which;

                        /* all this in case thr REQ: line is incomplete */
                        number[0] = name[0] = line[0] = '\0';
                        if (strlen(ptr) > (strlen(INFO_REQ) + 1))
                        {
                          ptr += strlen(INFO_REQ) + 1;
                          if ((temp = strstr(ptr, "&&"))) *temp = 0;
                          strncpy (number, ptr, CIDSIZE-1);
                          number[CIDSIZE-1] = 0;
                          if (temp)
                          {
                            ptr += strlen(number) + 2;
                            if ((temp = strstr(ptr, "&&"))) *temp = 0;
                            strncpy (name, ptr, CIDSIZE-1);
                            name[CIDSIZE-1] = 0;
                          }
                          if (temp)
                          {
                            ptr += strlen(name) + 2;
                            strncpy (line, ptr, CIDSIZE-1);
                            line[CIDSIZE-1] = 0;
                          }
                        }
                        temp = findAlias(name, number, line);
                        ret = write(polld[pos].fd, BEGIN_DATA3 CRLF,
                                     strlen(BEGIN_DATA3 CRLF));
                        logMsg(LEVEL2, BEGIN_DATA3 NL);
                        sprintf(msgbuf, INFOLINE "alias %s\n", temp);
                        logMsg(LEVEL2, msgbuf);
                        sprintf(msgbuf, INFOLINE "alias %s\r\n", temp);
                        ret = write(polld[pos].fd, msgbuf, strlen(msgbuf));

                        which = onBlackWhite(name, number);
                        switch (which)
                        {
                            case 0:
                                temp = "neither";
                                break;
                            case 1:
                                temp = "black name";
                                break;
                            case 2:
                                temp = "white name";
                                break;
                            case 5:
                                temp = "black number";
                                break;
                            case 6:
                                temp = "white number";
                                break;
                            default:
                                temp = "";
                                break;
                        }
                        sprintf (msgbuf, INFOLINE "%s\r\n" END_RESP CRLF, temp);
                        ret = write (polld[pos].fd, msgbuf, strlen (msgbuf));
                        sprintf (msgbuf, INFOLINE "%s\n" END_RESP NL, temp);
                        logMsg(LEVEL2, msgbuf);

                        if (number[0] == 0 || name[0] == 0) filename = "X";
                        else filename = "Dummy";
                        *ptr = 0;
                    }
                    if (strlen (filename) < 3)
                    {
                        char *temp;

                        if ((temp = strchr(ptr, ' '))) *temp = 0;
                        sprintf (msgbuf,
                                 "Unable to handle %s request - Ignored.\n",
                                 ptr);
                        logMsg(LEVEL1, msgbuf);
                    }
                    else if (strlen (ptr) > 4)
                    {
                        FILE        *respHandle;

                        ptr++;
                        sprintf (tmpbuf, DOUTIL, multi, filename, type, ptr);
                        respHandle = popen (tmpbuf, "r");
                        strcat(tmpbuf, "\n");
                        logMsg(LEVEL2, tmpbuf);
                        ret = write (polld[pos].fd, BEGIN_DATA2 CRLF,
                                     strlen (BEGIN_DATA2 CRLF));
                        logMsg(LEVEL2, BEGIN_DATA2 NL);
                        strcpy(msgbuf, RESPLINE);
                        ptr = msgbuf + sizeof (RESPLINE) - 1;
                        cnt = sizeof (msgbuf) - sizeof (RESPLINE);
                        while (fgets (ptr, cnt, respHandle))
                        {
                            ret = write (polld[pos].fd, msgbuf, strlen (msgbuf));
                            logMsg(LEVEL2, msgbuf);
                        }
                        ret = write (polld[pos].fd, END_RESP CRLF,
                                     strlen (END_RESP CRLF));
                        pclose (respHandle);
                        logMsg(LEVEL2, END_RESP NL);
                    }
                 }
              }
              else if (strncmp (buf, WRKLINE, strlen(WRKLINE)) == 0)
              {
                /* 
                 * Found a WRK: line
                 * Perform the requested work on behalf of the client
                 */
                 strcat(strcpy(msgbuf, buf), NL);
                 logMsg(LEVEL2, msgbuf);
                 if (strncmp (buf + strlen(WRKLINE), ACPT_LOG,
                     strlen (ACPT_LOG)) == 0)
                 {
                    if (strstr (buf + strlen(WRKLINE), ACPT_LOGS)) {
                        sprintf (msgbuf,
                                 "for f in %s.*[0-9]; do mv $f.new $f; done",
                                 cidlog);
                        ret = system (msgbuf);
                        strcat(msgbuf, "\n");
                        logMsg(LEVEL2, msgbuf);
                    }
                    sprintf (msgbuf, "mv %s.new %s", cidlog, cidlog);
                    ret = system (msgbuf);
                    strcat(msgbuf, "\n");
                    logMsg(LEVEL2, msgbuf);
                 }
                 else if (strncmp (buf + strlen(WRKLINE), RJCT_LOG,
                          strlen (RJCT_LOG)) == 0)
                 {
                    if (strstr (buf + strlen(WRKLINE), RJCT_LOGS)) {
                        sprintf (msgbuf, "rm %s.*.new",cidlog);
                        ret = system (msgbuf);
                        strcat(msgbuf, "\n");
                        logMsg(LEVEL2, msgbuf);
                    }
                    sprintf (msgbuf, "rm %s.new", cidlog);
                    ret = system (msgbuf);
                    strcat(msgbuf, "\n");
                    logMsg(LEVEL2, msgbuf);
                 }
              }
              else
              {
                /*
                 * Found unknown data
                 */

                sprintf(msgbuf, "Client %d sent unknown data.\n",
                        polld[pos].fd);
                logMsg(LEVEL3, msgbuf);
                writeLog(datalog, buf);
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
 * Get or create the INFO from a MSG: or NOT:
 */
void getINFO(char *bufptr)
{
    char *ptr;

    *mesg.date = *mesg.time = '\0';
    if ((ptr = strstr(bufptr, " ###")))
    {
        getField(ptr, "DATE", mesg.date, "");
        getField(ptr, "TIME", mesg.time, "");
        getField(ptr, "NAME", mesg.name, NO_NAME);
        getField(ptr, "NMBR", mesg.nmbr, NO_NMBR);
        getField(ptr, "LINE", mesg.line, NO_LINE);
        *ptr = '\0';

    } else
    {
        /* fill in missing fields */
        strcpy(mesg.name, NO_NAME);
        strcpy(mesg.nmbr, NO_NMBR);
        strcpy(mesg.line, NO_LINE);
    }
    userAlias(mesg.nmbr, mesg.name, mesg.line);

    if (!*mesg.date || !*mesg.time)
    {
        /* no date and time, create both */
        ptr = strdate(NOSEP);
        strncpy(mesg.date, ptr, 8);
        mesg.date[8] = 0;
        strncpy(mesg.time, ptr + 9, 4);
        mesg.time[4] = 0;
    }
}

/*
 * Get a INFO field from a MSG: or NOT:
 */
void getField(char *bufptr, char *field_name, char *mesgptr, char *noval)
{
    char tmpbuf[BUFSIZ], *ptr;

    tmpbuf[BUFSIZ -1] = '\0';
    if ((ptr = strstr(bufptr, field_name)))
    {
        if (*(ptr + 5) == '*') strncpy(mesgptr, noval, CIDSIZE - 1);
        else
        {
            strncpy(tmpbuf, ptr + 5, BUFSIZ -1);
            ptr = strchr(tmpbuf, '*');
            if (ptr) *ptr = '\0';
            strncpy(mesgptr, tmpbuf, CIDSIZE - 1);
        }
    }
    else strncpy(mesgptr, noval, CIDSIZE - 1);
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

void formatCID(char *buf)
{
    char cidbuf[BUFSIZ], *ptr, *sptr, *linelabel;
    time_t t;

    /*
     * At a RING
     *
     * US systems send Caller ID between the 1st and 2nd ring
     * Some non-US systems send Caller ID before 1st ring.
     *
     * If NAME, NUMBER, or DATE and TIME is not received, provide
     * the missing information.
     *
     * If generate Caller ID set and Caller ID not received, generate
     * a generic Caller ID at RING 2.
     *
     * Clear Caller ID info between rings.
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
            sendInfo();
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
             * gencid = 1: generate a Caller ID if it is not received
             * gencid = 0: do not generate a Caller ID
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
             * CID not here yet or already processed
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
         * The Gateway creates a CID, HUP, OUT, PID Message Line
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

        /*
         * this field is only from a Gateway
         * will be either CALLIN, CALLOUT, CALLHUP, CALLBLK, CALLPID
         */
        if ((ptr = strstr(buf, CALLOUT)))
        {
             calltype = OUT; /* this is a outgoing call*/
            
        }
        else if ((ptr = strstr(buf, CALLHUP)))
        {
            calltype = HUP; /* this is a blacklisted call hangup*/
        }
        else if ((ptr = strstr(buf, CALLBLK)))
        {
            calltype = BLK; /* this is a blocked call */
        }
        else if ((ptr = strstr(buf, CALLPID)))
        {
            calltype = PID; /* this is a call from a smart phone */
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
        if ((ptr = strchr(buf, '='))) ++ptr;
        else ptr = buf + 7; /* this should never happen */
        if (*ptr == ' ') ++ptr;
        strncpy(cid.ciddate, ptr, CIDSIZE - 1);
        t = time(NULL);
        ptr = ctime(&t);
        *(ptr + 24) = 0;
        strncat(cid.ciddate, ptr + 20, CIDSIZE - strlen(cid.ciddate) - 1);
        cid.status |= CIDDATE;
        cidsent = 0;
    }
    else if (strncmp(buf, "TIME", 4) == 0)
    {
        if ((ptr = strchr(buf, '='))) ++ptr;
        else ptr = buf + 7; /* this should never happen */
        if (*ptr == ' ') ++ptr;
        strncpy(cid.cidtime, ptr, CIDSIZE - 1);
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
            if (*(ptr + 4) == '=') ptr += 5;
            else ptr += 7;
            if (*ptr == ' ') ++ptr;
            builtinAlias(cid.cidnmbr, ptr);
            cid.status |= CIDNMBR;
            cidsent = 0;
        }
        if (cidnoname)
        {
            /*
             * CIDNAME optional on some systems
             * if ncidd.conf set cidnoname then set
             * cid.cidname to NONAME to get response
             * before ring 2
             */
            cid.status |= CIDNAME;
            strncpy(cid.cidname, NONAME, CIDSIZE - 1);
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

            if (*(ptr + 4) == '=') ptr += 5;
            else ptr += 7;
            if (*ptr == ' ') ++ptr;
            builtinAlias(cid.cidname, ptr);
            cid.status |= CIDNAME;
            cidsent = 0;
        }
    }
    else if (strncmp(buf, "MESG", 4) == 0)
    {
        ptr = buf;
        if (*(ptr + 4) == '=') ptr += 5;
        else ptr += 7;
        if (*ptr == ' ') ++ptr;
        strncpy(cid.cidmesg, ptr, CIDSIZE - 1);
        cid.status |= CIDMESG;
        cidsent = 0;
    }

    if ((cid.status & CIDALL4) == CIDALL4)
    {
        /*
         * All Caller ID or outgoing call information received.
         *
         * Create the CID (Caller ID), OUT (outgoing call),
         * HUP (hungup call), or BLK (call bloackd) text line.
         *
         * For OUT text lines (outgoing calls):
         *     the MESG field is not used
         *     the NAME field will be generic if no alias
         *
         * For HUP server generated text lines (hungup call):
         *     the CID label is replaced by a HUP label
         */

        userAlias(cid.cidnmbr, cid.cidname, cid.cidline);

        switch(calltype)
        {
            case IN:
                linelabel = CIDLINE;
                break;
            case OUT:
                linelabel = OUTLINE;
                break;
            case HUP:
                linelabel = HUPLINE;
                break;
            case BLK:
                linelabel = BLKLINE;
                break;
            case PID:
                linelabel = PIDLINE;
                break;
            default: /* should not happen */
                linelabel = CIDLINE;
                break;
        }
        if (hangup)
        {
            /* hangup phone if on blacklist but not whitelist */
            if (doHangup(cid.cidname, cid.cidnmbr)) linelabel = HUPLINE;
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
        writeClients(cidbuf);

        /*
         * Reset mesg, line, and status
         * Set sent indicator
         * Reset call out indicator if it was set
         */
        strncpy(cid.cidmesg, NOMESG, CIDSIZE - 1); /* default message */
        strcpy(cid.cidline, lineid); /* default line indicator */
        strcpy(infoline, lineid); /* default line indicator */
        cid.status = 0;
        cidsent = 1;
        if (calltype) calltype = 0;
    }
}

/*
 * Send string to all TCP/IP CID clients.
 */

void writeClients(char *inbuf)
{
    int pos, ret;
    char buf[BUFSIZ];

    strcat(strcpy(buf, inbuf), CRLF);
    for (pos = 0; pos < MAXCONNECT; ++pos)
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
    char **ptr, *iptr, *optr, input[BUFSIZ], msgbuf[BUFSIZ];
    FILE *fp;
    int ret, len;

    if (stat(cidlog, &statbuf) == 0)
    {
        if ((long unsigned int) statbuf.st_size > cidlogmax)
        {
            sprintf(logbuf, LOGMSG, (long unsigned int) statbuf.st_size,
                    cidlogmax, strdate(WITHSEP), CRLF);
            ret = write(sd, logbuf, strlen(logbuf));
            sprintf(msgbuf, LOGMSG, (long unsigned int) statbuf.st_size,
                    cidlogmax, strdate(WITHSEP), NL);
            logMsg(LEVEL1, msgbuf);
            sprintf(msgbuf, "%s%s", NOLOGSENT, CRLF);
            ret = write(sd, msgbuf, strlen(msgbuf));
            return;
        }
    }

    if ((fp = fopen(cidlog, "r")) == NULL)
    {
        sprintf(msgbuf, "%s%s", NOLOG, CRLF);
        ret = write(sd, msgbuf, strlen(msgbuf));
        sprintf(msgbuf, "cidlog: %s\n", strerror(errno));
        logMsg(LEVEL4, msgbuf);
        return;
    }

    /*
     * read each line of file, one line at a time
     * add "LOG" to line tag (CID: becomes CIDLOG:)
     * send line to clients
     */
    iptr = 0;
    while (fgets(input, BUFSIZ - sizeof(LINETYPE), fp) != NULL)
    {
        /* strip <CR> and <LF> */
        if ((iptr = strchr( input, '\r')) != NULL) *iptr = 0;
        if ((iptr = strchr( input, '\n')) != NULL) *iptr = 0;

        optr = logbuf;
        iptr = input;
        if (strstr(input, ": ") != NULL)
        {
            /* possible line tag found */
            for(ptr = lineTags; *ptr; ++ptr)
            {
                if (!strncmp(input, *ptr, strlen(*ptr)))
                {
                    /* copy line tag, skip ": " */
                    for(iptr = input; *iptr != ':';) *optr++ = *iptr++;
                    iptr += 2;
                    break;
                }
            }
        }
        /*
         * if line "<label>: " found, line begins with "<label>LOG: "
         * if line label not found, line begins with "LOG: "
         */
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
        sprintf(msgbuf, "Sent call log: %s\n", cidlog);
        logMsg(LEVEL3, msgbuf);
    }
    else
    {
        sprintf(msgbuf, "%s%s", EMPTYLOG, CRLF);
        ret = write(sd, msgbuf, strlen(msgbuf));
        sprintf(msgbuf, "Call log empty: %s\n", cidlog);
        logMsg(LEVEL3, msgbuf);
    }
}

/*
 * Write log, if logfile exists.
 */

void writeLog(char *logf, char *logbuf)
{
    int logfd, ret;
    char msgbuf[BUFSIZ];

    /* write to server log */
    sprintf(msgbuf, "%s\n", logbuf);
    logMsg(LEVEL3, msgbuf);

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
    }
}

/*
 * Send call information
 *
 * Format of CIDINFO line passed to TCP/IP clients by ncidd:
 *
 * CIDINFO: *LINE*<label>*RING*<number>*TIME<hh:rr:mm>
 */

void sendInfo()
{
    char buf[BUFSIZ];

    userAlias("", "", infoline);
    sprintf(buf, "%s%s%s%s%d%s%s%s",CIDINFO, LINE, infoline, \
            RING, ring, TIME, strdate(ONLYTIME), STAR);
    writeClients(buf);

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
                tm->tm_sec, (long int) tv.tv_usec / 100);
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
    for (pos = 0; pos < MAXCONNECT; ++pos)
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

/*
 * reload signal SIGHUP
 *
 * reload alias file
 * reload blacklist and whitelist files if hangup option given
 */
void reload(int sig)
{
    char msgbuf[BUFSIZ];

    sprintf(msgbuf,
      "Received Signal %d: %s\nReloading alias%s: %s\n", sig,
      strsignal(sig), hangup ? ", blacklist, and whitelist files" : " file",
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

    /* reload alias file, but quit on error */
    if (doAlias()) errorExit(-109, 0, 0);

    if (hangup)
    {
        /* remove existing blacklist entries to free memory used */
        rmEntries(blklist);

        /* remove existing whitelist entries to free memory used */
        rmEntries(whtlist);

    /* reload blacklist and whitelist files but quit on error */
    if (doList(blacklist, blklist) || doList(whitelist, whtlist))
         errorExit(-114, 0, 0);
    }
}

/*
 * new CID call log signal
 *
 * replace cidcall.log file with cidcall.log.new
 */
void update_cidcall_log (int sig)
{
    char msgbuf[BUFSIZ];

    sprintf (msgbuf,
      "Received Signal %d: %s\nReplacing %s with %s.new: %s\n", sig,
      strsignal(sig), cidlog, cidlog, strdate(WITHSEP));
    logMsg(LEVEL1, msgbuf);
    /*
     * can't replace log file now because it may be in the process of
     * being written to.  Set the flag value so that it can be updated
     * when it is safe to do so.
     */
    update_call_log = 1;
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

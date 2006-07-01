/*
 * ncidd - Network Caller ID Daemon
 *
 * Copyright (c) 2002, 2003, 2004, 2005, 2006
 * by John L. Chmielewski <jlc@users.sourceforge.net>
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
char *version = VERSION;
char *logfile = LOGFILE;
char *lockfile, *name;
char *TTYspeed;
int ttyspeed = TTYSPEED;
int port = PORT;
int debug, conferr, setcid, locked, sendlog, sendinfo;
int ttyfd, pollpos, pollevents;
int ring, ringwait, ringcount, clocal, nomodem, noserial;
int verbose = 1;

struct pollfd polld[CONNECTIONS + 2];
static struct termios otty, ntty;
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

void exit(), finish(), free();
char *strdate();

main(int argc, char *argv[])
{
    int events, mainsock, sd, argind, i;
    char *ptr;
    struct stat statbuf;
    char msgbuf[BUFSIZ];

    signal(SIGHUP, finish);
    signal(SIGTERM, finish);
    signal(SIGINT, finish);
    signal(SIGQUIT, finish);

    /* global containing name of program */
    name = strrchr(argv[0], (int) '/');
    name = name ? name + 1 : argv[0];

    /* process options from the command line */
    argind = getOptions(argc, argv);

    /* open or create logfile */
    if ((logptr = fopen(logfile, "a")) == NULL)
    {
        sprintf(msgbuf, "%s: %s\n", logfile, strerror(errno));
        logMsg(LEVEL1, msgbuf);
    }

    sprintf(msgbuf, "Started: %s\nServer: %s %s\n",strdate(), name, version);
    logMsg(LEVEL1, msgbuf);

    sprintf(msgbuf, "ncidd logfile: %s\n", logfile);
    logMsg(LEVEL2, msgbuf);

    /*
     * read config file, if present, exit on any errors
     * do not override any options set on the command line
     */
    if (doConf()) errorExit(-104, 0, 0);

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

    if (alias[0].type)
    {
        sprintf(msgbuf,
            "Printing alias structure: ELEMENT TYPE [FROM] [TO] [DEPEND]\n");
        logMsg(LEVEL5, msgbuf);
    }
    for (i = 0; i < ALIASSIZE && alias[i].type; ++i)
    {
        sprintf(msgbuf, " %.2d %.2d [%-21s] [%-21s] [%-21s]\n", i,
            alias[i].type,
            alias[i].from,
            alias[i].to,
            alias[i].depend ? alias[i].depend : " ");
        logMsg(LEVEL5, msgbuf);
    }

    sprintf(msgbuf, "Verbose level: %d\n", verbose);
    logMsg(LEVEL1, msgbuf);
    sprintf(msgbuf, "CID logfile: %s\n", cidlog);
    logMsg(LEVEL2, msgbuf);
    sprintf(msgbuf, "Data logfile: %s\n", datalog);
    logMsg(LEVEL2, msgbuf);

    /*
     * noserial = 1: serial port not used
     * noserial = 0: serial port used for Caller ID
     */

    if (!noserial)
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
            if (ptr = strrchr(ttyport, '/')) ptr++;
            else ptr = ttyport;

            if (lockfile = (char *) malloc(strlen(LOCKFILE) + strlen(ptr) + 1))
                strcat(strcpy(lockfile, LOCKFILE), ptr);
            else errorExit(-1, name, 0);
        }

        /* check TTY port lock file */
        if (stat(lockfile, &statbuf) == 0)
            errorExit(-102, "Exiting - TTY port in use (lockfile exists)",
                  lockfile);

        /*
        * Open tty port; tries to make sure the open does
        * not hang if port in use, or not restored after use
        */
        if ((ttyfd = open(ttyport, O_RDWR | O_NOCTTY | O_NDELAY)) < 0)
            errorExit(-1, ttyport, 0);
        if (fcntl(ttyfd, F_SETFL, fcntl(ttyfd, F_GETFL, 0) & ~O_NDELAY) < 0)
            errorExit(-1, ttyport, 0);

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
        logMsg(LEVEL2, msgbuf);
        sprintf(msgbuf, "TTY port speed: %s\n", TTYspeed);
        logMsg(LEVEL2, msgbuf);
        sprintf(msgbuf, "TTY lock file: %s\n", lockfile);
        logMsg(LEVEL2, msgbuf);
        sprintf(msgbuf, "TTY port control signals %s\n",
            clocal ? "disabled" : "enabled");
        logMsg(LEVEL2, msgbuf);

        if (nomodem)
        {
            sprintf(msgbuf, "CallerID from CID device, not AT modem\n");
            logMsg(LEVEL1, msgbuf);
        }

        /* Save tty port settings */
        if (tcgetattr(ttyfd, &otty) < 0) return -1;

        /* initialize tty port */
        if (doTTY() < 0) errorExit(-1, ttyport, 0);
    }
    else
    {
        sprintf(msgbuf, "CallerID from CID client(s) only\n");
        logMsg(LEVEL1, msgbuf);
    }

    if (!debug)
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

    if (!noserial) pollpos = addPoll(ttyfd);

    /* initialize server socket */
    if ((mainsock = tcpOpen(port)) < 0) errorExit(-1, "socket", 0);

    addPoll(mainsock);

    /* Read and display data */
    while (1)
    {
        switch (events = poll(polld, CONNECTIONS + 2, TIMEOUT))
        {
            case -1:    /* error */
                errorExit(-1, "poll", 0);
            case 0:        /* time out, without an event */
                /* end of ringing */
                if (ring > 0)
                {
                    if (ringwait < RINGWAIT) ++ringwait;
                    else
                    {
                        if (ringcount == ring)
                        {
                            ring = ringcount = ringwait = 0;
                            sendInfo(mainsock);
                        }
                        else
                        {
                            ringwait = 0;
                            ringcount = ring;
                        }
                    }
                }
                /* if no serial port, skip TTY code */
                if (!noserial)
                {
                    /* TTY port lockfile */
                    if (stat(lockfile, &statbuf) == 0)
                    {
                        if (!locked)
                        {
                            /* save TTY events */
                            pollevents = polld[pollpos].events;
                            /* remove TTY poll events */
                            polld[pollpos].events = polld[pollpos].revents = 0;
                            polld[pollpos].fd = 0;
                            sprintf(msgbuf, "TTY in use: releasing modem %s\n",
                                strdate());
                            logMsg(LEVEL1, msgbuf);
                            locked = 1;
                        }
                    }
                    else if (locked)
                    {
                        sprintf(msgbuf, "TTY free: using modem again %s\n",
                            strdate());
                        logMsg(LEVEL1, msgbuf);
                        tcflush(ttyfd, TCIOFLUSH);
                        if (doTTY() < 0)
                        {
                            sprintf(msgbuf,
                                "%sCannot init TTY, Terminated %s\n",
                                MSGLINE, strdate());
                            writeClients(mainsock, msgbuf);
                            strcat(msgbuf, NL);
                            logMsg(LEVEL1, msgbuf + strlen(MSGLINE));
                            tcsetattr(ttyfd, TCSANOW, &otty);
                            cleanup();
                            exit(-1);
                        }
                        locked = 0;
                        /* restore tty poll events */
                        polld[pollpos].fd = ttyfd;
                        polld[pollpos].events = pollevents;
                    }
                }
                break;
            default:    /* 1 or more events reported */
                doPoll(events, mainsock);
                break;
        }
    }
}

int getOptions(int argc, char *argv[])
{
    int c, num;
    int digit_optind = 0;
    int option_index = 0;
    static struct option long_options[] = {
        {"alias", 1, 0, 'A'},
        {"config", 1, 0, 'C'},
        {"cidlog", 1, 0, 'c'},
        {"datalog", 1, 0, 'd'},
        {"debug", 0, 0, 'D'},
        {"help", 0, 0, 'h'},
        {"initcid", 1, 0, 'i'},
        {"initstr", 1, 0, 'I'},
        {"lockfile", 1, 0, 'l'},
        {"logfile", 1, 0, 'L'},
        {"nomodem", 1, 0, 'n'},
        {"noserial", 1, 0, 'N'},
        {"port", 1, 0, 'p'},
        {"send", 1, 0, 's'},
        {"ttyspeed", 1, 0, 'S'},
        {"ttyclocal", 1, 0, 'T'},
        {"ttyport", 1, 0, 't'},
        {"verbose", 1, 0, 'v'},
        {"version", 0, 0, 'V'},
        {0, 0, 0, 0}
    };

    while ((c = getopt_long (argc, argv, "c:d:hi:l:n:p:s:t:v:A:C:DI:L:N:S:T:V",
        long_options, &option_index)) != -1)
    {
        switch (c)
        {
            case 'A':
                if (!(cidalias = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("cidalias")) >= 0) setword[num].type = 0;
                break;
            case 'C':
                if (!(cidconf = strdup(optarg))) errorExit(-1, name, 0);
                break;
            case 'D':
                debug = 1;
                break;
            case 'I':
                if (!(initstr = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("initstr")) >= 0) setword[num].type = 0;
                break;
            case 'L':
                if (!(logfile = strdup(optarg))) errorExit(-1, name, 0);
                break;
            case 'N':
                noserial = atoi(optarg);
                if (strlen(optarg) != 1 ||
                    (!(noserial == 0 && *optarg == '0') && noserial != 1))
                    errorExit(-107, "Invalid number", optarg);
                if ((num = findWord("noserial")) >= 0) setword[num].type = 0;
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
                fprintf(stderr, SHOWVER, name, version);
                exit(0);
            case 'c':
                if (!(cidlog = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("cidlog")) >= 0) setword[num].type = 0;
                break;
            case 'd':
                if (!(datalog = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("datalog")) >= 0) setword[num].type = 0;
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
                if ((num = findWord("tty")) >= 0) setword[num].type = 0;
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
                exit(-100);
        }
    }
    return optind;
}

int doTTY()
{
    char msgbuf[BUFSIZ];

    /* Setup tty port in raw mode */
    if (tcgetattr(ttyfd, &ntty) <0) return -1;
    ntty.c_lflag     &= ~(ICANON | ECHO | ECHOE | ISIG);
    ntty.c_oflag     &= ~OPOST;
    ntty.c_iflag = (IGNBRK | IGNPAR);
    ntty.c_cflag = (ttyspeed | CS8 | CREAD | HUPCL | CRTSCTS);
    if (clocal) ntty.c_cflag |= CLOCAL;
    ntty.c_cc[VEOL] = '\r';
    ntty.c_cc[VMIN]  = 0;
    ntty.c_cc[VTIME] = CHARWAIT;
    if (tcflush(ttyfd, TCIOFLUSH) < 0) return -1;
    if (tcsetattr(ttyfd, TCSANOW, &ntty) < 0) return -1;

    if (!nomodem)
    {
        /* initialize modem for CID */
        if (doModem() < 0) errorExit(-1, ttyport, 0);
    }

    /* take tty port out of raw mode */
    ntty.c_lflag = (ICANON);
    if (tcsetattr(ttyfd, TCSANOW, &ntty) < 0) return -1;

    if (nomodem) sprintf(msgbuf, "CallerID TTY port initialized.\n");
    else sprintf(msgbuf, "Modem set for CallerID.\n");
    logMsg(LEVEL1, msgbuf);

    return 0;
}

int doModem()
{
    int cnt, ret = 2;
    char msgbuf[BUFSIZ];

    /*
     * Try to initialize modem, sometimes the modem
     * fails to respond the 1st time, so try multiple
     * times on a no response return code, before
     * indicating no modem.
     */
    for (cnt = 0; ret == 2 && cnt < MODEMTRY; ++cnt)
    {
        if ((ret = initModem(initstr)) < 0) return -1;
        sprintf(msgbuf, "Try %d to init modem: return = %d.\n", cnt + 1, ret);
        logMsg(LEVEL3, msgbuf);
    }

    if (ret)
    {
        tcsetattr(ttyfd, TCSANOW, &otty);
        if (ret == 1) errorExit(-103, "Unable to initialize modem", ttyport);
        else errorExit(-105, "No modem found", ttyport);
    }

    sprintf(msgbuf, "Modem initialized.\n");
    logMsg(LEVEL1, msgbuf);

    /* Initialize CID */
    if ((ret = initModem(initcid)) < 0) return -1;
    if (ret)
    {
        if (!setcid)
        {
            if (!(initcid = strdup(INITCID2))) errorExit(-1, name, 0);
            if ((ret = initModem(initcid)) < 0) return -1;
        }

        if (ret)
        {
            tcsetattr(ttyfd, TCSANOW, &otty);
            errorExit(-103, "Unable to set modem CallerID", ttyport);
        }
    }

    return 0;
}

int initModem(char *ptr)
{
    int num = 0, size = 0;
    int try;
    char buf[BUFSIZ], *bufp;
    char msgbuf[BUFSIZ];

    /* send string to modem */
    strcat(strncpy(buf, ptr, BUFSIZ - 2), CR);
    if (write(ttyfd, buf, strlen(buf)) < 0) return -1;

    /* delay until response detected or number of tries exceeded */
    for (try = 0; try < INITTRY; try++)
    {
        if ((num = read(ttyfd, buf + size, BUFSIZ - size - 1)) < 0) return -1;
        if (num) break;
        usleep(INITWAIT);
    }

    /* get rest of response */
    while (num)
    {
        size += num;
        if ((num = read(ttyfd, buf + size, BUFSIZ - size - 1)) < 0) return -1;
    }
    buf[size] = 0;

    /* Remove CRLF at end of string */
    if (buf[size - 1] == '\n' || buf[size - 1] == '\r') buf[size - 1] = '\0';
    if (buf[size - 2] == '\r' || buf[size - 2] == '\n') buf[size - 2] = '\0';

    if (size)
    {
        sprintf(msgbuf, "%s\n", buf);
        logMsg(LEVEL3, msgbuf);
    }
    else
    {
        sprintf(msgbuf, "No Modem Response\n");
        logMsg(LEVEL3, msgbuf);
    }

    /* check response */
    if ((bufp = strrchr(buf, 'O')) != 0)
        if (!strncmp(bufp, "OK", 2)) return 0;
    if ((bufp = strrchr(buf, 'E')) != 0)
        if (!strncmp(bufp, "ERROR", 5)) return 1;

    /* no response, or other response */
    return 2;
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
    if ((sd = socket(PF_INET, SOCK_STREAM,0)) < 0)
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
    struct  sockaddr bind_addr;
    unsigned int socksize = sizeof(bind_addr);

    return accept(sock, &bind_addr, &socksize);
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

doPoll(int events, int mainsock)
{
  int num, pos, sd, cnt = 0;
  char buf[BUFSIZ], msgbuf[BUFSIZ];;

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
    logMsg(LEVEL4, msgbuf);

    if (polld[pos].revents & POLLHUP) /* Hung up */
    {
      if (!noserial && polld[pos].fd == ttyfd)
      {
        sprintf(buf, "%sDevice Hung Up, Terminated  %s\n",
          MSGLINE, strdate());
        writeClients(mainsock, buf);
        strcat(buf, NL);
        logMsg(LEVEL1, buf + strlen(MSGLINE));
        cleanup();
        exit(-1);
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
        sprintf(buf, "%sDevice Error, Terminated  %s\n",
          MSGLINE, strdate());
        writeClients(mainsock, buf);
        strcat(buf, NL);
        logMsg(LEVEL1, buf + strlen(MSGLINE));
        cleanup();
        exit(-1);
      }
        sprintf(msgbuf, "Poll Error, sd: %d\n", polld[pos].fd);
        logMsg(LEVEL1, msgbuf);
    }

    if (polld[pos].revents & POLLNVAL) /* Invalid Request */
    {
      sprintf(msgbuf, "Invalid Request: File descriptor not open, sd: %d\n",
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
            sprintf(msgbuf, "READ: %s\n", strerror(errno));
            logMsg(LEVEL1, msgbuf);
          }

          /* Modem or device returned no data */
          else if (!num)
          {
            sprintf(msgbuf, "Device returned no data, fd: %d\n", ttyfd);
            logMsg(LEVEL2, msgbuf);
            cnt++;

            /* if no data 10 times in a row, something wrong */
            if (cnt == 10)
            {
              sprintf(buf, "%sDevice returns no data, Terminated  %s\n",
                MSGLINE, strdate());
              writeClients(mainsock, buf);
              strcat(buf, NL);
              logMsg(LEVEL1, buf + strlen(MSGLINE));
              cleanup();
              exit(-1);
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
            if (ptr = strchr(buf, '\r')) *ptr = '\0';
            if (ptr = strchr(buf, '\n')) *ptr = '\0';

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
            strcat(strcat(strcpy(buf, ANNOUNCE), VERSION), CRLF);
            write(sd, buf, strlen(buf));
            if (addPoll(sd) < 0)
            {
              sprintf(msgbuf, "%s\n", TOOMSG);
              logMsg(LEVEL1, msgbuf);
              sprintf(buf, "%s: %d%s", TOOMSG, CONNECTIONS, CRLF);
              write(sd, buf, strlen(buf));
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
              sprintf(msgbuf, "Client Connected, sd: %d\n", sd);
              logMsg(LEVEL3, msgbuf);
            }
          }
        }
      }
      else
      {
        if (polld[pos].fd)
        {
          strcpy(buf, MSGLINE);
          if ((num = read(polld[pos].fd, buf + strlen(MSGLINE), BUFSIZ-1)) < 0)
          {
            sprintf(msgbuf, "Client READ: %s\n", strerror(errno));
            logMsg(LEVEL1, msgbuf);
          }
          /* read will return 0 for a disconnect */
          if (num == 0)
          {
            /* TCP/IP Client End Connection */
            sprintf(msgbuf, "Client disconnected, sd: %d\n", polld[pos].fd);
              logMsg(LEVEL3, msgbuf);
            close(polld[pos].fd);
            polld[pos].fd = polld[pos].events = 0;
          }
          else
          {
            /*
             * Client sent message to server
             */

            char *ptr;

            /* Terminate String */
            buf[num + strlen(MSGLINE)] = '\0';

            /* strip <CR> and <LF> */
            if (ptr = strchr(buf, '\r')) *ptr = '\0';
            if (ptr = strchr(buf, '\n')) *ptr = '\0';

            /*
             * Check first character is a 7-bit unsigned char value
             * if not, assume entire line is not wanted.  This may
             * need to be improved, but this gets rid of telnet binary.
             */
             if (isascii((int) buf[strlen(MSGLINE)]) == 0)
             {
                buf[strlen(MSGLINE)] = '\0';
                sprintf(msgbuf, "Message deleted, not 7-bit ASCII, sd: %d\n",
                  polld[pos].fd);
                logMsg(LEVEL3, msgbuf);
             }

            /* Make sure there is data in the message line */
            if (strncmp(buf, MSGLINE, strlen(buf)) != 0)
            {

              sprintf(msgbuf, "%s%s###", MSGLINE, CIDLINE);
              if (strncmp(buf, msgbuf, strlen(msgbuf)) == 0)
              {
                /*
                 * Found a CID Message Line
                 * See comments for formatCID for line format
                 */

                sprintf(msgbuf, "Client sent CID message, sd: %d\n",
                  polld[pos].fd);
                logMsg(LEVEL3, msgbuf);

                writeLog(datalog, buf);
                formatCID(mainsock, buf + strlen(MSGLINE) + strlen(CIDLINE));
              }
              else
              {
                sprintf(msgbuf, "%s%s###", MSGLINE, CIDINFO);
                if (strncmp(buf, msgbuf, strlen(msgbuf)) == 0)
                {
                  /*
                   * Found a CIDINFO MSG Line
                   *
                   * CIDINFO Message Line Format:
                   * CIDINFO: ###CANCEL
                   */

                  sprintf(msgbuf, "Client sent CIDINFO message, sd: %d\n",
                    polld[pos].fd);
                  logMsg(LEVEL3, msgbuf);

                  writeLog(datalog, buf);
                  if (strstr(buf, "CANCEL"))
                  {
                    ring = -1;
                    sendInfo(mainsock);
                    ring = 0;
                  }
                }
                else
                {
                  /* Write message to cidlog and all clients */

                  sprintf(msgbuf, "Client sent text message, sd: %d\n",
                    polld[pos].fd);
                  logMsg(LEVEL3, msgbuf);
                  writeLog(cidlog, buf);
                  writeClients(mainsock, buf);
                }
              }
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
 * CID Message Line Format:
 *
 * ###DATEmmddhhss...LINEidentifier...NMBRnumber...NAMEwords+++\r
 */

formatCID(int mainsock, char *buf)
{
    char cidbuf[BUFSIZ], *ptr, *sptr;
    time_t t;

    /*
     * All Caller ID information is between the 1st and 2nd ring
     * if RING is indicated, clear any Caller ID info received,
     * unless NAME is the only thing missing.
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
            /* ring == -1 means SIP CANCEL */
            if (ring < -1) ring = 0;
            ++ring;
            sendInfo(mainsock);
        }

        if ((cid.status & CIDALL3) == CIDALL3)
        {
            /*
            * date, time, and number were received
            * indicate No NAME, and process anyway
            */
            strncpy(cid.cidname, NONAME, CIDSIZE - 1);
            cid.status |= CIDNAME;
        }
        else if ((cid.status & CIDALT3) == CIDALT3)
        {
            /*
            * date, time, and name were received
            * indicate No Number, and process anyway
            */
            strncpy(cid.cidnmbr, NONUMB, CIDSIZE - 1);
            cid.status |= CIDNMBR;
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
     if (ptr = strstr(buf, "\020R\020X"))
     {
        cid.status = 0;
     }

    /*
     * sometimes bad charactors are received....
     * replace unprintable charachers with a '?'
     */
    for (ptr = buf; *ptr; ptr++) if (!isprint(*ptr)) *ptr = '?';

    /* Process Caller ID information */
    if (strncmp(buf, "###", 3) == 0)
    {
        /*
         * Found a NetCallerID box, or a CID Message Line
         * All information on one line
         * The CID Message LINE has a LINE field
         * The NetCallerID box does not have a LINE field
         */

        /* Make sure the status field is zero */
        cid.status = 0;

        if (ptr = strstr(buf, "DATE"))
        {
            /*
             * Found a message line, format it, log it, and send it:
             *    MSG: message
             */
            if (*(ptr + 4) == '.')
            {
                if (ptr = strstr(buf, "NAME"))
                {
                    strncat(strcpy(cidbuf, MSGLINE), ptr + 4, BUFSIZ -1);
                    if (ptr = strchr(cidbuf, '+')) *ptr = 0;
                    writeLog(cidlog, cidbuf);
                    writeClients(mainsock, cidbuf);
                    cid.status = 0;
                    return;
                }
            }

            strncpy(cid.cidtime, ptr + 8, 4);
            cid.cidtime[4] = 0;
            cid.status |= CIDTIME;
            strncpy(cid.ciddate, ptr + 4, 4);
            cid.ciddate[4] = 0;
            t = time(NULL);
            ptr = ctime(&t);
            *(ptr + 24) = 0;
            strncat(cid.ciddate, ptr + 20, CIDSIZE - strlen(cid.ciddate) - 1);
            cid.status |= CIDDATE;
        }
        if (ptr = strstr(buf, "LINE"))
        {
            /* this field is only in a CID Message Line */
            if (*(ptr + 5) == '.') strncpy(cid.cidline, ONELINE, CIDSIZE - 1);
            else
            {
                strncpy(cid.cidline, ptr + 4, CIDSIZE -1);
                ptr = strchr(cid.cidline, '.');
                if (ptr) *ptr = 0;
            }
        }
        if (ptr = strstr(buf, "NMBR"))
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
        if (ptr = strstr(buf, "NAME"))
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
    }
    else if (strncmp(buf, "TIME", 4) == 0)
    {
        strncpy(cid.cidtime, buf[4] == '=' ? buf + 5 : buf + 7, CIDSIZE - 1);
        cid.status |= CIDTIME;
    }
    else if (strncmp(buf, "NMBR", 4) == 0)
    {
        /* some systems send NMBR = ##########, then NMBR = O to mask it */
        if (!(cid.status & CIDNMBR))
        {
            builtinAlias(cid.cidnmbr, buf[4] == '=' ? buf + 5 : buf + 7);
            cid.status |= CIDNMBR;
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
        }
    }
    else if (strncmp(buf, "MESG", 4) == 0)
    {
        strncpy(cid.cidmesg, buf[4] == '=' ? buf + 5 : buf + 7, CIDSIZE - 1);
        cid.status |= CIDMESG;

        /* some systems send MESG instead of NAME, set NONAME */
        strncpy(cid.cidname, NONAME, CIDSIZE - 1);
        cid.status |= CIDNAME;
    }

    if ((cid.status & CIDALL4) == CIDALL4)
    {
        /*
         * All Caller ID information received.
         * Send Caller ID Information to clients.
         */
        userAlias(cid.cidnmbr, cid.cidname, cid.cidline);
        sprintf(cidbuf, "%s%s%s%s%s%s%s%s%s%s%s%s%s%s",
            CIDLINE,
            DATE, cid.ciddate,
            TIME, cid.cidtime,
            LINE, cid.cidline,
            NMBR, cid.cidnmbr,
            MESG, cid.cidmesg,
            NAME, cid.cidname,
            STAR);
        writeLog(cidlog, cidbuf);
        writeClients(mainsock, cidbuf);

        /* Reset status, mesg, and line. */
        cid.status = 0;
        strncpy(cid.cidmesg, NOMESG, CIDSIZE - 1);
        strcpy(cid.cidline, ONELINE); /* default line */
    }
}

/*
 * Built-in Aliases for O, P, and A
 */

builtinAlias(char *to, char *from)
{
    if (!strcmp(from, "O")) strncpy(to, O, CIDSIZE - 1);
    else if (!strcmp(from, "P")) strncpy(to, P, CIDSIZE - 1);
    else if (!strcmp(from, "A")) strncpy(to, A, CIDSIZE - 1);
    else strncpy(to, from, CIDSIZE - 1);
}

/*
 * User defined aliases.
 */

userAlias(char *nmbr, char *name, char *line)
{
    int i;

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
                if (!strcmp(line, alias[i].from)) strcpy(line, alias[i].to);
                break;
        }
    }
}

/*
 * Send string to all TCP/IP CID clients.
 */

writeClients(int mainsock, char *buf)
{
    int pos;
    char *ptr;

    for (pos = 0; pos < CONNECTIONS + 2; ++pos)
    {
        if (polld[pos].fd == 0 || polld[pos].fd == ttyfd ||
            polld[pos].fd == mainsock)
            continue;
        write(polld[pos].fd, buf, strlen(buf));
        write(polld[pos].fd, CRLF, strlen(CRLF));
    }
}

/*
 * Send log, if log file exists.
 */

sendLog(int sd, char *logbuf)
{
    struct stat statbuf;
    char *iptr, *optr, input[BUFSIZ], msgbuf[BUFSIZ];
    FILE *fp;
    int ret;

    if (stat(cidlog, &statbuf) == 0)
    {
        if (statbuf.st_size > LOGMAX)
        {
            sprintf(logbuf, LOGMSG, statbuf.st_size, LOGMAX, CRLF);
            write(sd, logbuf, strlen(logbuf));
            sprintf(msgbuf, LOGMSG, statbuf.st_size, LOGMAX, NL);
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
        if ((ret = write(sd, logbuf, strlen(logbuf))) == -1)
        {
            while (ret == -1 && errno == EAGAIN)
                ret = write(sd, logbuf, strlen(logbuf));

            if (ret == -1 && errno != EAGAIN)
            {
                sprintf(msgbuf, "sending log: %d %s\n", errno, strerror(errno));
                logMsg(LEVEL1, msgbuf);
            }
        }
    }

    (void) fclose(fp);

    sprintf(msgbuf, "Client connected, sd: %d, Sent call log: %s\n",
        sd, cidlog);
    logMsg(LEVEL3, msgbuf);
}

/*
 * Write log, if log file exists.
 */

writeLog(char *logf, char *logbuf)
{
    int logfd;
    char msgbuf[BUFSIZ];

    if ((logfd = open(logf, O_WRONLY | O_APPEND)) < 0)
    {
        sprintf(msgbuf, "%s: %s\n", logf, strerror(errno));
        logMsg(LEVEL4, msgbuf);
    }
    else
    {
        write(logfd, logbuf, strlen(logbuf));
        write(logfd, NL, strlen(NL));
        close(logfd);

        /* log to server log, if not blank */
        if (*logbuf)
        {
            sprintf(msgbuf, "%s\n", logbuf);
            logMsg(LEVEL3, msgbuf);
        }
    }
}

/*
 * Send call information
 *
 * Format of CIDINFO line passed to TCP/IP clients by ncidd:
 *
 * CIDINFO: *LINE*-*RING*1*
 */

sendInfo(int mainsock)
{
    char buf[BUFSIZ], *ptr;

    sprintf(buf, "%s%s%s%s%d%s%s", CIDINFO,
            LINE, cid.cidline,
            RING, ring,
            STAR, CRLF);
    writeClients(mainsock, buf);

    /* strip <CR> */
    if (ptr = strchr(buf, '\r'))
    {
        *ptr++ = '\n';
        *ptr = '\0';
    }
    logMsg(LEVEL3, buf);
}

/*
 * Returns the current date and time as a string in the format:
 *      MM/DD/YYYY HH:MM
 */
char *strdate()
{
    static char buf[BUFSIZ];
    struct tm *tm;
    struct timeval tv;

    (void) gettimeofday(&tv, 0);
    tm = localtime(&(tv.tv_sec));
    sprintf(buf, "%.2d/%.2d/%.4d %.2d:%.2d", tm->tm_mon + 1, tm->tm_mday,
        tm->tm_year + 1900, tm->tm_hour, tm->tm_min);
    return buf;
}

/*
 * Close all file descriptors and restore tty parameters.
 */

cleanup()
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

    sprintf(msgbuf, "Terminated: %s\n", strdate());
    logMsg(LEVEL1, msgbuf);
    cleanup();
    exit(0);
}

errorExit(int error, char *msg, char *arg)
{
    char msgbuf[BUFSIZ];

    if (error == -1)
    {
        /* system error */
        error = errno;
        sprintf(msgbuf, "%s: %s\n", msg, strerror(errno));
        logMsg(LEVEL1, msgbuf);
    }
    else if (msg != 0)
    {
        /* internal program error */
        sprintf(msgbuf, "%s: %s\n", msg, arg);
        logMsg(LEVEL1, msgbuf);
    }

    /* do not print terminated message if option error */
    if (error != -108 && error != -107 && error != -101 && error != 106 &&
        error != 100)
    {
        sprintf(msgbuf, "Terminated:  %s\n", strdate());
        logMsg(LEVEL1, msgbuf);
    }

    cleanup();
    exit(error);
}

/*
 * The printing of messages needs to be improved.
 */
logMsg(int level, char *message)
{
    /* write to stderr in debug mode */
    if (debug && verbose >= level) fputs(message, stderr);

    /* write to logfile */
    if (logptr && verbose >= level)
    {
        fputs(message, logptr);
        fflush(logptr);
    }
}

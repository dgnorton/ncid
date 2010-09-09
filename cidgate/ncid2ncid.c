/*
 * ncid2ncid - NCID server to NCID server gateway
 *
 * Copyright 2010
 *  by John L. Chmielewski <jlc@users.sourceforge.net>
 *
 * ncid2ncid is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * ncid2ncid is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 */

#include "ncid2ncid.h"

/* globals */
int debug, warn;
int verbose   = 1;
char *name, *pidfile;
char *logfile  = LOGFILE;
pid_t pid;
FILE *logptr;
struct sigaction sigact;
struct pollfd polld[SERVERS];

int conferr;
char *config = CONFIG;

int doPID(), getOptions(), addPoll(), socketConnect();
void cleanup(), errorExit(), logMsg(), sigdetect();
char *strdate(), *inet_ntoa(), *strmatch();

void perror();
char *getWord();
int findWord(), doConf(), doSet(), configError();

#ifndef __CYGWIN__
    extern char *strsignal();
#endif

/*
 * tohost and a number of fromhost? are added when gateway starts up
 * the size of SERVERS determins the number of fromhost?
 *    tohost = setword[2]
 *    toport = setword[3]
 *    fromhost1 = setword[4]
 *    fromport1 = setword[5]
 *    etc
 */
struct setword setword[SERVERS * 2 + 4] =
{
    /* *word       type      **buf     *value  min         max */
   {"pidfile",    WORDSTR,  &pidfile, 0,        0,         0},
   {"verbose",    WORDNUM,  0,        &verbose, 1,         MAXLEVEL},
   {"warn",       WORDNUM,  0,        &warn,    OFF,       ON}
};

/*
 * a number of fromhost? are added when gateway starts up
 * the size of SERVERS determins the number of fromhost?
 *    tohost = ns[0]
 *    fromhost1 = ns[1]
 *    fromhost2 = ns[2]
 *    etc
 */
struct server ns[SERVERS] =
{
   /* *name   *host  port sd */
    {"tohost", HOST, PORT, 0}
};

char *lineType[] = {"CID: ", "CIDINFO: ", "MSG: ", ""};

int main(int argc, char *argv[])
{
    int    argind, events, pos, i, ret, errnum;
    int    sd = 0, tosd = 0, fromsd1 = 0, fromsd2 = 0, fromsd3 = 0;
    char   msgbuf[BUFSIZ], rcvbuf[BUFSIZ], tmp[100], *ptr;
    struct stat statbuf;

    /* global containing name of program */
    name = strrchr(argv[0], (int) '/');
    name = name ? name + 1 : argv[0];

    /* initialize ns[] */
    for(i = 1; i < SERVERS; ++i)
    {
        ns[i].port = PORT;
        sprintf(tmp, "fromhost%d", i);
        if (!(ns[i].name = strdup(tmp))) errorExit(-1, name, 0);
    }

    /* initialize setword[] */
    for(pos = 0, i = 3; pos < SERVERS; ++pos)
    {
        setword[i].word = ns[pos].name;
        setword[i].type = WORDSTR;
        setword[i++].buf = &ns[pos].host;
        sprintf(tmp, "fromport%d", pos);
        setword[i].type = WORDNUM;
        if (!(setword[i].word = strdup(tmp))) errorExit(-1, name, 0);
        setword[i++].value = &ns[pos].port;
    }

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

    sprintf(msgbuf, "Started: %s\nGateway: %s %s\n",strdate(WITHYEAR),
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

    /*
     * read config file, if present, exit on any errors
     * do not override any options set on the command line
     */
    if (doConf()) errorExit(-104, 0, 0);

    sprintf(msgbuf, "Total servers supported: %d\n", SERVERS);
    logMsg(LEVEL1, msgbuf);

    sprintf(msgbuf, "Verbose level: %d\n", verbose);
    logMsg(LEVEL1, msgbuf);

    sprintf(msgbuf,
            "Send server disconnect and reconnect messages to clients? %s\n",
            warn ? "YES" : "NO");
    logMsg(LEVEL1, msgbuf);

    /* if in debug mode */
    if (debug)
    {
        sprintf(msgbuf, "Debug mode\n");
        logMsg(LEVEL1, msgbuf);
    }

    /* first sending host is required */
    if (!ns[1].host) errorExit(-108, NOSEND, REQOPT); 

    /* catch some signals */
    sigact.sa_handler = sigdetect;
    sigaction(SIGHUP,  &sigact, NULL);
    sigaction(SIGTERM, &sigact, NULL);
    sigaction(SIGINT,  &sigact, NULL);
    sigaction(SIGQUIT, &sigact, NULL);
    sigaction(SIGALRM, &sigact, NULL);
    sigaction(SIGILL,  &sigact, NULL);
    sigaction(SIGABRT, &sigact, NULL);
    sigaction(SIGFPE,  &sigact, NULL);
    sigaction(SIGSEGV, &sigact, NULL);

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

    /*create a PID file */
    if (doPID())
    {
        sprintf(msgbuf,"%s already exists", pidfile);
        errorExit(-110, "Fatal", msgbuf);
    }

    /*
     * connect to the NCID servers configured
     * add the socket to poll()
     */
    for (i = 0; i < SERVERS; ++i)
    {
        if (ns[i].host)
        {
            ns[i].sd = socketConnect(FATAL, i);
            addPoll(ns[i].sd);
        }
    }
    tosd = ns[0].sd;

    while (1)
    {
        switch (events = poll(polld, SERVERS, TIMEOUT))
        {
            case -1:    /* error */
                sprintf(msgbuf, "poll(): %s\n", strerror(errno));
                logMsg(LEVEL1, msgbuf);
                break;
            case 0:     /* timeout */
                /* try to reconnect servers that disconnected */
                for (pos = 0; pos < SERVERS; pos++)
                {
                    if (polld[pos].fd) continue;
                    /*
                     * This requires the order of sockets in polld[].
                     * match the order of sockets in ns[]
                     *
                     * the new socket must be placed in the same polld[]
                     * position as the old one
                     */
                    if (ns[pos].sd && (sd = socketConnect(0, pos)))
                    {
                        ns[pos].sd = polld[pos].fd = sd;
                        polld[pos].events = (POLLIN | POLLPRI);
                        if (warn)
                        {
                            sprintf(rcvbuf, "MSG: %s %s:%d reconnected\n",
                                    ns[pos].name, ns[pos].host, ns[pos].port);
                            ret = send(tosd, rcvbuf, strlen(rcvbuf), 0);
                        }
                    }
                }
                break;
            default:    /* 1 or more events */
                for (pos = 0; pos < SERVERS; ++pos)
                {
                    sd = polld[pos].fd;
                    if (polld[pos].revents & POLLHUP)
                    {
                        /* Hung up (output only) */
                        sprintf(msgbuf, "Hung Up, sd: %d\n", sd);
                        logMsg(LEVEL1, msgbuf);
                        close(sd);
                        polld[pos].fd = polld[pos].events
                                      = polld[pos].revents = 0;
                    }
                    if (polld[pos].revents & POLLERR)
                    {
                        /* Poll Error (output only) */
                        sprintf(msgbuf, "Poll Error, closed client %d.\n", sd);
                        logMsg(LEVEL1, msgbuf);
                        close(sd);
                        polld[pos].fd = polld[pos].events
                                      = polld[pos].revents = 0;
                    }
                    if (polld[pos].revents & POLLNVAL)
                    {
                        /* Invalid Request (output only) */
                        sprintf(msgbuf,
                                "Removed client %d, invalid request.\n", sd);
                        logMsg(LEVEL1, msgbuf);
                        polld[pos].fd = polld[pos].events
                                      = polld[pos].revents = 0;
                    }
                    if (polld[pos].revents & POLLOUT)
                    {
                        /* Write will not block */
                        sprintf(msgbuf,
                           "Removed client %d, write event not configured.\n",
                            sd);
                        logMsg(LEVEL1, msgbuf);
                        polld[pos].fd = polld[pos].events
                                      = polld[pos].revents = 0;
                    }
                    if (polld[pos].revents & (POLLIN | POLLPRI))
                    {
                        /* There is data to read */
                        sprintf(msgbuf, "Reading Socket: %d\n", sd);
                        logMsg(LEVEL9, msgbuf);

                        /* read all data until read fails */
                        while (1)
                        {
                            ret = recv(sd, rcvbuf, BUFSIZ - 1, MSG_DONTWAIT);
                            if (ret < 0)
                            {
                                /* read failed */
                                if (errno != EWOULDBLOCK && errno != EAGAIN)
                                {
                                    sprintf(msgbuf, "Client %d removed.\n",
                                            sd);
                                    logMsg(LEVEL1, msgbuf);
                                    close(sd);
                                    polld[pos].fd = polld[pos].events
                                                  = polld[pos].revents = 0;
                                }
                                break;
                            }
                            else if (ret)
                            {
                                /* data obtained */
                                rcvbuf[ret] = '\0';
                                logMsg(LEVEL8, rcvbuf);
                            }
                            else
                            {
                                /* read will return 0 for a disconnect */
                                close(sd);
                                polld[pos].fd = polld[pos].events
                                              = polld[pos].revents = 0;

                                sprintf(msgbuf, "MSG: %s %s:%d disconnected\n",
                                    ns[pos].name, ns[pos].host, ns[pos].port);
                                logMsg(LEVEL1, msgbuf + 5);
                                if (warn)
                                {
                                  if (sd != tosd)
                                    ret = send(tosd, msgbuf, strlen(msgbuf), 0);
                                }
                                break;
                            }
                        }

                        if (sd != tosd)
                        {   
                            /* data is from a sending server */
                            for (i = 0; *lineType[i]; i++)
                            {
                                /* search for certain line types */
                                if (!(ret = strncmp(lineType[i], rcvbuf,
                                    strlen(lineType[i])))) break; 
                            }
                            if (!ret)
                            {
                                /*
                                 * found line type to forward
                                 *
                                 * need to check for EAGAIN or EWOULDBLOCK
                                 * if port is made nonblocking
                                 */
                                ret = send(tosd, rcvbuf, strlen(rcvbuf), 0);
                                if (ptr = index(rcvbuf, (int) '\r'))
                                {
                                    /* found \r, remove it */
                                    *ptr++ ='\n';
                                    *ptr = '\0';
                                }
                                if (ret < 0)
                                {
                                    /*
                                     * host probably disconnected
                                     *
                                     * may need to check signals
                                     */
                                    sprintf(msgbuf,
                                            "Line not sent to %s:%d\n%s",
                                            ns[0].host, ns[0].port, rcvbuf);
                                }
                                else
                                {
                                    /* line sent to host */
                                    sprintf(msgbuf, "Line sent to %s:%d\n%s",
                                            ns[0].host, ns[0].port, rcvbuf);
                                }
                                logMsg(LEVEL1, msgbuf);
                            }
                        }   
                    }   
                }
                polld[pos].revents = 0;
                --events;
                break;
        }
    }

    /* should not get here */
    cleanup(0);
    exit(0);
}


int getOptions(int argc, char *argv[])
{
    int c, num;
    int digit_optind = 0;
    int option_index = 0;
    char *ptr;
    static struct option long_options[] = {
        {"config", 1, 0, 'C'},
        {"debug", 0, 0, 'D'},
        {"fromhost", 1, 0, 'f'},
        {"help", 0, 0, 'h'},
        {"logfile", 1, 0, 'L'},
        {"pidfile", 1, 0, 'P'},
        {"tohost", 1, 0, 't'},
        {"verbose", 1, 0, 'v'},
        {"version", 0, 0, 'V'},
        {"warn", 1, 0, 'W'},
        {0, 0, 0, 0}
    };

    while ((c = getopt_long (argc, argv, "f:hs:t:v:C:DL:P:VW:",
        long_options, &option_index)) != -1)
    {
        switch (c)
        {
            case 'f': /* [host][:port] must contain host or port or both */
                if (ptr = index(optarg, (int) ':'))
                {
                    if ((ns[1].port = atoi(ptr + 1)) == 0)
                        errorExit(-101, "Invalid port number", optarg);
                    if ((num = findWord("fromport1")) >= 0)
                        setword[num].type = 0;
                }
                if (optarg != ptr)
                {
                    if (ptr) *ptr = '\0';
                    if (!(ns[1].host = strdup(optarg))) errorExit(-1, name, 0);
                    if ((num = findWord("fromhost1")) >= 0)
                        setword[num].type = 0;
                }
                break;
            case 'h': /* help message */
                fprintf(stderr, DESC, name);
                fprintf(stderr, USAGE, name);
                exit(0);
            case 't': /* [host][:port] must contain host or port or both */
                if (ptr = index(optarg, (int) ':'))
                {
                    if ((ns[0].port = atoi(ptr + 1)) == 0)
                        errorExit(-101, "Invalid port number", optarg);
                    if ((num = findWord("toport")) >= 0)
                        setword[num].type = 0;
                }
                if (optarg != ptr)
                {
                    if (ptr) *ptr = '\0';
                    if (!(ns[0].host = strdup(optarg))) errorExit(-1, name, 0);
                    if ((num = findWord("tohost")) >= 0)
                        setword[num].type = 0;
                }
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
            case 'C':
                if (!(config = strdup(optarg)))
                    errorExit(-1, name, 0);
                break;
            case 'D':
                debug = 1;
                break;
            case 'L':
                if (!(logfile = strdup(optarg))) errorExit(-1, name, 0);
                break;
            case 'P':
                if (!(pidfile = strdup(optarg))) errorExit(-1, name, 0);
                break;
            case 'V': /* version */
                fprintf(stderr, SHOWVER, name, VERSION);
                exit(0);
            case 'W': /* warn users */
                warn = atoi(optarg);
                if (strlen(optarg) != 1 ||
                    (!(warn == 0 && *optarg == '0') && warn != 1))
                    errorExit(-107, "Invalid number", optarg);
                if ((num = findWord("warn")) >= 0) setword[num].type = 0;
                break;
            case '?': /* bad option */
                fprintf(stderr, USAGE, name);
                exit(-100);
        }
    }
    return optind;
}

int addPoll(int pollfd)
{
    int added, pos;

    for (added = pos = 0; pos < SERVERS; ++pos)
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

/*
 * Returns the current date and time as a string in the format:
 *      WITHYEAR: MM/DD/YYYY HH:MM:SS
 *      NOYEAR:   MMDDHHMM
 *      ONLYTIME: HH:MM:SS
 */
char *strdate(int withyear)
{
    static char buf[BUFSIZ];
    struct tm *tm;
    struct timeval tv;

    (void) gettimeofday(&tv, 0);
    tm = localtime((const time_t *)&(tv.tv_sec));
    if (withyear & WITHYEAR)
        sprintf(buf, "%.2d/%.2d/%.4d %.2d:%.2d:%.2d", tm->tm_mon + 1,
                tm->tm_mday, tm->tm_year + 1900, tm->tm_hour, tm->tm_min,
                tm->tm_sec);
    else if (withyear & NOYEAR)
        sprintf(buf, "%.2d%.2d%.2d%.2d", tm->tm_mon + 1,
                tm->tm_mday, tm->tm_hour, tm->tm_min);
    else
        sprintf(buf, "%.2d:%.2d:%.2d",  tm->tm_hour, tm->tm_min, tm->tm_sec);
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
    int retval, ret = 0;

    /* if pidfile == 0, no pid file is wanted */
    if (pidfile == 0)
    {
        logMsg(LEVEL1, "Not using PID file, there was no '-P' option.\n");
        return ret;
    }

    /* check PID file */
    curpid = getpid();
    if (stat(pidfile, &statbuf) == 0)
    {
        if ((pidptr = fopen(pidfile, "r")) == NULL) return(1);
        retval = fscanf(pidptr, "%u", &foundpid);
        fclose(pidptr);
        if (foundpid) ret = kill(foundpid, 0);
        if (ret == 0 || (ret == -1 && errno != ESRCH)) return(1);
        sprintf(msgbuf, "Found stale pidfile: %s\n", pidfile);
        logMsg(LEVEL1, msgbuf);
    }

    /* create pidfile */
    if ((pidptr = fopen(pidfile, "w")) == NULL)
    {
        sprintf(msgbuf, "Cannot write %s: %s\n", pidfile, strerror(errno));
        logMsg(LEVEL1, msgbuf);
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
 * connect to the NCID server
 *     exit on connect error if fatal = 1
 *     contunue on connect error if fatal = 0
 *
 *     returns socket created or 0
 */
int socketConnect(int fatal, int pos)
{
    int sd = 0, ret, i;
	char msgbuf[BUFSIZ];
	struct sockaddr_in sin;
	struct sockaddr_in pin;

    /*
     * The TiVo S1 does not have gethostbyname() in libc.so.
     * The #ifndef's replace gethostbyname() with inet_addr().
     * IP addresses must be used, not host names, for the TiVo S1
     */
#ifndef TIVO_S1
	struct hostent *hp;
	/* find out about the desired host machine */
	if ((hp = gethostbyname(ns[pos].host)) == 0)
        errorExit(-1, "gethostbyname", strerror(h_errno));
#endif
	/* fill in the socket structure with host information */
	memset(&pin, 0, sizeof(pin));
	pin.sin_family = AF_INET;
#ifndef TIVO_S1
	pin.sin_addr.s_addr = ((struct in_addr *)(hp->h_addr))->s_addr;
#else
	if (pin.sin_addr.s_addr = inet_addr(ns[pos].host) == INADDR_NONE)
        errorExit(-1, ns[pos].host, "Bad IP Address");
#endif
	pin.sin_port = htons(ns[pos].port);

	/* grab an Internet domain socket */
	if ((sd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
        errorExit(-1, "socket", 0);

	/* connect to PORT on HOST */
	if (connect(sd, (struct sockaddr *) &pin, sizeof(pin)) == -1)
    {
        /* connect failed */
        sprintf(msgbuf, "%s:%d",ns[pos].host, ns[pos].port);
        if (fatal) errorExit(-1, msgbuf, 0);
        /* if connect fails, close socket */
        close(sd);
        sd = 0;
    
    }
    else
    {
        /* connected */
        sprintf(msgbuf, "%s: %s:%d\n",
                ns[pos].name, ns[pos].host, ns[pos].port);
        logMsg(LEVEL1, msgbuf);

        /* log greeting from server */
        for (i = 0;  i < 50; ++i)
        {
            (void) recv(sd, &msgbuf[i], 1, 0);
            if (msgbuf[i] == '\n')
            {
                msgbuf[i + 1] = '\0';
                break;
            }
        }
        logMsg(LEVEL1, msgbuf);
    }

    return sd;
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

void cleanup(int error)
{
    char msgbuf[BUFSIZ];

    /* remove pid file, if it was created */
    if (pid)
    {
        unlink(pidfile);
        sprintf(msgbuf, "Removed pidfile: %s\n", pidfile);
        logMsg(LEVEL1, msgbuf);
    }

    if (error != -100 && error != -101 && error != -107)
    {
        /* do not print terminated message, if option error */
        sprintf(msgbuf, "Terminated:  %s\n", strdate(WITHYEAR));
        logMsg(LEVEL1, msgbuf);
    }
}

/* Log error, call cleanup(), and exit */
void errorExit(int error, char *msg, char *arg)
{
    char msgbuf[BUFSIZ];

    if (error == -1 && arg == 0)
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

    cleanup(error);

    exit(error);
}

/* process signals */
void sigdetect(int sig)
{
    char msgbuf[BUFSIZ];

    sprintf(msgbuf, "Received Signal: %s\n", strsignal(sig));
    logMsg(LEVEL1, msgbuf);

    /* termination signals */
    cleanup(0);

    /* allow signal to terminate the process */
    signal (sig, SIG_DFL);
    raise (sig);
}

/*
 * Process the config file.
 */

int doConf()
{
    char input[BUFSIZ], word[BUFSIZ], msgbuf[BUFSIZ], *inptr;
    int lc;
    FILE *fp;

    if ((fp = fopen(config, "r")) == NULL)
    {
        sprintf(msgbuf, "No config file: %s\n", config);
        logMsg(LEVEL1, msgbuf);
        return 0;
    }

    /* read each line of file, one line at a time */
    for (lc = 1; fgets(input, BUFSIZ, fp) != NULL; lc++)
    {
        inptr = getWord(input, word, lc);

        /* line containing only <NL> or is a comment line*/
        if (inptr == 0 || word[0] == '#') continue;

        /* first word on line must be "set" */
        if (!strcmp(word, "set")) doSet(inptr, lc);
        else configError(lc, word, ERRCMD);
    }
    (void) fclose(fp);
    sprintf(msgbuf, "Processed config file: %s\n", config);
    logMsg(LEVEL1, msgbuf);
    return conferr;
}

/*
 * process set lines:
 *        set word = value
 */

int doSet(char *inptr, int lc)
{
    int num;
    char word[BUFSIZ], msgbuf[BUFSIZ];

    /* process configuration parameters */
    while (inptr = getWord(inptr, word, lc))
    {
        if (word[0] == '#')    break; /* rest of line is comment */

        if ((num = findWord(word)) < 0)
        {
            configError(lc, word, ERRWORD);
            break;
        }

        if (!(inptr = getWord(inptr, word, lc)))
        {
            configError(lc, word, ERREQA);
            break;
        }

        if (word[0] != '=')
        {
            configError(lc, word, ERREQB);
            break;
        }

        if (!(inptr = getWord(inptr, word, lc)))
        {
            configError(lc, word, ERRARG);
            break;
        }

        /* make sure config file does not override command line */
        if (setword[num].type)
        {
            if (setword[num].type & WORDSTR)
            {
                if (!(*setword[num].buf = strdup(word)))
                    errorExit(-1, name, 0);

                /* set flag, if needed */
                if (setword[num].type & WORDFLAG) ++(*setword[num].value);
            }
            else
            {
                /* atoi does not return an error */
                *setword[num].value = atoi(word);
                if(*setword[num].value == 0 && *word != '0')
                    configError(lc, word, ERRNUM);

                /* min is always tested, even if 0, max is not, if 0 */
                if ((*setword[num].value < setword[num].min) ||
                        (setword[num].max &&
                        *setword[num].value > setword[num].max))
                    configError(lc, word, ERRNUM);
            }
        }
        else
        {
            sprintf(msgbuf, "Skipping: set %s    From config file: %s\n",
                setword[num].word, config);
            logMsg(LEVEL1, msgbuf);
        }
    }
}

int findWord(char *wdptr)
{
    int i;

    for (i = 0; setword[i].word; i++)
        if (!strcmp(wdptr, setword[i].word)) return i;

    return -1;
}

int configError(int lc, char *word, char *mesg)
{
    if (*word != 0)
    {
        fprintf(stderr, "%s: Line %d; %s %s\n", config, lc, mesg, word);
        ++conferr;
    }
}

/*
 * a word is either a series of non-space characters,
 * everything between double quotes, or '='
 */

char *getWord(char *inptr, char *wdptr, int lc)
{
    char *endptr;

    if (inptr == 0) return 0;

    while (*inptr && isspace(*inptr)) inptr++;
    if (endptr = strchr(inptr, '\n')) *endptr = 0;
    if (*inptr == 0) return 0;
    *wdptr = 0;

    if (*inptr == '"')
    {
        ++inptr;
        if ((endptr = strchr(inptr, '"')) == 0)
        {
            configError(lc, "\"", ERRMISS);
            return 0;
        }
        while (*inptr && inptr != endptr) *wdptr++ = *inptr++;
        if (*inptr) inptr++;
    }
    else if (*inptr == '=') *wdptr++ = *inptr++;
    else while (*inptr && !isspace(*inptr) && *inptr != '=' && *inptr != '"')
            *wdptr++ = *inptr++;

    *wdptr = 0;

    return inptr;
}

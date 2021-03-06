/*
 * sip2ncid.c - This file is part of sip2ncid.
 *
 * Copyright (c) 2005-2013
 * by John L. Chmielewski <jlc@users.sourceforge.net>
 *
 * sip2ncid is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * sip2ncid is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with sip2ncid.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "sip2ncid.h"

/* globals */
int debug, listdevs, msgsent, nofilter, test, sd, warn, rmdups, OSXlaunchd;
int ncidport   = NCIDPORT;
int sipport    = SIPPORT;
int verbose    = 1;
char *pidfile;
char *ncidhost = LOCALHOST;
char *logfile  = LOGFILE;
char *name, *siphost, *device, *readfile, *writefile;
pid_t pid;
FILE *logptr;
pcap_t *descr;
pcap_dumper_t *dumpfile;
struct sigaction sigact;
struct calls                    /* calls in progress */
{
    char *callid;
    char *callstart;
    char *line;
} calls[MAXCALL];

int doPID(), getOptions(), pcapListDevs(), parseLine(), getCallID(),
    findCallID(), addCallID(), rmCallID(), socketRead(), callType();
void cleanup(), doPCAP(), sigdetect(), errorExit(), socketConnect(),
     processPackets();
char *strdate(), *inet_ntoa(), *strmatch(), *lineLabel();
#ifndef __CYGWIN__
    extern char *strsignal();
#endif

int main(int argc, char *argv[])
{
    int argind, i, errnum = 0;
    char msgbuf[BUFSIZ];

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

    if (listdevs)
    {
        pcapListDevs();
        exit(0);
    }

    if (!test){
        /*
         * not in test mode, create or open existing logfile
         */
        logptr = fopen(logfile, "a");
        errnum = errno;
    }

    sprintf(msgbuf, "Started: %s\nGateway: %s %s\n",strdate(WITHYEAR),
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
    strcat(msgbuf, "\n");
    logMsg(LEVEL1, msgbuf);

    if (!test)
    {
        /* not in test mode, check status of logfile */
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

        if (debug)
        {
            /* debug mode */
            sprintf(msgbuf, "Debug mode\n");
            logMsg(LEVEL1, msgbuf);
        }
    }
    else
    {
        /*
         * in test mode, test mode is also debug mode
         */
        debug = 1;

        sprintf(msgbuf, "%s mode\nServer: %s %s\n",
                readfile ? "Dump read" : "Test", name, VERSION);
        logMsg(LEVEL1, msgbuf);
    }

    /*
     * read config file, if present, exit on any errors
     * do not override any options set on the command line
     */
    if (doConf()) errorExit(-104, 0, 0);

    if (readfile)
    {
        sprintf(msgbuf, "Reading from dumpfile: %s\n", readfile);
        logMsg(LEVEL1, msgbuf);
    }
    else if (writefile)
    {
        sprintf(msgbuf, "Writing to dumpfile: %s\n", readfile);
        logMsg(LEVEL1, msgbuf);
    }

    sprintf(msgbuf, "Verbose level: %d\n", verbose);
    logMsg(LEVEL1, msgbuf);

    sprintf(msgbuf,
        "Warn clients: 'No SIP packets' & 'SIP packets returned' messages? %s\n",
            warn ? "YES" : "NO");
    logMsg(LEVEL1, msgbuf);
    sprintf(msgbuf,
        "Remove duplicate INVITE Packets? %s\n", rmdups ? "YES" : "NO");
    logMsg(LEVEL1, msgbuf);

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

    /* must not be in test mode to create a PID file and connect to NCID */
    if (!test)
    {
        sprintf(msgbuf,"NCID server at %s:%d\n", ncidhost, ncidport);
        logMsg(LEVEL1, msgbuf);

        if (doPID())
        {
            sprintf(msgbuf,"%s already exists", pidfile);
            errorExit(-110, "Fatal", msgbuf);
        }

        socketConnect(FATAL);
    }

    doPCAP();

    /* should only get here after reading a dump file */
    cleanup(0);
    exit(0);
}


int getOptions(int argc, char *argv[])
{
    int c, num;
    int option_index = 0;
    char *ptr;
    static struct option long_options[] = {
        {"config", 1, 0, 'C'},
        {"debug", 0, 0, 'D'},
        {"help", 0, 0, 'h'},
        {"interface", 1, 0, 'i'},
        {"listdevs", 0, 0, 'l'},
        {"logfile", 1, 0, 'L'},
        {"ncid", 1, 0, 'n'},
        {"pidfile", 1, 0, 'P'},
        {"sip", 1, 0, 's'},
        {"testudp", 0, 0, 't'},
        {"testall", 0, 0, 'T'},
        {"verbose", 1, 0, 'v'},
        {"version", 0, 0, 'V'},
        {"writefile", 1, 0, 'w'},
        {"warn", 1, 0, 'W'},
        {"osx-launchd", 0, 0, '0'},
        {0, 0, 0, 0}
    };

    while ((c = getopt_long (argc, argv, "hi:ln:r:s:tv:w:C:DL:P:TVW:",
        long_options, &option_index)) != -1)
    {
        switch (c)
        {
            case '0':
                ++OSXlaunchd;
                break;
            case 'r':
                if (!(readfile = strdup(optarg))) errorExit(-1, name, 0);
                test = 1;
                verbose = 3;
                break;
            case 'w':
                if (!(writefile = strdup(optarg))) errorExit(-1, name, 0);
                debug = 1;
                verbose = 3;
                break;
            case 'h': /* help message */
                fprintf(stderr, DESC, name);
                fprintf(stderr, USAGE, name);
                exit(0);
            case 'i':
                if (!(device = strdup(optarg))) errorExit(-1, name, 0);
                if ((num = findWord("interface")) >= 0) setword[num].type = 0;
                break;
            case 'l':
                listdevs = 1;
                break;
            case 'n': /* [host][:port] must contain host or port or both */
                if ((ptr = index(optarg, (int) ':')))
                {
                    if ((ncidport = atoi(ptr + 1)) == 0)
                        errorExit(-101, "Invalid port number", optarg);
                    if ((num = findWord("ncidport")) >= 0)
                        setword[num].type = 0;
                }
                if (optarg != ptr)
                {
                    if (ptr) *ptr = '\0';
                    if (!(ncidhost = strdup(optarg))) errorExit(-1, name, 0);
                    if ((num = findWord("ncidhost")) >= 0)
                        setword[num].type = 0;
                }
                break;
            case 's':
                if ((ptr = index(optarg, (int) ':')))
                {
                    if ((sipport = atoi(ptr + 1)) == 0)
                        errorExit(-101, "Invalid port number", optarg);
                    if ((num = findWord("sipport")) >= 0)
                        setword[num].type = 0;
                }
                if (optarg != ptr)
                {
                    if (ptr) *ptr = '\0';
                    if (!(siphost = strdup(optarg))) errorExit(-1, name, 0);
                    if ((num = findWord("siphost")) >= 0)
                        setword[num].type = 0;
                }
                break;
            case 't':
                test = 1;
                verbose = 3;
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
            case 'T':
                test = 1;
                nofilter = 1;
                verbose = 3;
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
 * connect to the NCID server
 *     exit on connect error if fatal = 1
 *     contunue on connect error if fatal = 0
 */
void socketConnect(int fatal)
{
	char msgbuf[BUFSIZ];
	struct sockaddr_in pin;

    /*
     * The TiVo S1 does not have gethostbyname() in libc.so.
     * The #ifndef's replace gethostbyname() with inet_addr().
     * IP addresses must be used, not host names, for the TiVo S1
     */
#ifndef TIVO_S1
	struct hostent *hp;
	/* find out about the desired host machine */
	if ((hp = gethostbyname(ncidhost)) == 0)
        errorExit(-1, "gethostbyname", strerror(h_errno));
#endif
	/* fill in the socket structure with host information */
	memset(&pin, 0, sizeof(pin));
	pin.sin_family = AF_INET;
#ifndef TIVO_S1
	pin.sin_addr.s_addr = ((struct in_addr *)(hp->h_addr))->s_addr;
#else
	if (pin.sin_addr.s_addr = inet_addr(ncidhost) == INADDR_NONE)
        errorExit(-1, "NCIDHOST", "Bad IP Address");
#endif
	pin.sin_port = htons(ncidport);

	/* grab an Internet domain socket */
	if ((sd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
        errorExit(-1, "socket", 0);

	/* connect to PORT on HOST */
	if (connect(sd, (struct sockaddr *) &pin, sizeof(pin)) == -1)
    {
        if (fatal) errorExit(-1, "NCID server", 0);
        sprintf(msgbuf, "Warning: could not connect to the NCID server\n");
        logMsg(LEVEL2, msgbuf);
        /* if connect fails, close socket */
        close(sd);
        sd = 0;
    
    }
    else if (fcntl(sd, F_SETFL, O_NONBLOCK) < 0) errorExit(-1, "socket", 0);
}

int socketRead()
{
    int num;
    char msgbuf[BUFSIZ];

    if ((num = read(sd, msgbuf, BUFSIZ-1)) > 0)
    {
        msgbuf[num] = '\0';
        logMsg(LEVEL9, msgbuf);
    }
    return(num);
}

/*
 * List all network Devices
 */
int pcapListDevs()
{
    char errbuf[PCAP_ERRBUF_SIZE];
    char *desc, *ptr;
    pcap_if_t *alldevsp;

    if (pcap_findalldevs(&alldevsp, errbuf) < 0)
    {
        errorExit(-1, "pcap_findalldevs()", errbuf);
    }
    while (alldevsp)
    {
        if ((desc = alldevsp->description) == 0)
        {
            if (alldevsp->flags == PCAP_IF_LOOPBACK) desc = LOOPBACK;
            else if (!strncmp(alldevsp->name, "virbr", 5)) desc = VIRBR;
            else desc = NODESC;
        }

        /* If using WinPcap, path elements use '\' instead of '/' */
        while ((ptr = index(alldevsp->name, (int) '\\'))) *ptr = '/';

        fprintf(stdout, "%s : %s\n", alldevsp->name, desc);
        alldevsp = alldevsp->next;
    }
    pcap_freealldevs(alldevsp);
    return(0);
}

/* callback function that is passed to pcap_loop(..) and called each time
 * a packet is recieved
 */
void processPackets(u_char *args,
                    const struct pcap_pkthdr* pkthdr,
                    const u_char* packet)
{
    static unsigned int pktnum = 0;        /* packet number */
    static unsigned int invnum = 0;        /* INVITE packet number */
    static unsigned int gotdup = 0;        /* INVITE packet duplicate */
    static unsigned int charcnt;           /* character count */
    static char *linenum[MAXLINE];         /* telephone lines */

    /* declare pointers to packet headers */
    const struct ip *ip;                   /* IP Header */
    const struct udphdr *udp;              /* UDP Header */
    const char   *pdata;                   /* Packet Data */

    int size_ip, size_udp, size_pdata, cnt, pos, empty, retval, outcall;

    char sipbuf[SIPSIZ], msgbuf[BUFSIZ], cidmsg[BUFSIZ], warnmsg[BUFSIZ],
         tonumber[CIDSIZ], fromnumber[CIDSIZ], callid[CIDSIZ],
         toname[CIDSIZ], fromname[CIDSIZ];
    char *line, *number, *name, *type, *ptr;

    alarm(PKTWAIT); /* reset SIP packet timeout alarm */
    if (msgsent & 0x1)
    {
        /* log only one SIP packets returned message */
        sprintf(msgbuf, "SIP packets returned: port %d %s\n",
                sipport, strdate(WITHYEAR));
        logMsg(LEVEL1, msgbuf);

        if (warn && sd)
        {
            /*
            * send clients SIP OK message if warn option
            * set and if connected to the NCID server
            */
            sprintf(warnmsg, "MSG: %s", msgbuf);
            retval =  write(sd, warnmsg, strlen(warnmsg));
        }
    }
    msgsent = 0;    /* reset message log flag */

    /* 
     * if socket is open:
     *  try to read data from server
     *  close socket if connection gone
     */
    if (sd)
    {
        /*
         * socketRead:
         *  returns  0 when socket no longer connected
         *  returns -1 when socket has no data to read 
         *  returns a number when data read from socket
         */
        if ((cnt = socketRead()) == 0)
        {
            close(sd);
            sd = 0;
        }
        else if (cnt == -1)
        {
            if (charcnt)
            {
                sprintf(msgbuf, "NCID server sent %d characters\n", charcnt);
                logMsg(LEVEL3, msgbuf);
                charcnt = 0;
            }
        }
        else charcnt += (unsigned) cnt;
    }

    /* write packet to dumpfile */
    if (writefile) pcap_dump(args, pkthdr, packet);

    /* if no open socket, and not in test mode, try to connect again */
    if (!sd && !test) socketConnect(NONFATAL);

    sprintf(msgbuf, "Packet number: %u\n", ++pktnum);
    logMsg(LEVEL2, msgbuf);

    /* compute IP header offset */
    ip = (struct ip *)(packet + SIZE_ETHERNET);
    size_ip = (ip->ip_hl)*4;
    if (size_ip < 20)
    {
        sprintf(msgbuf, "   * Invalid IP header length: %u bytes\n", size_ip);
        logMsg(LEVEL1, msgbuf);
        return;
    }

    /* log source and destination IP addresses */
    sprintf(msgbuf, "       From: %s\n         To: %s\n",
            inet_ntoa(ip->ip_src), inet_ntoa(ip->ip_dst));
    logMsg(LEVEL4, msgbuf);

    /* determine protocol */
    switch(ip->ip_p) {
        case IPPROTO_TCP:
            sprintf(msgbuf, "   Protocol: TCP\n");
            logMsg(LEVEL3, msgbuf);
            return;
        case IPPROTO_UDP:
            sprintf(msgbuf, "   Protocol: UDP\n");
            logMsg(LEVEL3, msgbuf);
            if (nofilter) return;
            break;
        case IPPROTO_ICMP:
            sprintf(msgbuf, "   Protocol: UDP\n");
            logMsg(LEVEL3, msgbuf);
            return;
        case IPPROTO_IP:
            sprintf(msgbuf, "   Protocol: IP\n");
            logMsg(LEVEL3, msgbuf);
            return;
        default:
            sprintf(msgbuf, "   Protocol: unknown\n");
            logMsg(LEVEL3, msgbuf);
            return;
    }

    /*
     *  UDP packets reach here, if no filter was used.
     */

    /* compute UDP header offset */
    udp = (struct udphdr *)(packet + SIZE_ETHERNET + size_ip);
    size_udp = sizeof (struct udphdr);

    /* log source and destination ports */
    sprintf(msgbuf, "   Src port: %d\n   Dst port: %d\n",
            ntohs(udp->uh_sport), ntohs(udp->uh_dport));
    logMsg(LEVEL4, msgbuf);

    /* compute UDP packet data offset */
    pdata = (char *)(packet + SIZE_ETHERNET + size_ip + size_udp);

    /* compute UDP packet data size */
    size_pdata = ntohs(ip->ip_len) - (size_ip + size_udp);

    /* if UDP packet has data */
    if (size_pdata > 0)
    {
        sprintf(msgbuf, "   UDP data: %d bytes:\n", size_pdata);
        logMsg(LEVEL4, msgbuf);
        if (size_pdata < SIPSIZ)
            *(strncpy(sipbuf, pdata, size_pdata) + size_pdata) = '\0';
        else
        {
            *(strncpy(sipbuf, pdata, SIPSIZ - 1) + SIPSIZ) = '\0';
            sprintf(msgbuf, "Warning: SIP Packet truncated: %u > %u\n",
                    size_pdata, SIPSIZ - 1);
            logMsg(LEVEL1, msgbuf);
        }
        logMsg(LEVEL3, sipbuf);

        /*
         * Must be a SIP/2 packet
         */
        if (strstr(sipbuf, SIPVER))
        {
            /*
             * Look for CSeq INVITE line
             *   Cseq: NMBR INVITE
             *
             * INVITE Packets:
             *   INVITE sip:15553331212@192.168.111.21:10000 SIP/2.0
             *   SIP/2.0 NMBR Trying
             *   SIP/2.0 NMBR Ringing
             *   SIP/2.0 NMBR Request Terminated
             *   SIP/2.0 183 Session Progress
             *   SIP/2.0 401 Unauthorized
             *   SIP/2.0 407 Proxy Authentication Required
             *   SIP/2.0 487 Request Cancelled
             *   SIP/2.0 487 Request Terminated
             */
            if (strmatch(sipbuf, CSEQ, INVITE))
            {
                /*
                 * Crude test for duplicate INVITE packet
                 *
                 * Assumes a duplicate if 2 INVITE packets in a row
                 * or for a INVITE and all RINGING packets in a row
                 *
                 * invnum was previous INVITE packet number
                 *
                 * it's possible this could miss a call if 2 come
                 * in at the same time
                 */
                if (rmdups)
                {
                    /* Configured to find and remove duplicate SIP packets */

                    if (gotdup)
                    {
                        if (strstr(sipbuf, "Trying"))
                        {
                            sprintf(msgbuf, "Ignoring Trying Packet %u\n",
                                    pktnum);
                            logMsg(LEVEL2, msgbuf);
                            return;
                        }
                        if (strstr(sipbuf, "Ringing"))
                        {
                            sprintf(msgbuf, "Ignoring Ringing Packet %u\n",
                                    pktnum);
                            logMsg(LEVEL2, msgbuf);
                            return;
                        }
                    }
                    if (pktnum == invnum + 1)
                    {
                        sprintf(msgbuf, "Duplicate INVITE Packet %u with %u\n",
                            pktnum, invnum);
                        logMsg(LEVEL2, msgbuf);
                        invnum = pktnum;
                        gotdup = 1;
                        return;
                    }
                    else
                    {
                        invnum = pktnum;
                        gotdup = 0;
                    }
                }

                /* Get the unique Call-ID */
                getCallID(sipbuf, callid, sizeof(callid), INVITE);

                /*
                 * Ignore a Request Terminated packet
                 * Ignore a Request Cancelled packet
                 */
                if (strmatch(sipbuf, SIPVER, REQTERM) ||
                    strmatch(sipbuf, SIPVER, REQCAN))
                {
                    /*
                     * Call-ID should already have been cleared,
                     * but just in case ...
                     */
                    (void) rmCallID(callid);
                    return;
                }

                /* if Call-ID found, call in progress */
                if (findCallID(callid) != -1) return;

                /*
                 * Get called number from To line:
                 *
                 * To: <sip:CALLED_NMBR@IP_Address>;tag=TAG_NMBR
                 */
                if (parseLine(sipbuf, INVITE, TO,
                    (char *) 0, (char *) &number) == 0)
                {
                    strcpy(tonumber, number);
                }

               /*
                * Get Caller ID information from From line
                *
                * From: [["]NAME["]] <sip:CALLING_NMBR@IP_ADDR>;tag=TAG_NMBR
                */
                if (parseLine(sipbuf, INVITE, FROM,
                    (char *) &name, (char *) &number) == 0)
                {
                    /* assumes incoming call */
                    strcpy(fromnumber, number);

                    /* Determine if call is incoming or outgoing. */
                    outcall = callType(sipbuf, fromnumber, linenum);

                    if (outcall)
                    {
                        /* Outgoing Call */
                        line = lineLabel(fromnumber);
                        number = tonumber;
                        name = NONAME;
                        type = CALLOUT;
                    }
                    else
                    {
                        /* Incoming Call */
                        line = lineLabel(tonumber);
                        number = fromnumber;
                        type = CALLIN;
                    }

                /* add Call-ID to calls in-progress table, if not filled */
                (void) addCallID(callid, line);

                    sprintf(cidmsg, CIDLINE, strdate(NOYEAR), type, line,
                            number, name);
                    if (sd) retval =  write(sd, cidmsg, strlen(cidmsg));
                    logMsg(LEVEL1, cidmsg);
                }
            }

            /*
             * Look for CSeq CANCEL line
             *  CSeq: NMBR CANCEL
             *
             * CANCEL Packets:
             *   CANCEL sip:15553331212@192.168.111.21:10000 SIP/2.0
             *   SIP/2.0 NMBR OK
             *
             * Hangup Before Answer
             */
            else if (strmatch(sipbuf, CSEQ, CANCEL))
            {
                /* Get the unique Call-ID */
                getCallID(sipbuf, callid, sizeof(callid), CANCEL);

                /* If Call-ID not found, return */
                if ((pos = findCallID(callid)) == -1) return;

                /*
                 * Get calling number from a "From:" line
                 *
                 * From: [["]NAME["]] <sip:CALLING_NMBR@IP_ADDR>;tag=TAG_NMBR
                 */
                if (parseLine(sipbuf, CANCEL, FROM, (char *) &name,
                    (char *) &number)) return;
                strcpy(fromnumber, number);
                strcpy(fromname, name);

                /*
                 * if number is a telephone line number, it is a outgoing call
                 * and the called number is in the TO line
                 *
                 * To: [["]NAME["]] <sip:CALLED_NMBR@IP_ADDR>;tag=TAG_NMBR
                 */
                if (parseLine(sipbuf, CANCEL, TO, (char *) &name,
                    (char *) &number) == 0)
                {
                    strcpy(tonumber, number);
                    strcpy(toname, name);

                    /* Determine if call is incoming or outgoing. */
                    outcall = callType(sipbuf, fromnumber, linenum);

                    if (outcall)
                    {
                        /* Outgoing Call */
                        number = tonumber;
                        name = toname;
                        type = CALLOUT;
                    }
                    else
                    {
                        /* Incoming Call */
                        number = fromnumber;
                        name = fromname;
                        type = CALLIN;
                    }

                    ptr = strdup(strdate(NOYEAR));
                    sprintf(cidmsg, INFOLINE, CANCEL, ptr,
                            calls[pos].callstart, strdate(WITHYEAR),
                            type, calls[pos].line, number, name);
                    free(ptr);
                    if (sd) retval =  write(sd, cidmsg, strlen(cidmsg));
                    logMsg(LEVEL1, cidmsg);
                }

                /* Remove Call-ID */
                (void) rmCallID(callid);
            }

            /*
             * Look for CSeq BYE line
             *  CSeq: NMBR BYE
             *
             * BYE Packets:
             *   BYE sip:15553331212@192.168.111.21:10000 SIP/2.0
             *   SIP/2.0 407 Proxy Authentication Required
             *   SIP/2.0 NMBR OK
             *
             * Hangup After Answer
             */
            else if (strmatch(sipbuf, CSEQ, BYE))
            {
                /* Get the unique Call-ID */
                getCallID(sipbuf, callid, sizeof(callid), BYE);

                /* If Call-ID not found, return */
                if ((pos = findCallID(callid)) == -1) return;

                /*
                 * Get calling number from a "To:" or "From:" line
                 * To: [["]NAME["]] <sip:CALLING_NMBR@IP_ADDR>;tag=TAG_NMBR
                 */
                if (parseLine(sipbuf, BYE, TO, (char *) &name,
                    (char *) &number)) return;
                strcpy(tonumber, number);
                strcpy(toname, name);

                /*
                 * if number is the telephone line number,
                 * the calling number is in the FROM line
                 *
                 * From: [["]NAME["]] <sip:CALLING_NMBR@IP_ADDR>;tag=TAG_NMBR
                 */
                if (parseLine(sipbuf, BYE, FROM, (char *) &name,
                    (char *) &number) == 0)
                {
                    strcpy(fromnumber, number);
                    strcpy(fromname, name);

                    /* Determine if call is incoming or outgoing. */
                    outcall = callType(sipbuf, fromnumber, linenum);

                    if (outcall)
                    {
                        /* Outgoing Call */
                        number = tonumber;
                        name = toname;
                        type = CALLOUT;
                    }
                    else
                    {
                        /* Incoming Call */
                        number = fromnumber;
                        name = fromname;
                        type = CALLIN;
                    }

                    ptr = strdup(strdate(NOYEAR));
                    sprintf(cidmsg, INFOLINE, BYE, ptr,
                            calls[pos].callstart, strdate(WITHYEAR),
                            type, calls[pos].line, number, name);
                    free(ptr);
                    if (sd) retval =  write(sd, cidmsg, strlen(cidmsg));
                    logMsg(LEVEL1, cidmsg);
                }

                /* Remove Call-ID it */
                (void) rmCallID(callid);
            }

            /*
             * Look for SIP/2 Unauthorized line
             *  SIP/2.0 401 Unauthorized
             *  CSeq: NMBR REGISTER
             */
            else if (strmatch(sipbuf, SIPVER, UNAUTHORIZED))
            {
                /*
                 * Skip this packet, otherwize it is considered
                 * a REGISTER packet.
                 */
            }

            /*
             * Look for CSeq REGISTER line
             *  CSeq: NMBR REGISTER
             *
             * REGISTER Packets:
             *   REGISTER sip:h.voncp.com:10000 SIP/2.0
             *   SIP/2.0 200 OK
             */
            else if (strmatch(sipbuf, CSEQ, REGISTER))
            {
                /*
                 * Get the telephone line number from CONTACT line
                 *
                 * Contact: ["]NAME["]] <sip:NMBR@IP_ADDR:PORT>;expires=TIME
                 *
                 * Normally the contact line is the same as the from line
                 * but on a PBX the from line is the extension and the
                 * contact line is the number called.  Extensions need to
                 * be handled properly.
                 */
                if (parseLine(sipbuf, REGISTER, CONTACT, (char *) 0,
                    (char *) &number) == 0)
                {
                    /* add phone number if not seen before */
                    for (cnt = pos = empty = 0; cnt < MAXLINE; ++cnt)
                    {
                        if (!linenum[cnt])
                        {
                            /* get 1st empty position in table */
                            if (!empty) pos = cnt;
                            empty = 1;
                            continue;
                        }
                        if (!strcmp(linenum[cnt], number)) return;
                    }
                    if (empty)
                    {
                        linenum[pos] = strdup(number);
                        sprintf(cidmsg, REGLINE, pos, number);
                        logMsg(LEVEL1, cidmsg);
                    }
                    else
                    {
                        sprintf(cidmsg,
                            "Number of telephone lines exceeds: %u\n", MAXLINE);
                        logMsg(LEVEL1, cidmsg);
                    }
                }
            }
        }
    }

    return;
}

/*
 * Determine the line label, usually last 4 digits
 * of the receiving call telephone number, but it
 * might be masked in which case it is anon [ymous]
 */
char *lineLabel(char *number)
{
    char *label;

    if (isdigit(number[0]) && isdigit(number[1]))
        label = number + strlen(number) - 4;
    else label = "ANON";

    return label;
}

/*
 * Determine if call is incoming or outgoing
 *  Returns 0 if incoming call
 *  Returns 1 if outgoing call
 */

int callType(char *sipbuf, char *number, char *linenum[])
{
    int cnt, outcall = 0;
    char msgbuf[BUFSIZ];

    /*
     * Determine if call is incoming or outgoing.
     * If telephone number is in linenum, it is a outgoing call.
     */
    for (cnt = 0; cnt < MAXLINE; ++cnt)
    {
        if (linenum[cnt])
        {
            sprintf(msgbuf,
                "linenum[%d]=%s  number=%s\n", cnt, linenum[cnt], number);
            logMsg(LEVEL5, msgbuf);
        }
        if (linenum[cnt] && !strcmp(linenum[cnt], number))
        {
            outcall = 1;
            break;
        }
    }

    /*
     * At least one PBX does not send out any REGISTER
     * packets so the linenum array is not populated
     * with telephone numbers receiving calls.
     */
    if (cnt >= MAXLINE)
    {
        /*
         * The linenum array has no entries or is filled.
         * Look for "Call-ID: call-" at the begining of
         * the buffer.  If there, it is a outgoing call.
        */
        if (strstr(sipbuf, OUTCALL) != NULL) outcall = 1;
        sprintf(msgbuf, "Checked for \"%s\" outcall= %d\n",
            OUTCALL, outcall);
        logMsg(LEVEL5, msgbuf);
    }
    return outcall;
}

/*
 * Parse Line for number and name, if requested
 */

int parseLine(char *sipbuf, char *plabel, char *llabel,
               char **name, char **number)
{
    int ret = 0;
    char *sptr, *eptr, *elptr;
    char msgbuf[BUFSIZ];
    static char linebuf[SIPSIZ];

    /* make copy of input buffer */
    strcpy(linebuf, sipbuf);

    if ((sptr = strstr(linebuf, llabel)))
    {
        /* Terminate end of line */
        if ((elptr = index(sptr, (int) NL)))
        {
            *elptr = '\0';
    
            if (name)
            {
                /* Look for NAME in quotes */
                if ((*name = index(sptr, (int) QUOTE)))
                {
                    if ((eptr = index(++*name, (int) QUOTE)))
                    {
                        *eptr = '\0';
                        sptr = ++eptr;
                    }
                    else
                    {
                        sprintf(msgbuf,
                                "%s packet: Missing end of Name quote\n",
                                plabel);
                        logMsg(LEVEL1, msgbuf);
                        *name = "BADNAME";
                    }
                }
                else
                {
                    /* NAME may not be in quotes */
                    *name = sptr + strlen(llabel) + 1;
                    if (**name != '<')
                    {
                        for (eptr=*name; !isspace((int) *eptr); ++eptr);
                        *eptr = '\0';
                        sptr = ++eptr;
                    }
                    else *name = "NONAME";
                }
            }

            /* Look for calling number */
            if ((sptr = strstr(sptr, SIPNUM)))
            {
                if ((eptr = index(sptr, (int) SIPAT)))
                {
                    *eptr = '\0';
                    *number = sptr + strlen(SIPNUM);;
                }
                else
                {
                    sprintf(msgbuf, "%s packet: %s Number Bad\n",
                            plabel, llabel);
                    logMsg(LEVEL1, msgbuf);
                    *number = "BADNUMBER";
                }
            }
            /* No calling number in packet */
            else *number = "NONUMBER";

        }
        else
        {
            /* should not happen */
            sprintf(msgbuf, "%s packet: %s line bad\n", plabel, llabel);
            logMsg(LEVEL1, msgbuf);
            ret = 1;
        }
    }
    else
    {
        /* should not happen */
        sprintf(msgbuf, "%s packet: %s line not found\n", plabel, llabel);
        logMsg(LEVEL1, msgbuf);
        ret = 1;
    }

return ret;
}

/*
 * Must match: <part_of_WORD><SPACE><NUMBER><SPACE><WORD>
 * Examples:
 *     CSeq: 20 REGISTER (match is CSEQ: and REGISTER)
 *     SIP/2.0 200 OK    (match is SIP/2 and OK)
 */

char *strmatch(char *strbuf, char *fword, char *eword)
{
    char *ptr;

    if ((ptr = strstr(strbuf, fword)))
    {
        /* skip over part of word matched */
        ptr += strlen(fword);
        /* skip over part of word not matched */
        while (isgraph((int) *ptr)) ++ptr;
        /* skip over space */
        if (isblank((int) *ptr)) ++ptr;
        if (isdigit((int) *ptr))
        {
            while (isdigit((int) *ptr)) ptr++;
            if (isblank((int) *ptr))
            {
                while (isblank((int) *ptr)) ptr++;
                if (strncmp(ptr, eword, strlen(eword)) == 0) return ptr;
            }
        }
    }

    return NULL;
}

/*
 * Get the unique Call-ID
 * return 0 if Call-ID not found
 * return 1 Call-ID found
 */
int getCallID(char *sipbuf, char *callid, int size, char *label)
{
    int len, ret = 0;
    char *sptr, *eptr;
    char msgbuf[BUFSIZ];

    if ((sptr = strstr(sipbuf, CALLID)))
    {
        /* using sizeof() will skip end space */
        sptr += sizeof(CALLID);
        if ((eptr = index(sptr, (int) NL)))
        {
            len = eptr - sptr;
            if (len < size)
                *(strncpy(callid, sptr, len) + len) = '\0';
            else
            {
                *(strncpy(callid, sptr, size -1) + size) = '\0';
                sprintf(msgbuf, "Warning: %s packet - %s truncated: %u > %u\n",
                        label, CALLID, len, size - 1);
                logMsg(LEVEL1, msgbuf);
            }
            ret = 1;
        }
    }
    if (!ret)
    {
        *callid = '\0';
        sprintf(msgbuf, "Warning: cannot get %s in %s\n", CALLID, label);
        logMsg(LEVEL1, msgbuf);
    }

    return ret;
}

/*
 * find the CallID in calls array
 * if found return position
 * if not found return -1
 */
int findCallID(char *callid)
{
    int pos;
    char msgbuf[BUFSIZ];

    for (pos = 0; pos < MAXCALL; ++pos)
    {
        if (calls[pos].callid && !strcmp(calls[pos].callid, callid))
        {
            /* found call in the calls in-progress table */
            sprintf(msgbuf, "found calls[%d]=%s\n", pos, calls[pos].callid);
            logMsg(LEVEL2, msgbuf);
            break;
        }
    }
    return (pos == MAXCALL ? -1 : pos);
}


/*
 * add the CallID, CallStart, and line label to calls array
 * if added return position
 * if not added return -1
 */
int addCallID(char *callid, char *line)
{
    int pos;
    char msgbuf[BUFSIZ];

    for (pos = 0; pos < MAXCALL; ++pos)
    {
        if (!calls[pos].callid)
        {
            /* add call to in-progress table */
            calls[pos].callid = strdup(callid);
            calls[pos].callstart = strdup(strdate(WITHYEAR));
            calls[pos].line = strdup(line);
            sprintf(msgbuf, "Added calls[%d].callid=%s\n", pos, callid);
            logMsg(LEVEL2, msgbuf);
            break;
        }
    }
    if (pos == MAXCALL)
    {
        /* in-progress table filled, call not added */
        sprintf(msgbuf, "%d simultaneous calls exceeded\n", pos);
        logMsg(LEVEL1, msgbuf);
        pos = -1;
    }
    return pos;
}

/*
 * Remove CallID, Call Start, and line label from calls array
 * if removed return position
 * if not removed return -1
 */
int rmCallID(char *callid)
{
    int pos;
    char msgbuf[BUFSIZ];

    for (pos = 0; pos < MAXCALL; ++pos)
    {
        if (calls[pos].callid && !strcmp(calls[pos].callid, callid))
        {
            sprintf(msgbuf, "Removed calls[%d]=%s\n", pos, calls[pos].callid);
            logMsg(LEVEL2, msgbuf);
            free(calls[pos].callid);
            free(calls[pos].callstart);
            free(calls[pos].line);
            calls[pos].callid = 0;
            break;
        }
    }
    return (pos == MAXCALL ? -1 : pos);
}

void doPCAP()
{
    int pcapret, retval;
    char errbuf[PCAP_ERRBUF_SIZE], msgbuf[BUFSIZ], filter_exp[BUFSIZ];
    char warnmsg[BUFSIZ];
    struct bpf_program fp;      /* hold compiled program     */
    bpf_u_int32 maskp;          /* subnet mask               */
    bpf_u_int32 netp;           /* ip                        */

    if (readfile)
    {
        /* open a dump file for reading */
        descr = pcap_open_offline(readfile, errbuf);
        if(descr == NULL) errorExit(-1, "pcap_open_offline()", errbuf);
    }
    else
    {
        /* grab a device to peak into... */
        if (!device) device = pcap_lookupdev(errbuf);
        if(device == NULL) errorExit(-1, "pcap_lookupdev()", errbuf);

        sprintf(msgbuf, "Network Interface: %s\n", device);
        logMsg(LEVEL1, msgbuf);

        /* ask pcap for the network address and mask of the device */
        pcap_lookupnet(device, &netp, &maskp, errbuf);

        /* open device for reading in promiscuous mode */
        descr = pcap_open_live(device, BUFSIZ, 1, PCAPWAIT, errbuf);
        if(descr == NULL) errorExit(-1, "pcap_open_live()", errbuf);

        /* make sure we're capturing on an Ethernet device [2] */
        if (pcap_datalink(descr) != DLT_EN10MB)
            errorExit(-1, device, "not an Ethernet device");

        if (writefile)
        {
            /* open a dump file for writing */
            dumpfile = pcap_dump_open(descr, writefile);
            if (dumpfile == NULL)
                errorExit(-1, "pcap_dump_open()", pcap_geterr(descr));
        }
    }

    /* do not apply filter if no filter is wanted or reading a dump file */
    if (!nofilter && !readfile)
    {
        /* create filter */
        if (siphost) sprintf(filter_exp, "host %s and ", siphost);
        else filter_exp[0] = '\0';
        sprintf(filter_exp + strlen(filter_exp), "port %d and udp", sipport);

        /* compile the filter expression */
        if (pcap_compile(descr, &fp, filter_exp, 0, netp) == -1)
            errorExit(-1, filter_exp, pcap_geterr(descr));

        /* apply the compiled filter */
        if (pcap_setfilter(descr, &fp) == -1)
            errorExit(-1, filter_exp, pcap_geterr(descr));

        sprintf(msgbuf, "Filter: %s\n", filter_exp);
        logMsg(LEVEL1, msgbuf);
    }
    else
    {
        sprintf(msgbuf, "No filter applied\n");
        logMsg(LEVEL1, msgbuf);
    }

    while (1)
    {
        alarm(PKTWAIT); /* set timer for SIP packet timeout */
        pcapret = pcap_loop(descr, -1, processPackets, (u_char *) dumpfile);

        /*
        * pcapret values
        *     #:  partial packet count
        *     0:  packet count reached
        *     -1: error
        *     -2: pcap_loop() terminated by pcap_breakloop()
        *
        * msgsent values
        *     0x0: no messages logged
        *     0x1: timeout message logged
        *     0x2: error message logged
        */
        sprintf(msgbuf,
                "Alarm Timeout: pcap_loop(): return = %d, msgsent flag = %d\n",
                pcapret, msgsent);
        logMsg(LEVEL4, msgbuf);
        if (msgsent ^ 0x3)
        {
            /* need to send either timeout or error message */
            if (pcapret == -2)
            {
                if ((msgsent & 0x1) == 0)
                {
                    /* log only one SIP packet timeout message */
                    sprintf(msgbuf,
                            "No SIP packets in %d seconds: port %d %s\n",
                            PKTWAIT, sipport, strdate(WITHYEAR));
                    logMsg(LEVEL1, msgbuf);
                    msgsent |= 0x1;
                    if (warn && sd)
                    {
                        /*
                        * send clients one warning message if warn option
                        * set and if connected to the NCID server
                        */
                        sprintf(warnmsg, "MSG: %s", msgbuf);
                        retval =  write(sd, warnmsg, strlen(warnmsg));
                    }
                }
            }
            else if (pcapret == -1)
            {
                /* It appears that errors from pcap_loop aren't recoverable */
                 errorExit(-1, "pcap_loop", 0);
            }
        }
    }
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

    /* close dumpfile if open for read or write */
    if (dumpfile) pcap_dump_close(dumpfile);
    if (descr) pcap_close(descr);

    if (test)
    {
        sprintf(msgbuf, "%s terminated\n",
                readfile ? "Dump read" : "Test mode");
        logMsg(LEVEL1, msgbuf);
    }
    else if (error != -100 && error != -101 && error != -107)
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

    if (sig == SIGALRM)
    {
        /*
         * signal to break out of pcap_loop()
         * to make sure packets are received
         */
        pcap_breakloop(descr);
    }
    else
    {
        /* termination signals */
        cleanup(0);

        /* allow signal to terminate the process */
        signal (sig, SIG_DFL);
        raise (sig);
    }
}

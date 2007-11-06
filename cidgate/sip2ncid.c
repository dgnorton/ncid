/*
 * sip2ncid - Inject CID info by snooping SIP invites
 *
 * Copyright 2007
 *  by John L. Chmielewski <jlc@users.sourceforge.net>
 *
 * This file is part of sip2ncid, a On Screen Display for the TiVo.
 * 
 * sip2ncid is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * sip2ncid is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 */

#include "sip2ncid.h"

/* globals */
int debug, listdevs, nofilter, test, sd;
int ncidport   = NCIDPORT;
int sipport    = SIPPORT;
int verbose    = 1;
char *pidfile  = PIDFILE;
char *ncidhost = LOCALHOST;
char *name, *siphost, *device, *readfile, *writefile;
pid_t pid;
FILE *logptr;
pcap_t *descr;
pcap_dumper_t *dumpfile;

int doPID(), getOptions(), pcapListDevs();
void cleanup(), doPCAP(), exitExit(), finish();
void errorExit(), socketConnect();
char *strdate(), *inet_ntoa();

int main(int argc, char *argv[])
{
    int argind;
    char msgbuf[BUFSIZ];

    /* global containing name of program */
    name = strrchr(argv[0], (int) '/');
    name = name ? name + 1 : argv[0];

    /* process options from the command line */
    argind = getOptions(argc, argv);

    if (listdevs)
    {
        pcapListDevs();
        exit(0);
    }

    sprintf(msgbuf, "Started: %s\nServer: %s %s\n",strdate(WITHYEAR),
            name, VERSION);
    logMsg(LEVEL1, msgbuf);

    /* look for test mode */
    if (test)
    {
        /* test mode is also debug mode */
        debug = 1;

        sprintf(msgbuf, "%s mode\n",
                readfile ? "Dump read" : "Test");
        logMsg(LEVEL1, msgbuf);
    }
    else if (debug)
    {
        sprintf(msgbuf, "Debug mode\n");
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

    signal(SIGHUP, finish);
    signal(SIGTERM, finish);
    signal(SIGINT, finish);
    signal(SIGQUIT, finish);

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
    int digit_optind = 0;
    int option_index = 0;
    char *ptr;
    static struct option long_options[] = {
        {"config", 1, 0, 'C'},
        {"debug", 0, 0, 'D'},
        {"dumpfile", 1, 0, 'd'},
        {"help", 0, 0, 'h'},
        {"interface", 1, 0, 'i'},
        {"listdevs", 0, 0, 'l'},
        {"ncid", 1, 0, 'n'},
        {"pidfile", 1, 0, 'P'},
        {"sip", 1, 0, 's'},
        {"testudp", 0, 0, 't'},
        {"testall", 0, 0, 'T'},
        {"verbose", 1, 0, 'v'},
        {"version", 0, 0, 'V'},
        {0, 0, 0, 0}
    };

    while ((c = getopt_long (argc, argv, "hi:ln:r:s:tv:w:C:DP:TV",
        long_options, &option_index)) != -1)
    {
        switch (c)
        {
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
                if (ptr = index(optarg, (int) ':'))
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
                if (ptr = index(optarg, (int) ':'))
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
            case '?': /* bad option */
                fprintf(stderr, USAGE, name);
                exit(-100);
        }
    }
    return optind;
}

/*
 * Returns the current date and time as a string in the format:
 *      With a year:    MM/DD/YYYY HH:MM
 *      Without a year: MMDDHHMM
 */
char *strdate(int withyear)
{
    static char buf[BUFSIZ];
    struct tm *tm;
    struct timeval tv;

    (void) gettimeofday(&tv, 0);
    tm = localtime((const time_t *)&(tv.tv_sec));
    if (withyear)
        sprintf(buf, "%.2d/%.2d/%.4d %.2d:%.2d", tm->tm_mon + 1, tm->tm_mday,
                tm->tm_year + 1900, tm->tm_hour, tm->tm_min);
    else
        sprintf(buf, "%.2d%.2d%.2d%.2d", tm->tm_mon + 1,
                tm->tm_mday, tm->tm_hour, tm->tm_min);
    return buf;
}

/*
 * if PID file exists, and PID in process table, ERROR
 * if PID file exists, and PID not in process table, replace PID file
 * if no PID file, write one
 * if write a pidfile failed, OK
 */
int doPID()
{
    struct stat statbuf;
    char msgbuf[BUFSIZ];
    FILE *pidptr;
    pid_t curpid, foundpid = 0;
    int ret = 0;

    /* check PID file */
    curpid = getpid();
    if (stat(pidfile, &statbuf) == 0)
    {
        if ((pidptr = fopen(pidfile, "r")) == NULL) return(1);
        fscanf(pidptr, "%u", &foundpid);
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
	struct sockaddr_in sin;
	struct sockaddr_in pin;
	struct hostent *hp;

	/* go find out about the desired host machine */
	if ((hp = gethostbyname(ncidhost)) == 0)
        errorExit(-1, "gethostbyname", strerror(h_errno));

	/* fill in the socket structure with host information */
	memset(&pin, 0, sizeof(pin));
	pin.sin_family = AF_INET;
	pin.sin_addr.s_addr = ((struct in_addr *)(hp->h_addr))->s_addr;
	pin.sin_port = htons(ncidport);

	/* grab an Internet domain socket */
	if ((sd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
        errorExit(-1, "socket", 0);

	/* connect to PORT on HOST */
	if (connect(sd, (struct sockaddr *) &pin, sizeof(pin)) == -1)
    {
        if (fatal) errorExit(-1, "NCID server", 0);
        sprintf(msgbuf, "Warning: could not connect to the NCID server\n");
        logMsg(LEVEL1, msgbuf);
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
        logMsg(LEVEL3, msgbuf);
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
        while (ptr = index(alldevsp->name, (int) '\\')) *ptr = '/';

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
    static int count = 1;                  /* packet counter */
    static int linecnt;
    static char *linenum[MAXLINENUM];

    /* declare pointers to packet headers */
    const struct ip *ip;                   /* IP Header */
    const struct udphdr *udp;              /* UDP Header */
    const char   *pdata;                   /* Packet Data */

    int size_ip, size_udp, size_pdata;

    char msgbuf[BUFSIZ], cidmsg[BUFSIZ];
    char *sptr, *eptr, *elptr, *line, *number, *name;

    struct tm *tm;
    struct timeval tv;

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
        if (!socketRead())
        {
            close(sd);
            sd = 0;
        }
    }

    /* write packet to dumpfile */
    if (writefile) pcap_dump(args, pkthdr, packet);

    /* if no open socket, and not in test mode, try to connect again */
    if (!sd && !test) socketConnect(NONFATAL);

    sprintf(msgbuf, "Packet number %d:\n", count);
    logMsg(LEVEL2, msgbuf);
    count++;

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
        strncpy(msgbuf, pdata, size_pdata);
        msgbuf[size_pdata] = '\0';
        logMsg(LEVEL3, msgbuf);

        /* Look for the INVITE packet */
        if (!strncmp(msgbuf, PKTINV, strlen(PKTINV)))
        {
            /*
             * Look for Caller ID information
             *  From: [["]NAME["]] <sip:CALLING_NMBR@IP_ADDRESS>;tag=TAG_NUMBER
             *  To: <sip:CALLED_NMBR@IP_Address>
             */
            if (sptr = strstr(msgbuf, FROM))
            {
                /* look for end of line and terminate line */
                if (elptr = index(sptr, (int) ENDLINE))
                {
                    *elptr = '\0';

                    /* Look for NAME in quotes */
                    if (name = index(sptr, (int) QUOTE))
                    {
                        if (eptr = index(++name, (int) QUOTE))
                        {
                            *eptr = '\0';
                            sptr = ++eptr;
                        }
                    }
                    else
                    {
                        /* NAME may not be in quotes */
                        name = sptr + strlen(FROM) +1;
                        if (*name != '<' && !isspace((int) *sptr))
                        {
                            for (eptr=name; !isspace((int) *eptr); ++eptr);
                            *eptr = '\0';
                            sptr = ++eptr;
                        }
                        else name = "NO NAME";
                    }

                    /* Look for number */
                    if (sptr = strstr(sptr, SIPNUM))
                    {
                        eptr = index(sptr, (int) SIPAT);
                        *eptr = '\0';
                        number = sptr + strlen(SIPNUM);;
                        sptr = ++elptr;
                    }
                    else number = "NO NUMBER";

                    /* if number is the line number, it is a outgoing call */
                    for (linecnt = 0; linenum[linecnt]; ++linecnt)
                    {
                        if (!strcmp(linenum[linecnt], number)) return;
                    }

                    /* look for end of line and terminate line */
                    if (elptr = index(sptr, ENDLINE)) *elptr = '\0';

                    /* Look for line identifier (last 4 digits) */
                    if (sptr = strstr(sptr, TO))
                    {
                        eptr = index(sptr, (int) SIPAT);
                        *eptr++ = '\0';
                        line = eptr - 5;
                    }
                    else line = "UNKNOWN";

                    /* form and send NCID CID message line */
                    sprintf(cidmsg, CIDLINE, strdate(NOYEAR),
                            line, number, name);
                    if (sd) write(sd, cidmsg, strlen(cidmsg));
                    logMsg(LEVEL1, cidmsg);
                }
                else
                {
                    sprintf(msgbuf, "INVITE packet seems bad\n");
                    logMsg(LEVEL3, cidmsg);
                }
            }
        }

        /*
         * Look for the CANCEL packet
         *  To: <sip:NUMBER_CALLED@IP_ADDRESS>
         */
        else if (!strncmp(msgbuf, PKTCAN, strlen(PKTCAN)))
        {
            /* Caller hung up */
            if (sptr = strstr(msgbuf, TO))
            {
                if (sptr = strstr(msgbuf, SIPNUM))
                {
                    sptr += strlen(SIPNUM);
                    if ((eptr = index(sptr, SIPAT)))
                    {
                        *eptr = '\0';
                        sprintf(cidmsg, CIDCAN, sptr, strdate(NOYEAR));
                        if (sd) write(sd, cidmsg, strlen(cidmsg));
                        logMsg(LEVEL1, cidmsg);
                    }
                }
            }
        }

        /* Look for the SIP/ packet */
        else if (!strncmp(msgbuf, PKTSIP, strlen(PKTSIP)))
        {
            /*
             * Look for REGISTER
             *  Contact: [["]NAME["]] <sip:TEL_NMBR@IP_ADDR:PORT>;expires=TIME
             */
            if (sptr = strstr(msgbuf, CSEQREG))
            {
                /* look for the line phone number */
                if (sptr = strstr(sptr, SIPNUM))
                {
                    sptr += strlen(SIPNUM);
                    eptr = index(sptr, (int) SIPAT);
                    *eptr = '\0';

                    /* add phone number if not seen before */
                    for (linecnt = 0; linenum[linecnt]; ++linecnt)
                        if (!strcmp(linenum[linecnt], sptr)) break;
                    if (!linenum[linecnt] && linecnt < MAXLINENUM - 1)
                    {
                        linenum[linecnt] = strdup(sptr);
                        sprintf(cidmsg, "%s: %s\n", REGLINE, sptr);
                        logMsg(LEVEL1, cidmsg);
                    }
                }
            }
            /*
             * Look for BYE
             *  To: [["]NAME["]] <sip:CALLING_NMBR@IP_ADDRESS>;tag=TAG_NUMBER
             */
            else if (sptr = strstr(msgbuf, CSEQBYE))
            {
                /* call terminated */
                if (sptr = strstr(msgbuf, TO))
                {
                    if (sptr = strstr(msgbuf, SIPNUM))
                    {
                        sptr += strlen(SIPNUM);
                        if ((eptr = index(sptr, SIPAT)))
                        {
                            *eptr = '\0';
                            sprintf(cidmsg, CIDBYE, sptr, strdate(NOYEAR));
                            if (sd) write(sd, cidmsg, strlen(cidmsg));
                            logMsg(LEVEL1, cidmsg);
                        }
                    }
                }
            }
        }
    }

    return;
}

void doPCAP()
{
    int i;
    char errbuf[PCAP_ERRBUF_SIZE], msgbuf[BUFSIZ], filter_exp[BUFSIZ];
    const u_char *packet;
    struct pcap_pkthdr hdr;     /* pcap.h                    */
    struct ether_header *eptr;  /* net/ethernet.h            */
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
        descr = pcap_open_live(device, BUFSIZ, 1, -1, errbuf);
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

    pcap_loop(descr, -1, processPackets, (u_char *) dumpfile);
}

/*
 * log messages, and print messages in debug mode
 */
void logMsg(int level, char *message)
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

/* signal exit */
void finish(int sig)
{
    cleanup(0);

    /* allow signal to terminate the process */
    signal (sig, SIG_DFL);
    raise (sig);
}

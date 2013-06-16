/*
 * nciddhangup.c - This file is part of ncidd.
 *
 * Copyright (c) 2005-2013
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
char *blacklist = BLACKLIST, *blklist[LISTSIZE];
char *whitelist = WHITELIST, *whtlist[LISTSIZE];

int doList(), nextEntry(), onList(), hangupCall(), doHangup();

void addEntry(), rmEntries();

#ifndef __CYGWIN__
    extern char *strsignal();
#endif

/*
 * Process the blacklist or whitelist file
 * Returns: 0 - no errors
 *          # of errors
 */
int doList(char *filename, char **list)
{
    char input[BUFSIZ], word[BUFSIZ], msgbuf[BUFSIZ], *inptr;
    int lc, i;
    FILE *fp;

    if ((fp = fopen(filename, "r")) == NULL)
    {
        sprintf(msgbuf, "%s file missing: %s\n",
                blklist == list ? "Blacklist" : "Whitelist", filename);
        logMsg(LEVEL1, msgbuf);
        return 1;
    }

    /* read each line of file, one line at a time */
    for (lc = 1; fgets(input, BUFSIZ, fp) != NULL; lc++)
    {
        inptr = getWord(input, word, lc);

        /* line containing only <NL> or is a comment line*/
        if (inptr == 0 || word[0] == '#') continue;

        /* get search strings on line */
        addEntry(inptr, word, lc, list);
    }
    (void) fclose(fp);
    sprintf(msgbuf, "Processed %s file: %s\n",
            blklist == list ? "blacklist" : "whitelist", filename);
    logMsg(LEVEL1, msgbuf);

    if (!errorStatus && list[0])
    {
        for (i = 0; i < LISTSIZE && list[i]; ++i);
        sprintf(msgbuf, "%s Entries: %d/%d\n",
                blklist == list ? "Blacklist" : "Whitelist", i, LISTSIZE);
        logMsg(LEVEL1, msgbuf);

        for (i = 0; i < LISTSIZE && list[i]; ++i)
        {
            sprintf(msgbuf, " %.2d \"%s\"\n", i, list[i]);
            logMsg(LEVEL8, msgbuf);
        }
    }

    return errorStatus;
}

/* Process blacklist or whitelist file lines */
void addEntry(char *inptr, char *wdptr, int lc, char **list)
{
    int cnt;
    char *mem = 0;

    /* process the blacklist or whitelist words */
    do
    {
        if (*wdptr == '#')    break; /* rest of line is comment */
        if ((cnt = nextEntry(lc, list)) < 0) return;
        mem = cpy2mem(wdptr, mem);
        list[cnt] = mem;
        
    }
    while ((inptr = getWord(inptr, wdptr, lc)) != 0);
}

int nextEntry(int lc, char **list)
{
    int i;

    for (i = 0; i < LISTSIZE && list[i]; ++i);
    if (i == LISTSIZE)
    {
        configError(blklist == list ? blacklist : whitelist, lc, " ", ERRLIST);
        return -1;
    }
    return i;
}

void rmEntries(char **list)
{
    int i;

    for (i = 0; i < LISTSIZE; ++i)
    {
        if (list[i])
        {
            free(list[i]);
            list[i] = 0;
        }    
    }
}

/*
 * Check if call is in blacklist file
 *
 * Hangup phone if match in blacklist file
 * but no match in whitelist file
 *
 * return = 0 if call not terminated
 * return = 1 if call terminated
 */

int doHangup(char *namep, char *nmbrp)
{
    if (onList(namep, nmbrp, blklist))
    {
        if (!onList(namep, nmbrp, whtlist))
        {
            /* a blacklist match must not also be a whitelist match */
            if (!hangupCall()) return 1;
        }
    }

return 0;
}

/*
 * Hangup Call
 * return = 0  success
 * return != 0 error
 */
int hangupCall()
{
    int ret = 0, ttyflag = 0;
    char msgbuf[BUFSIZ];
    FILE *lockptr;

    /* if lockfile present, nothing to do */
    if (CheckForLockfile()) return 1;

    /* Create TTY port lockfile */
    if ((lockptr = fopen(lockfile, "w")) == NULL)
    {
        sprintf(msgbuf, "%s: %s\n", lockfile, strerror(errno));
        logMsg(LEVEL1, msgbuf);
        return 1;
    }
    else
    {
        /* write process number to lockfile */
        fprintf(lockptr, "%d\n", getpid());

        fclose(lockptr);
    }

    /*
     * if modem not used, open port and initialize it
     */
    if (!ttyfd)
    {
        ttyflag = 1;
        if ((ttyfd = open(ttyport, O_RDWR | O_NOCTTY | O_NDELAY)) < 0)
        {
            sprintf(msgbuf, "Modem: %s\n", strerror(errno));
            logMsg(LEVEL1, msgbuf);
            ret = ttyfd;
            ttyfd = 0;
        }
        else if (ret = fcntl(ttyfd, F_SETFL, fcntl(ttyfd, F_GETFL, 0)
                 & ~O_NDELAY) < 0)
        {
            sprintf(msgbuf, "Modem: %s\n", strerror(errno));
            logMsg(LEVEL1, msgbuf);
        }
        else
            ret = doTTY();
    }

    if (!ret)
    {
        /* put tty port in raw mode */
        if (!(ret = tcsetattr(ttyfd, TCSANOW, &rtty) < 0))
        {
            /* Send AT to get modem OK after switch to raw mode */
            (void) initModem("AT", HANGUPTRY);

            /* Pick up the call */
            ret = initModem(PICKUP, HANGUPTRY);
            if (ret == 0)
            {
                /*
                 * HANGUP only if PICKUP was successful
                 *
                 * delay while off-hook to make sure to hangup call
                 */
                usleep(HANGUPDELAY);
                sprintf(msgbuf, "off-hook for %d microseconds\n", HANGUPDELAY);
                logMsg(LEVEL3, msgbuf);

                /* Hangup up the call */
                ret = initModem(HANGUP, HANGUPTRY);
            }

            /* take tty port out of raw mode */
            (void) tcsetattr(ttyfd, TCSAFLUSH, &ntty);
        }
    }

    if (ttyflag)
    {
        (void) close(ttyfd);
        ttyfd = 0;
    }

    /* remove TTY port lockfile */
    if (unlink(lockfile))
    {
        sprintf(msgbuf, "Failed to remove stale lockfile: %s\n", lockfile);
        logMsg(LEVEL1, msgbuf);
    }

return ret;
}

/*
 * compare blacklist or whitelist strings to name and number
 *
 * return = 1  if match
 * return = 0  if no match
 */
int onList(char *namep, char *nmbrp, char **list)
{
    int ret = 1, i;
	char msgbuf[BUFSIZ], *ptr;

    for (i = 0; list[i] && i < LISTSIZE; ++i)
    {
        if (*list[i] == '^')
        {
            /* must match at start of string */
            ptr = list[i], ++ptr;
            if (!(ret = strncmp(ptr, namep, strlen(ptr)))) break;
            if (!(ret = strncmp(ptr, nmbrp, strlen(ptr)))) break;
        }
        else
        {
            /* can match anywhere in string */
            if (strstr(namep, list[i])) { ret = 0; break; }
            if (strstr(nmbrp, list[i])) { ret = 0; break; }
        }
    }

    if (!ret)
    {
        sprintf(msgbuf, "%s Match #%.2d: %s    number: %s    name: %s\n",
                blklist == list ? "Blacklist" : "Whitelist",
                i, list[i], nmbrp, namep);
        logMsg(LEVEL3, msgbuf);
    }

    return !ret;
}

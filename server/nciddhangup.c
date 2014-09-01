/*
 * nciddhangup.c - This file is part of ncidd.
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
int pickup = 1;
char *blacklist = BLACKLIST;
char *whitelist = WHITELIST;
struct list *blkHead = NULL, *blkCurrent = NULL,
            *whtHead = NULL, *whtCurrent = NULL;

int doList(), onList(), hangupCall(), doHangup(), onBlackWhite();

void addEntry(), nextEntry(), rmEntries();

#ifndef __CYGWIN__
    extern char *strsignal();
#endif

/*
 * Process the blacklist or whitelist file
 * Returns: 0 - no errors
 *          # of errors
 */
int doList(char *filename, list_t **listHead, list_t **listCurrent)
{
    char input[BUFSIZ], word[BUFSIZ], msgbuf[BUFSIZ], *inptr;
    struct list *node, *nextnode;
    int lc, i, bl;
    FILE *fp;

    bl = !strcmp(blacklist, filename) ? 1 : 0;

    if ((fp = fopen(filename, "r")) == NULL)
    {
        sprintf(msgbuf, "%s file missing: %s\n",
            bl ? "Blacklist" : "Whitelist", filename);
        logMsg(LEVEL1, msgbuf);
        return 1;
    }
    fnptr = filename;

    /* read each line of file, one line at a time */
    for (lc = 1; fgets(input, BUFSIZ, fp) != NULL; lc++)
    {
        inptr = getWord(fnptr, input, word, lc);

        /* line containing only <NL> or is a comment line*/
        if (inptr == 0 || word[0] == '#') continue;

        /* get search strings on line */
        addEntry(inptr, word, lc, listHead, listCurrent);
    }
    (void) fclose(fp);
    sprintf(msgbuf, "Processed %s file: %s\n",
            bl ? "blacklist" : "whitelist", filename);
    logMsg(LEVEL1, msgbuf);

    sprintf(msgbuf, "%s Table:\n", bl ? "Blacklist" : "Whitelist");
    logMsg(LEVEL1, msgbuf);

    if (!errorStatus && *listHead)
    {
        node = *listHead;
        for (i = 0; node != NULL; i++)
        {
            nextnode = node->next;
            node = nextnode;
        }

        sprintf(msgbuf, "    Number of Entries: %d\n", i);
        logMsg(LEVEL1, msgbuf);

        sprintf(msgbuf, "    SLOT ENTRY\n    ---- -----\n");
        logMsg(LEVEL8, msgbuf);

        node = *listHead;
        for (i = 0; node != NULL; i++)
        {
            nextnode = node->next;
            sprintf(msgbuf, "    %-4.3d \"%s\"\n", i, node->entry);
            logMsg(LEVEL8, msgbuf);
            node = nextnode;
        }
    }
    else
    {
        sprintf(msgbuf, "    Number of Entries: 0\n");
        logMsg(LEVEL1, msgbuf);
    }

    return errorStatus;
}

/*
 * Process blacklist or whitelist file lines
 */
void addEntry(char *inptr, char *wdptr, int lc, list_t
              **listHead, list_t **listCurrent)
{
    /* process the blacklist or whitelist words */
    do
    {
        if (*wdptr == '#')    break; /* rest of line is comment */
        nextEntry(listHead, listCurrent);
        if (strlen(wdptr) > ENTRYSIZE)
            configError(cidalias, lc, wdptr, ERRLONG);
        strcpy((*listCurrent)->entry, wdptr);
    }
    while ((inptr = getWord(fnptr, inptr, wdptr, lc)) != 0);
}

/*
 * Adds a node to the list for a new entry
 */
void nextEntry(list_t **listHead, list_t **listCurrent)
{
    list_t *node;

    if (!(node = (list_t *) malloc(sizeof(list_t)))) errorExit(-1, name, 0);
    node->next = NULL;
    if (*listHead == NULL) *listHead = node;
    else (*listCurrent)->next = node;
    *listCurrent = node;
}

/*
 * Frees all list nodes
 */
void rmEntries(list_t **listHead, list_t **listCurrent)
{
    struct list *node = *listHead;
    struct list *nextnode;

    while (node != NULL)
    {
        nextnode = node->next;
        free(node);
        node = nextnode;
    }

    *listHead = NULL;
    *listCurrent = NULL;
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
    int ret;

    /* a blacklist match must never be on the whitelist */
    if (!onList(namep, nmbrp, 0, &whtHead))
    {
        /* no whitelist match */

        if (onList(namep, nmbrp, 0, &blkHead))
        {
            /* blacklist match */

            /* try to hangup a call */
            ret = hangupCall();

            /* normal hangup, return must be 0 */
            if (!ret) return 1;
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
    unsigned int hangupdelay;
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
        else if ((ret = fcntl(ttyfd, F_SETFL, fcntl(ttyfd, F_GETFL, 0)
                 & ~O_NDELAY)) < 0)
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
           (void) initModem(GETOK, HANGUPTRY);

            if (hangup == 1)    /* hangup mode */
            {
                /* Pick up the call */
                ret = initModem(PICKUP, HANGUPTRY);
                sprintf(msgbuf, "hangup mode %d: PICKUP sent, return code is %d\n",hangup,ret);
                logMsg(LEVEL5, msgbuf);

                /* set off-hook delay to make sure to hangup call */
                hangupdelay = HANGUPDELAY;
            }
            else    /* FAX hangup mode */
            {
                /* Set FAX mode */
                ret = initModem(FAXMODE, HANGUPTRY);
                sprintf(msgbuf, "hangup mode %d: FAXMODE sent, return code is %d\n",hangup,ret);
                logMsg(LEVEL5, msgbuf);

                if (pickup)
                {
                    /* PICKUP required for some (mostly USB) modems */
                    ret = initModem(PICKUP, HANGUPTRY);
                    sprintf(msgbuf, "hangup mode %d: PICKUP sent, return code is %d\n",hangup,ret);
                    logMsg(LEVEL5, msgbuf);
                }

                /* generate FAX tones */
                ret = initModem(FAXANS, HANGUPTRY);
                sprintf(msgbuf, "hangup mode %d: FAXANS sent, return code is %d\n",hangup,ret);
                logMsg(LEVEL5, msgbuf);

                /* set off-hook delay so caller hears annoying fax tones */
                hangupdelay = FAXDELAY;
            }

            /* off-hook delay for all hangup modes */
            usleep(hangupdelay * 1000000);
            sprintf(msgbuf, "off-hook for %d %s\n", hangupdelay, hangupdelay == 1 ? "second" : "seconds");
            logMsg(LEVEL3, msgbuf);

            if (hangup == 2)    /* FAX hangup mode */
            {
                /* set voice mode */
                ret = initModem(DATAMODE, HANGUPTRY);
                sprintf(msgbuf, "hangup mode %d: DATAMODE sent, return code is %d\n", hangup, ret);
                logMsg(LEVEL5, msgbuf);
            }

            /* Hangup the call */
            ret = initModem(HANGUP, HANGUPTRY);
                sprintf(msgbuf, "hangup mode %d: HANGUP sent, return code is %d\n", hangup, ret);
                logMsg(LEVEL5, msgbuf);

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
 * Compare blacklist or whitelist strings to name and number
 *
 * If "flag" is zero, log a match message
 *   Return = 1  if the number or matches
 *   Return = 0  if no match
 *
 * If "flag" is one, never log a match message
 *   Return = 3  if the number matches
 *   Return = 1  if the name matches
 *   Return = 0  if no match
 */
int onList(char *namep, char *nmbrp, int flag, list_t **listHead)
{
    int ret = 0, i, nbrMatch = 0;
	char msgbuf[BUFSIZ], *ptr;
    list_t *node, *nextnode;

    node = *listHead;
    for (i = 0; node != 0; i++)
    {
        nextnode = node->next;
        if (node->entry[0] == '^')
        {
            /* must match at start of string */
            ptr = node->entry, ++ptr;
            if (!strncmp(ptr, namep, strlen(ptr))) { ret = 1; break; }
            if (!strncmp(ptr, nmbrp, strlen(ptr))) { ret = 1, nbrMatch = 2; break; }
        }
        else
        {
            /* can match anywhere in string */
            if (strstr(namep, node->entry)) { ret = 1; break; }
            if (strstr(nmbrp, node->entry)) { ret = 1, nbrMatch = 2; break; }
        }
        node = nextnode;
    }

    if (flag) return (ret + nbrMatch);
    if (ret > 0)
    {
        sprintf(msgbuf, "%s Match #%.2d: %s    number: %s    name: %s\n",
                blkHead == *listHead ? "Blacklist" : "Whitelist",
                i, node->entry, nmbrp, namep);
        logMsg(LEVEL3, msgbuf);
    }

    return ret;
}

/*
 * Check for a name or a number being in the black or white list
 *
 * Return = 0  not on either list
 * Return = 1  name is on the blacklist and not on the whitelist
 * Return = 5  number is on the blacklist and not on the whitelist
 * Return = 2  name is on the whitelist; may or may not be on the blacklist
 * Return = 6  number is on the whitelist; may or may not be on the blacklist
 *
 * Bits 0 and 1:
 *      0 - On neither list
 *      1 - Name or number on blacklist
 *      2 - Name or number on whitelist
 *
 * Bit 2:
 *      0 - Name is on the list
 *      1 - Number is on the list
 */
int onBlackWhite (char *namep, char *nmbrp)
{
    int ret;

    /* ret will be either 0, 1, or 3 */
    if ((ret = onList(namep, nmbrp, 1, &whtHead))) return 2 * ret;
    if ((ret = onList(namep, nmbrp, 1, &blkHead))) return 2 * ret - 1;
    return 0;
}

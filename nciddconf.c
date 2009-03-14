/*
 * Copyright (c) 2002, 2003, 2004, 2005, 2006, 2007, 2009
 * by  John L. Chmielewski <jlc@users.sourceforge.net>
 *
 * nciddconf.c is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * nciddconf.c is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 */

#include "ncidd.h"

int errorStatus;
char *cidconf = CIDCONF;
char *getWord();
int doset();
void doSend(), configError(), doSet();

struct setword setword[] = {
    /* char *word; int type; char **buf; int *value; int min; int max */
    {"cidalias",   WORDSTR,            &cidalias, 0,         0,    0},
    {"cidlog",     WORDSTR,            &cidlog,   0,         0,    0},
    {"cidlogmax",  WORDNUM,            0,         (int *) &cidlogmax,1,    LOGMAXNUM},
    {"datalog",    WORDSTR,            &datalog,  0,         0,    0},
    {"lineid",     WORDSTR,            &lineid,   0,         0,    0},
    {"initcid",    WORDSTR | WORDFLAG, &initcid,  &setcid,   0,    0},
    {"initstr",    WORDSTR,            &initstr,  0,         0,    0},
    {"lockfile",   WORDSTR,            &lockfile, 0,         0,    0},
    {"nomodem",    WORDNUM,            0,         &nomodem,  OFF, ON},
    {"noserial",   WORDNUM,            0,         &noserial, OFF, ON},
    {"pidfile",    WORDSTR,            &pidfile,  0,         0,    0},
    {"port",       WORDNUM,            0,         &port,     0,    0},
    {"ttyclocal",  WORDNUM,            0,         &clocal,   OFF, ON},
    {"ttyport",    WORDSTR,            &ttyport,  0,         0,    0},
    {"ttyspeed",   WORDSTR,            &TTYspeed, 0,         0,    0},
    {"verbose",    WORDNUM,            0,         &verbose,  1,    MAXLEVEL},
    {0,            0,                  0,         0,         0,    0}
};

struct sendclient sendclient[] = {
    {"cidlog",   &sendlog},
    {"cidinfo",  &sendinfo},
    {0,           0}
};

/*
 * Process the config file.
 */

int doConf()
{
    char input[BUFSIZ], word[BUFSIZ], buf[BUFSIZ], *inptr;
    int lc;
    FILE *fp;

    if ((fp = fopen(cidconf, "r")) == NULL)
    {
        sprintf(buf, "No config file: %s\n", cidconf);
        logMsg(LEVEL1, buf);
        return 0;
    }

    /* read each line of file, one line at a time */
    for (lc = 1; fgets(input, BUFSIZ, fp) != NULL; lc++)
    {
        inptr = getWord(input, word, lc);

        /* line containing only <NL> or is a comment line*/
        if (inptr == 0 || word[0] == '#') continue;

        /* first word on line must be either "set", or "send" */
        if (!strcmp(word, "set")) doSet(inptr, lc);
        else if (!strcmp(word, "send")) doSend(inptr, lc);
        else configError(cidconf, lc, word, ERRCMD);
    }
    (void) fclose(fp);
    sprintf(buf, "Processed config file: %s\n", cidconf);
    logMsg(LEVEL1, buf);

    return errorStatus;
}

/*
 * process set lines:
 *        set word = value
 */

void doSet(char *inptr, int lc)
{
    int num;
    char word[BUFSIZ], buf[BUFSIZ];

    /* process configuration parameters */
    while ((inptr = getWord(inptr, word, lc)))
    {
        if (word[0] == '#')    break; /* rest of line is comment */

        if ((num = findWord(word)) < 0)
        {
            configError(cidconf, lc, word, ERRWORD);
            break;
        }
        if (setword[num].type == WORDFLAG)
        {
            ++(*setword[num].value);
            break;
        }

        if (!(inptr = getWord(inptr, word, lc)))
        {
            configError(cidconf, lc, word, ERREQA);
            break;
        }

        if (word[0] != '=')
        {
            configError(cidconf, lc, word, ERREQB);
            break;
        }

        if (!(inptr = getWord(inptr, word, lc)))
        {
            configError(cidconf, lc, word, ERRARG);
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
                    configError(cidconf, lc, word, ERRNUM);

                /* min is always tested, even if 0, max is not, if 0 */
                if ((*setword[num].value < setword[num].min) ||
                        (setword[num].max &&
                        *setword[num].value > setword[num].max))
                    configError(cidconf, lc, word, ERRNUM);
            }
        }
        else
        {
            sprintf(buf, "Skipping: set %s    From config file: %s\n",
                setword[num].word, cidconf);
            logMsg(LEVEL1, buf);
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

/*
 * process send lines:
 *        send datatype [datatype] [...]
 */

void doSend(char *inptr, int lc)
{
    int num;
    char word[BUFSIZ];

    /* process configuration parameters */
    while ((inptr = getWord(inptr, word, lc)))
    {
        if (word[0] == '#')    break; /* rest of line is comment */

        if ((num = findSend(word)) < 0)
        {
            configError(cidconf, lc, word, ERRWORD);
            break;
        }

        ++(*sendclient[num].value);
    }
}

int findSend(char *wdptr)
{
    int i;

    for (i = 0; sendclient[i].word; i++)
        if (!strcmp(wdptr, sendclient[i].word)) return i;

    return -1;
}

void configError(char *file, int lc, char *word, char *mesg)
{
    char buf[BUFSIZ];

    if (*word == 0) return;
    sprintf(buf, "%s: Line %d; %s %s\n", file, lc, mesg, word);
    logMsg(LEVEL1, buf);
    ++errorStatus;
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
    if ((endptr = strchr(inptr, '\n')) != NULL) *endptr = 0;
    if (*inptr == 0) return 0;
    *wdptr = 0;

    if (*inptr == '"')
    {
        ++inptr;
        if ((endptr = strchr(inptr, '"')) == NULL)
        {
            configError(cidconf, lc, "\"", ERRMISS);
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

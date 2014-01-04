/*
 * config.c - This file is part of sip2ncid
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

int conferr;
char *config = CONFIG;

struct setword setword[] = {
   /* char *word; int type; char **buf; int *value; int min; int max */
   {"interface",  WORDSTR,  &device,    0,          0,       0},
   {"ncidhost",   WORDSTR,  &ncidhost,  0,          0,       0},
   {"ncidport",   WORDNUM,  0,          &ncidport,  0,       0},
   {"pidfile",    WORDSTR,  &pidfile,   0,          0,       0},
   {"siphost",    WORDSTR,  &siphost,   0,          0,       0},
   {"sipport",    WORDNUM,  0,          &sipport,   0,       0},
   {"verbose",    WORDNUM,  0,          &verbose,   1,       MAXLEVEL - 1},
   {"warn",       WORDNUM,  0,          &warn,      OFF,     ON},
   {"rmdups",     WORDNUM,  0,          &rmdups,    OFF,     ON},
   {0,            0,        0,          0,          0,       0}
};

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

void doSet(char *inptr, int lc)
{
    int num;
    char word[BUFSIZ], msgbuf[BUFSIZ];

    /* process configuration parameters */
    while ((inptr = getWord(inptr, word, lc)))
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

void configError(int lc, char *word, char *mesg)
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
    if ((endptr = strchr(inptr, '\n'))) *endptr = 0;
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

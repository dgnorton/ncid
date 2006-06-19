/*
 * Copyright (c) 2005, 2006
 * by John L. Chmielewski <jlc@users.sourceforge.net>
 *
 * nciddalias.c is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * nciddalias.c is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 */

#include "ncidd.h"

char *cidalias = CIDALIAS;
char *cpy2mem();

struct alias alias[ALIASSIZE];

extern int errorStatus, configError();
extern char *getWord();

/*
 * Process the alias file.
 */

doAlias()
{
    char input[BUFSIZ], word[BUFSIZ], buf[BUFSIZ], *inptr;
    int lc;
    FILE *fp;

    if ((fp = fopen(cidalias, "r")) == NULL)
    {
        sprintf(buf, "No alias file: %s\n", cidalias);
        logMsg(LEVEL1, buf);
        return 0;
    }

    /* read each line of file, one line at a time */
    for (lc = 1; fgets(input, BUFSIZ, fp) != NULL; lc++)
    {
        inptr = getWord(input, word, lc);

        /* line containing only <NL> or is a comment line*/
        if (inptr == 0 || word[0] == '#') continue;

        /* first word on line must be "alias" */
        if (!strcmp(word, "alias")) getAlias(inptr, lc);
        else configError(cidalias, lc, word, ERRCMD);
    }
    (void) fclose(fp);
    sprintf(buf, "Processed alias file: %s\n", cidalias);
    logMsg(LEVEL1, buf);

    return errorStatus;
}

/*
 * process alias lines:
 *        alias from = to
 *        alias NMBR from = to [if name_value]
 *        alias NAME from = to [if number_value]
 *        alias LINE from = to
 */

getAlias(char *inptr, int lc)
{
    char word[BUFSIZ];

    inptr = getWord(inptr, word, lc);

    if (word[0] == '#')    return; /* rest of line is comment */

    if (!strcmp(word, "NMBR")) setAlias(inptr, lc, word, NMBRONLY);
    else if (!strcmp(word, "NAME")) setAlias(inptr, lc, word, NAMEONLY);
    else if (!strcmp(word, "LINE")) setAlias(inptr, lc, word, LINEONLY);
    else setAlias(inptr, lc, word, NMBRNAME);
}

setAlias(char *inptr, int lc, char *wdptr, int type)
{
    int cnt;
    char *mem;

    if ((cnt = nextAlias(lc)) < 0) return 0;
    if (type == NMBRNAME || (inptr = getWord(inptr, wdptr, lc)))
    {
        mem = cpy2mem(wdptr, mem);
        alias[cnt].from = mem;
        if (inptr = getWord(inptr, wdptr, lc))
        {
            if (*wdptr == '=')
            {
                if ((inptr = getWord(inptr, wdptr, lc)))
                {
                    mem = cpy2mem(wdptr, mem);
                    alias[cnt].to = mem;
                    if (type == NMBRNAME) alias[cnt].type = type;
                    else
                    {
                        if (inptr = getWord(inptr, wdptr, lc))
                        {
                               if (strcmp(wdptr, "if"))
                                configError(cidalias, lc, wdptr, ERRIF);
                            else if (inptr = getWord(inptr, wdptr, lc))
                            {
                                mem = cpy2mem(wdptr, mem);
                                alias[cnt].depend = mem;
                                alias[cnt].type = type + 1;
                            }
                            else configError(cidalias, lc, wdptr, ERRARG);
                        }
                        else alias[cnt].type = type;
                    }
                }
                else configError(cidalias, lc, wdptr, ERRARG);
            }
            else configError(cidalias, lc, wdptr, ERREQB);
        }
        else configError(cidalias, lc, wdptr, ERREQA);
    }
    else configError(cidalias, lc, wdptr, ERRARG);
}

nextAlias(int lc)
{
    int i;

    for (i = 0; i < ALIASSIZE && alias[i].type; ++i);
    if (i == ALIASSIZE)
    {
        configError(cidalias, lc, " ", ERRALIAS);
        return -1;
    }
    return i;
}

char *cpy2mem(char *wdptr, char *memptr)
{
    if (!(memptr = (char *) malloc(strlen(wdptr) + 1)))
        errorExit(-1, name, 0);
    return strcpy(memptr, wdptr);
}

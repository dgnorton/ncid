/*
 * Copyright (c) 2005-2013
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

struct alias alias[ALIASSIZE];

extern int errorStatus;
extern char *getWord();

int doAlias(), nextAlias();
char *cpy2mem();
void builtinAlias(), userAlias(), getAlias(), setAlias(), rmaliases();

/*
 * Built-in Aliases for O, P, and A
 */

void builtinAlias(char *to, char *from)
{
    if (!strcmp(from, "O")) strncpy(to, O, CIDSIZE - 1);
    else if (!strcmp(from, "P")) strncpy(to, P, CIDSIZE - 1);
    else if (!strcmp(from, "A")) strncpy(to, A, CIDSIZE - 1);
    else strncpy(to, from, CIDSIZE - 1);
}

/*
 * User defined aliases.
 */

void userAlias(char *nmbr, char *name, char *line)
{
    int i;
    char *ptr;

    /* we may want to skip the leading 1, if present */
    if (ignore1 && *nmbr == '1') ++nmbr;

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
                {
                    strcpy(nmbr, alias[i].to);
                }
                break;
            case NAMEONLY:
                if (!strcmp(name, alias[i].from)) strcpy(name, alias[i].to);
                break;
            case NAMEDEP:
                ptr = alias[i].depend;
                if (*ptr == '^')
                {
                    ++ptr;
                    if (!strncmp(nmbr, ptr, strlen(ptr)) &&
                        (!strcmp(name, alias[i].from) ||
                        !strcmp(alias[i].from, "*")))
                    {
                        strcpy(name, alias[i].to);
                    }
                }
                else
                {
                    if (!strcmp(nmbr, ptr) &&
                        (!strcmp(name, alias[i].from) ||
                        !strcmp(alias[i].from, "*")))
                    {
                        strcpy(name, alias[i].to);
                    }
                }
                break;
            case LINEONLY:
                if (!strcmp(line, alias[i].from) ||
                   !strcmp(alias[i].from, "*")) strcpy(line, alias[i].to);
                break;
        }
    }
}

/*
 * Process the alias file.
 * Returns: 0 - no errors
 *          # of errors
 */

int doAlias()
{
    char input[BUFSIZ], word[BUFSIZ], msgbuf[BUFSIZ], *inptr;
    int lc, i;
    int max_temp = 0, max_type_txt = 0, max_from = 0, max_to = 0;
    FILE *fp;

    if ((fp = fopen(cidalias, "r")) == NULL)
    {
        sprintf(msgbuf, "No alias file: %s\n", cidalias);
        logMsg(LEVEL1, msgbuf);
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
    sprintf(msgbuf, "Processed alias file: %s\n", cidalias);
    logMsg(LEVEL1, msgbuf);

    if (!errorStatus && alias[0].type)
    {
	
	    for (i = 0; i < ALIASSIZE && alias[i].type; ++i);
        sprintf(msgbuf, "Alias Entries: %d/%d\n",
                i, ALIASSIZE);
        logMsg(LEVEL1, msgbuf);

        /*
         * Make the alias display pretty by determining maximum column
         * widths, and create human readable 'type'.
         */

        for (i = 0; i < ALIASSIZE && alias[i].type; ++i)
        {
            switch (alias[i].type)
            {
                case NMBRNAME:
                    alias[i].type_txt = NMBRNAME_TXT ;
                    break;

                case NMBRONLY:
                    alias[i].type_txt = NMBRONLY_TXT ;
                    break;

                case NMBRDEP:
                    alias[i].type_txt = NMBRDEP_TXT ;
                    break;

                case NAMEONLY:
                    alias[i].type_txt = NAMEONLY_TXT ;
                    break;

                case NAMEDEP:
                    alias[i].type_txt = NAMEDEP_TXT ;
                    break;

                case LINEONLY:
                    alias[i].type_txt = LINEONLY_TXT ;
                    break;

                default:
                    alias[i].type_txt = "UNKNOWN" ;
            }

            max_temp = strlen(alias[i].type_txt);
            if (max_temp > max_type_txt) max_type_txt=max_temp;

            max_temp = strlen(alias[i].from);
            if (max_temp > max_from) max_from=max_temp;

            max_temp = strlen(alias[i].to);
            if (max_temp > max_to) max_to=max_temp;

        }

        sprintf(msgbuf,
            "Alias Entries: ELEMENT TYPE \"FROM\" \"TO\" [\"DEPEND\"]\n");
        logMsg(LEVEL8, msgbuf);

        for (i = 0; i < ALIASSIZE && alias[i].type; ++i)
        {
            sprintf(msgbuf, " %.3d %.2d (%s)%-*s \"%s\"%-*s \"%s\"%-*s ",
                i,
                alias[i].type,
                alias[i].type_txt,
                max_type_txt - (int) strlen(alias[i].type_txt), "",
                alias[i].from,
                max_from - (int) strlen(alias[i].from), "",
                alias[i].to,
                max_to - (int) strlen(alias[i].to), "");

            if (alias[i].depend)
                strcat(strcat(strcat(msgbuf, "\""), alias[i].depend), "\"");
            strcat(msgbuf, NL);

            logMsg(LEVEL8, msgbuf);
        }
    }

    return errorStatus;
}

/*
 * process alias lines:
 *        alias from = to
 *        alias NMBR from = to [if name_value]
 *        alias NAME from = to [if number_value]
 *        alias LINE from = to
 */

void getAlias(char *inptr, int lc)
{
    char word[BUFSIZ];

    inptr = getWord(inptr, word, lc);

    if (word[0] == '#') return; /* rest of line is comment */

    if (!strcmp(word, "NMBR")) setAlias(inptr, lc, word, NMBRONLY);
    else if (!strcmp(word, "NAME")) setAlias(inptr, lc, word, NAMEONLY);
    else if (!strcmp(word, "LINE")) setAlias(inptr, lc, word, LINEONLY);
    else setAlias(inptr, lc, word, NMBRNAME);
}

void setAlias(char *inptr, int lc, char *wdptr, int type)
{
    int cnt;
    char *mem = 0;

    if ((cnt = nextAlias(lc)) < 0) return;
    if (type == NMBRNAME || (inptr = getWord(inptr, wdptr, lc)))
    {
        mem = cpy2mem(wdptr, mem);
        if (strlen(mem) > CIDSIZE) configError(cidalias, lc, wdptr, ERRLONG);
        alias[cnt].from = mem;
        if ((inptr = getWord(inptr, wdptr, lc)))
        {
            if (*wdptr == '=')
            {
                if ((inptr = getWord(inptr, wdptr, lc)))
                {
                    mem = cpy2mem(wdptr, mem);
                    if (strlen(mem) > CIDSIZE)
                        configError(cidalias, lc, wdptr, ERRLONG);
                    alias[cnt].to = mem;
                    if (type == NMBRNAME) alias[cnt].type = type;
                    else
                    {
                        if ((inptr = getWord(inptr, wdptr, lc)))
                        {
                               if (strcmp(wdptr, "if"))
                                configError(cidalias, lc, wdptr, ERRIF);
                            else if ((inptr = getWord(inptr, wdptr, lc)))
                            {
                                mem = cpy2mem(wdptr, mem);
                                if (strlen(mem) > CIDSIZE)
                                    configError(cidalias, lc, wdptr, ERRLONG);
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

int nextAlias(int lc)
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

void rmaliases()
{
    int i;

    for (i = 0; i < ALIASSIZE && alias[i].type; ++i)
    {
        alias[i].type = 0;
        if (alias[i].from) free(alias[i].from);
        if (alias[i].to) free(alias[i].to);
        if (alias[i].depend) free(alias[i].depend);
    }
}

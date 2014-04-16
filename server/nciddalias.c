/*
 * nciddalias.c - This file is part of ncidd.
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

char *cidalias = CIDALIAS;

struct alias alias[ALIASSIZE];

int doAlias(), nextAlias(), strmatch();
char *cpy2mem(), *findAlias();
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

    /* we may want to skip the leading 1, if present */
    if (ignore1 && *nmbr == '1') ++nmbr;

    for (i = 0; i < ALIASSIZE && alias[i].type; ++i)
    {
        switch (alias[i].type)
        {
            case NMBRNAME:
                if (strmatch(nmbr, alias[i].from)) strcpy(nmbr, alias[i].to);
                if (strmatch(name, alias[i].from)) strcpy(name, alias[i].to);
                break;
            case NMBRONLY:
                if (strmatch(nmbr, alias[i].from)) strcpy(nmbr, alias[i].to);
                break;
            case NMBRDEP:
                if (strmatch(name, alias[i].depend) && strmatch(nmbr, alias[i].from))
                {
                    strcpy(nmbr, alias[i].to);
                }
                break;
            case NAMEONLY:
                if (strmatch(name, alias[i].from)) strcpy(name, alias[i].to);
                break;
            case NAMEDEP:
                if (strmatch(nmbr, alias[i].depend) && strmatch(name, alias[i].from))
                {
                    strcpy(name, alias[i].to);
                }
                break;
            case LINEONLY:
                if (strmatch(line, alias[i].from)) strcpy(line, alias[i].to); 
                break;
        }
    }
}

/*
 * compare value to string with wildcards
 * ^ - at beginning: partial match from beginning
 * * - at beginning and/or end:  partial match
 *
 * returns: 0 = no match
 *          1 = match
 *          2 = only "*" or "?*" in value
 */

int strmatch(char *string, char *value)
{
    int result = 0, len;
    char *ptr;

    if (!strcmp(value, "*") || !strcmp(value, "?*"))
    {
        result = 2;
    }
    else
    {
        len = strlen(value);
        if (*value == '*')
        {
            ++value;
            if ((ptr = strchr(string, value[0])))
            {
                string = ptr;
                len = strlen(value);
            }
            else --len;
        }
        else if (*value == '^')
        {
            ++value;
            --len;
        }
        if (value[len -1] == '*') --len;
        result = !strncmp(string, value, len);
    }

return result;
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
        fnptr = cidalias;

    /* read each line of file, one line at a time */
    for (lc = 1; fgets(input, BUFSIZ, fp) != NULL; lc++)
    {
        inptr = getWord(fnptr, input, word, lc);

        /* line containing only <NL> or is a comment line*/
        if (inptr == 0 || word[0] == '#') continue;

        /* first word on line must be "alias" */
        if (!strcmp(word, "alias")) getAlias(inptr, lc);
        else configError(cidalias, lc, word, ERRCMD);
    }
    (void) fclose(fp);
    sprintf(msgbuf, "Processed alias file: %s\n", cidalias);
    logMsg(LEVEL1, msgbuf);

    sprintf(msgbuf, "Alias Table ");
    logMsg(LEVEL1, msgbuf);
	
    if (!errorStatus && alias[0].type)
    {
	    for (i = 0; i < ALIASSIZE && alias[i].type; ++i)
        ;
        sprintf(msgbuf, "Number of Entries: %d/%d\n", i, ALIASSIZE);
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

        max_temp = strlen("FROM");
        if (max_temp > max_from) max_from=max_temp;

        max_temp = strlen("TO");
        if (max_temp > max_to) max_to=max_temp;

        sprintf(msgbuf, "    %-7s %s%-*s %s%-*s %s%-*s %s\n",
                "ELEMENT",
                "TYPE", max_type_txt - (int) strlen("TYPE"), "",
                "FROM", max_from - (int) strlen("FROM"), "",
                "TO", max_to - (int) strlen("TO"), "",
                "DEPEND");
        logMsg(LEVEL8, msgbuf);
        sprintf(msgbuf, "    %-7s %s%-*s %s%-*s %s%-*s %s\n",
                "-------",
                "----", max_type_txt - (int) strlen("TYPE"), "",
                "----", max_from - (int) strlen("FROM"), "",
                "--", max_to - (int) strlen("TO"), "",
                "------");
        logMsg(LEVEL8, msgbuf);

        for (i = 0; i < ALIASSIZE && alias[i].type; ++i)
        {
            sprintf(msgbuf, "    %-7.3d %s%-*s %s%-*s %s%-*s ",
                i,
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
    else
    {
        sprintf(msgbuf, "Number of Entries: 0/%d\n", ALIASSIZE);
        logMsg(LEVEL1, msgbuf);
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

    inptr = getWord(fnptr, inptr, word, lc);

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
    if (type == NMBRNAME || (inptr = getWord(fnptr, inptr, wdptr, lc)))
    {
        mem = cpy2mem(wdptr, mem);
        if (strlen(mem) > CIDSIZE) configError(cidalias, lc, wdptr, ERRLONG);
        alias[cnt].from = mem;
        if ((inptr = getWord(fnptr, inptr, wdptr, lc)))
        {
            if (*wdptr == '=')
            {
                if ((inptr = getWord(fnptr, inptr, wdptr, lc)))
                {
                    mem = cpy2mem(wdptr, mem);
                    if (strlen(mem) > CIDSIZE)
                        configError(cidalias, lc, wdptr, ERRLONG);
                    alias[cnt].to = mem;
                    if (type == NMBRNAME) alias[cnt].type = type;
                    else
                    {
                        if ((inptr = getWord(fnptr, inptr, wdptr, lc)))
                        {
                               if (strcmp(wdptr, "if"))
                                configError(cidalias, lc, wdptr, ERRIF);
                            else if ((inptr = getWord(fnptr, inptr, wdptr, lc)))
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

/*
 * Find the an alias and return the type of alias.
 * If multiple aliases, return the last one.
 */
char *findAlias(char *name, char *nmbr, char *line) {
    int i;
    char *calltype, *linetype;
    static char ret[BUFSIZ];

    /* set defaults */
    calltype = linetype = NOALIAS_TXT;

    for (i = 0; i < ALIASSIZE && alias[i].type; ++i)
    {
        if (strcmp(alias[i].to, nmbr) == 0)
        {
            calltype = alias[i].type_txt;
        }
        if (strcmp(alias[i].to, name) == 0)
        {
            calltype = alias[i].type_txt;
        }
        if (strcmp(alias[i].to, line) == 0)
        {
            linetype = alias[i].type_txt;
        }
    }
    if (*line)
    {
        /* there is a line name so new format */
        sprintf(ret, "%s %s ", calltype, linetype);
    }
    else
    {
        /* there is no line name so old format */
        sprintf(ret, "%s", calltype);
    }

    return ret;
}

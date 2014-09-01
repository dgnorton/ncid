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

struct alias *aliasHead = NULL, *aliasCurrent = NULL;

int doAlias(), strmatch();
char *findAlias();
void builtinAlias(), nextAlias(), userAlias(), getAlias(), setAlias(), rmaliases();

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
    struct alias *node = aliasHead;
    struct alias *nextnode;

    /* we may want to skip the leading 1, if present */
    if (ignore1 && *nmbr == '1') ++nmbr;

    while (node != NULL)
    {
        nextnode = node->next;
        switch (node->info.type)
        {
            case NMBRNAME:
                if (strmatch(nmbr, node->info.from)) strcpy(nmbr, node->info.to);
                if (strmatch(name, node->info.from)) strcpy(name, node->info.to);
                break;
            case NMBRONLY:
                if (strmatch(nmbr, node->info.from)) strcpy(nmbr, node->info.to);
                break;
            case NMBRDEP:
                if (strmatch(name, node->info.depend) && strmatch(nmbr, node->info.from))
                {
                    strcpy(nmbr, node->info.to);
                }
                break;
            case NAMEONLY:
                if (strmatch(name, node->info.from)) strcpy(name, node->info.to);
                break;
            case NAMEDEP:
                if (strmatch(nmbr, node->info.depend) && strmatch(name, node->info.from))
                {
                    strcpy(name, node->info.to);
                }
                break;
            case LINEONLY:
                if (strmatch(line, node->info.from)) strcpy(line, node->info.to); 
                break;
        }
        node = nextnode;
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
    struct alias *node;
    struct alias *nextnode;

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

    sprintf(msgbuf, "Alias Table:\n");
    logMsg(LEVEL1, msgbuf);
	
    node = aliasHead;
    if (!errorStatus && node)
    {
        for (i = 0; node != NULL; i++)
        {
            nextnode = node->next;
            node = nextnode;
        }
        sprintf(msgbuf, "    Number of Entries: %d\n", i);
        logMsg(LEVEL1, msgbuf);

        /*
         * Make the alias display pretty by determining maximum column
         * widths, and create human readable 'type'.
         */

        node = aliasHead;
        while(node != NULL)
        {
            nextnode = node->next;
            switch (node->info.type)
            {
                case NMBRNAME:
                    node->info.type_txt = NMBRNAME_TXT ;
                    break;

                case NMBRONLY:
                    node->info.type_txt = NMBRONLY_TXT ;
                    break;

                case NMBRDEP:
                    node->info.type_txt = NMBRDEP_TXT ;
                    break;

                case NAMEONLY:
                    node->info.type_txt = NAMEONLY_TXT ;
                    break;

                case NAMEDEP:
                    node->info.type_txt = NAMEDEP_TXT ;
                    break;

                case LINEONLY:
                    node->info.type_txt = LINEONLY_TXT ;
                    break;

                default:
                    node->info.type_txt = "UNKNOWN" ;
            }

            max_temp = strlen(node->info.type_txt);
            if (max_temp > max_type_txt) max_type_txt=max_temp;

            max_temp = strlen(node->info.from);
            if (max_temp > max_from) max_from=max_temp;

            max_temp = strlen(node->info.to);
            if (max_temp > max_to) max_to=max_temp;

            node = nextnode;
        }

        max_temp = strlen("FROM");
        if (max_temp > max_from) max_from=max_temp;

        max_temp = strlen("TO");
        if (max_temp > max_to) max_to=max_temp;

        sprintf(msgbuf, "    %-4s %s%-*s %s%-*s %s%-*s %s\n",
                "SLOT",
                "TYPE", max_type_txt - (int) strlen("TYPE"), "",
                "FROM", max_from - (int) strlen("FROM"), "",
                "TO", max_to - (int) strlen("TO"), "",
                "DEPEND");
        logMsg(LEVEL8, msgbuf);
        sprintf(msgbuf, "    %-4s %s%-*s %s%-*s %s%-*s %s\n",
                "----",
                "----", max_type_txt - (int) strlen("TYPE"), "",
                "----", max_from - (int) strlen("FROM"), "",
                "--", max_to - (int) strlen("TO"), "",
                "------");
        logMsg(LEVEL8, msgbuf);

        node = aliasHead;
        for (i = 0; node != NULL; i++)
        {
            nextnode = node->next;
            sprintf(msgbuf, "    %-4.3d %s%-*s %s%-*s %s%-*s ",
                i,
                node->info.type_txt,
                max_type_txt - (int) strlen(node->info.type_txt), "",
                node->info.from,
                max_from - (int) strlen(node->info.from), "",
                node->info.to,
                max_to - (int) strlen(node->info.to), "");

            if (node->info.depend)
                strcat(strcat(strcat(msgbuf, "\""), node->info.depend), "\"");
            strcat(msgbuf, NL);

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
    nextAlias();
    if (type == NMBRNAME || (inptr = getWord(fnptr, inptr, wdptr, lc)))
    {
        if (strlen(wdptr) > CIDSIZE) configError(cidalias, lc, wdptr, ERRLONG);
        strcpy(aliasCurrent->info.from, wdptr);
        if ((inptr = getWord(fnptr, inptr, wdptr, lc)))
        {
            if (*wdptr == '=')
            {
                if ((inptr = getWord(fnptr, inptr, wdptr, lc)))
                {
                    if (strlen(wdptr) > CIDSIZE)
                        configError(cidalias, lc, wdptr, ERRLONG);
                    strcpy(aliasCurrent->info.to, wdptr);
                    if (type == NMBRNAME)
                        aliasCurrent->info.type = type;
                    else
                    {
                        if ((inptr = getWord(fnptr, inptr, wdptr, lc)))
                        {
                               if (strcmp(wdptr, "if"))
                                configError(cidalias, lc, wdptr, ERRIF);
                            else if ((inptr = getWord(fnptr, inptr, wdptr, lc)))
                            {
                                if (strlen(wdptr) > CIDSIZE)
                                    configError(cidalias, lc, wdptr, ERRLONG);
                                strcpy(aliasCurrent->info.depend, wdptr);
                                aliasCurrent->info.type = type + 1;
                            }
                            else configError(cidalias, lc, wdptr, ERRARG);
                        }
                        else aliasCurrent->info.type = type;
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

void nextAlias()
{
    struct alias *node;
    if (!(node = (struct alias *) malloc(sizeof(struct alias))))
        errorExit(-1, name, 0);
    node->next = NULL;
    if (aliasHead == NULL) aliasHead = node;
    else aliasCurrent->next = node;
    aliasCurrent = node;
}

/*
 * Frees all alias nodes
 */
void rmaliases()
{
    struct alias *node = aliasHead;
    struct alias *nextnode;

    while (node != NULL)
    {
        nextnode = node->next;
        free(node);
        node = nextnode;
    }

    aliasHead = NULL;
    aliasCurrent = NULL;
}

/*
 * Find the an alias and return the type of alias.
 * If multiple aliases, return the last one.
 */
char *findAlias(char *name, char *nmbr, char *line) {
    char *calltype, *linetype;
    static char ret[BUFSIZ];
    struct alias *node = aliasHead;
    struct alias *nextnode;

    /* set defaults */
    calltype = linetype = NOALIAS_TXT;

    while (node != NULL)
    {
        nextnode = node->next;
        if (strcmp(node->info.to, nmbr) == 0)
        {
            calltype = node->info.type_txt;
        }
        if (strcmp(node->info.to, name) == 0)
        {
            calltype = node->info.type_txt;
        }
        if (strcmp(node->info.to, line) == 0)
        {
            linetype = node->info.type_txt;
        }
        node = nextnode;
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

/*
 * config.h This file is part of sip2ncid.
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

#ifndef CONFIG_H
#define CONFIG_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#ifndef CONFIG
#define CONFIG      "/usr/local/etc/ncid/sip2ncid.conf"
#endif

#define WORDZERO    0x00
#define WORDSTR     0x10
#define WORDNUM     0x20
#define WORDFONT    0x40
#define WORDFLAG    0x80

#define ON           1
#define OFF          0

#define ERRCMD      "unknown command:"
#define ERRWORD     "unknown word:"
#define ERRARG      "missing argument for word:"
#define ERREQA      "missing '=' after word:"
#define ERREQB      "missing '=' before word:"
#define ERRMISS     "missing:"
#define ERRNUM      "invalid number:"

struct setword
{
    char *word;
    int type;
    char **buf;
    int *value;
    int min;
    int max;
};

void perror(), doSet(), configError();
char *getWord();
int findWord(), doConf();

extern void errorExit();
extern int debug, verbose, delay;
extern char *config, *name;
extern struct setword setword[];

#endif /* CONFIG_H */

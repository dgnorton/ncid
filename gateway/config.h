/*
 * Copyright 2007 John L. Chmielewski <jlc@cfl.rr.com>
 *
 * config.h is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * config.h is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 */

#ifndef CONFIG_H
#define CONFIG_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#ifndef CONFIG
#define CONFIG      "/usr/local/etc/ncid/ncidsip.conf"
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

void perror();
char *getWord();
int findWord(), doConf(), doSet(), configError();

extern void errorExit();
extern int debug, verbose, delay;
extern char *config, *name;
extern struct setword setword[];

#endif /* CONFIG_H */

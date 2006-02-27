/*
 * Copyright (c) 2002, 2005, 2006
 * by John L. Chmielewski <jlc@users.sourceforge.net>
 *
 * nciddconf.h is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * nciddconf.h is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 */

#include <stdio.h>
#include <string.h>

#ifndef CIDCONF
#define CIDCONF     "/etc/ncid/ncidd.conf"
#endif

#define WORDZERO    0x00
#define WORDSTR     0x10
#define WORDNUM     0x20
#define WORDFONT    0x40
#define WORDFLAG    0x80

#define ON          1
#define OFF         0

#define ERRCMD      "unknown command:"
#define ERRWORD     "unknown word:"
#define ERRARG      "missing argument for word:"
#define ERREQA      "missing '=' after word:"
#define ERREQB      "missing '=' before word:"
#define ERRMISS     "missing:"
#define ERRNUM      "invalid number:"
#define ERRPORT     "invalid port number:"

struct setword
{
    char *word;
    int type;
    char **buf;
    int *value;
    int min;
    int max;
};

struct sendclient
{
    char *word;
    int *value;
};

extern char *name, *cidconf;
extern struct setword setword[];
extern struct sendclient sendclient[];
extern char *getWord();

/*, 2009
 * Copyright (c) 2005, 2006
 * by John L. Chmielewski <jlc@users.sourceforge.net>
 *
 * nciddalias.h is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * nciddalias.h is distributed in the hope that it will be useful,
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

#ifndef CIDALIAS
#define CIDALIAS     "/etc/ncid/ncidd.alias"
#endif

#define ALIASSIZE    200
#define NMBRNAME     0x01
#define NMBRONLY     0x10
#define NMBRDEP      0x11
#define NAMEONLY     0x20
#define NAMEDEP      0x21
#define LINEONLY     0x40

#define NMBRNAME_TXT "NMBRNAME"
#define NMBRONLY_TXT "NMBRONLY"
#define NMBRDEP_TXT  "NMBRDEP"
#define NAMEONLY_TXT "NAMEONLY"
#define NAMEDEP_TXT  "NAMEDEP"
#define LINEONLY_TXT "LINEONLY"

#define ERRIF        "missing 'if' before word:"
#define ERRLONG      "word is too long:"
#define ERRALIAS     "too many aliases"

struct alias
{
    int type;
    char *type_txt;
    char *from;
    char *to;
    char *depend;
};

extern char *name, *cidalias;
extern struct alias alias[];
extern char *cpy2mem();
extern void rmaliases();

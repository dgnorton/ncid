/*
 * nciddhangup.h - This file is part of ncidd.
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

#ifndef NCIDDHANGUP_H
#define NCIDDHANGUP_H

#ifndef NO_REGEX
#include <sys/types.h>
#include <regex.h>
#endif

#ifndef BLACKLIST
#define BLACKLIST   "/etc/ncid/ncidd.blacklist"
#endif

#ifndef WHITELIST
#define WHITELIST   "/etc/ncid/ncidd.whitelist"
#endif

/* builtin rule return values */
#define RULE_NAME_CONTAINS_NUMBER 1000

#define PICKUP      "ATH1"
#define HANGUP      "ATH0"
#define FAXMODE     "AT+FCLASS=1"
#define DATAMODE    "AT+FCLASS=0"
#define VOICEMODE   "AT+FCLASS=8"
#define FAXANS      "ATA"
#define FAXDELAY    10   /* seconds */

#define GETOK       "AT"
#define HANGUPTRY   6
#define HANGUPDELAY 1   /* second */

#define ENTRYSIZE   180 /* maximum size of a list entry */

typedef struct list
{
    char entry[ENTRYSIZE];
    struct list *next;
#ifndef NO_REGEX
    regex_t preg;
#endif
}list_t;

extern char *blacklist, *whitelist;
extern int pickup;
extern struct list *blkHead, *blkCurrent, *whtHead, *whtCurrent,
                   *listHead, *listCurrent;
extern int doList(), doHangup(), onBlackWhite();
extern void rmEntries();

#endif	/*NCIDDHANGUP_H*/

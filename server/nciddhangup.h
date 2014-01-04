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

#ifndef BLACKLIST
#define BLACKLIST   "/etc/ncid/ncidd.blacklist"
#endif

#ifndef WHITELIST
#define WHITELIST   "/etc/ncid/ncidd.whitelist"
#endif

#define PICKUP      "AT H1"
#define HANGUP      "AT H0"
#define HANGUPTRY   6
#define HANGUPDELAY 400000  /* 400000 microseconds = 0.4 seconds */

#define LISTSIZE    500
#define ERRLIST     "list too large"

extern char *blacklist, *whitelist, *blklist[], *whtlist[];
extern int doList(), doHangup(), onBlackWhite();
extern void rmEntries();

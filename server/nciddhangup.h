/*
 * Copyright 2011
 * by  John L. Chmielewski <jlc@cfl.rr.com>
 *
 * nciddhangup.h is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * nciddhangup.h is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 */

#ifndef BLACKLIST
#define BLACKLIST   "/etc/ncid/ncidd.blacklist"
#endif

#define CR          "\r"
#define PICKUP      "ATH1"
#define HANGUP      "ATH0"
#define LISTSIZE    200
#define ERRLIST     "blacklist array too large"

extern char *blacklist;
extern int doBlacklist(), doHangup();
extern void rmbl();

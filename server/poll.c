/*
 * The following Copyright Notice references the use of the poll
 * stub below. The GPL license is not in effect for the following code snippet
 * braced by the ifdef __MACH__. You are free to embed the following software
 * and copyright notice without the encumberances of the GNU General Public
 * License.
 *
 * Copyright (c) 2002 Mark Salyzyn
 * Copyright (c) 2004
 * All rights reserved.
 *
 * modified by John L. Chmielewski:
 *  created poll.h and moved lines there, events and revents were reversed,
 *  added switch statement to look at return value of select(), added more
 *  poll() defines, modified logic to find fd that requires service
 *
 * TERMS AND CONDITIONS OF USE
 *
 * Redistribution and use in source form, with or without modification, are
 * permitted provided that redistributions of source code must retain the
 * above copyright notice, this list of conditions and the following
 * disclaimer.
 *
 * This software is provided `as is' by Mark Salyzyn and any express or implied
 * warranties, including, but not limited to, the implied warranties of
 * merchantability and fitness for a particular purpose, are disclaimed. In no
 * event shall Mark Salyzyn be liable for any direct, indirect, incidental,
 * special, exemplary or consequential damages (including, but not limited to,
 * procurement of substitute goods or services; loss of use, data, or profits;
 * or business interruptions) however caused and on any theory of liability,
 * whether in contract, strict liability, or tort (including negligence or
 * otherwise) arising in any way out of the use of this software, even if
 * advised of the possibility of such damage.
 */

#if (defined(__MACH__))

#include "poll.h"

int poll(struct pollfd * pfds, int npfds, int ptimeout)
{
    fd_set          readfds;
    fd_set          writefds;
    fd_set          exceptfds;
    struct timeval  timeout = { ptimeout / 1000, (ptimeout % 1000) * 1000 };
    struct pollfd * list    = pfds;
    int             nlist   = npfds;
    int             nfds    = 0;
    int             retVal  = 0;
    int             nsets;

    FD_ZERO(&readfds);
    FD_ZERO(&writefds);
    FD_ZERO(&exceptfds);

    /* Set up fds */
    if (list) while (nlist > 0) {
        list->revents = 0;
        if (list->events & POLLIN) {
            FD_SET(list->fd, &readfds);
            if (list->fd >= nfds) nfds = list->fd + 1;
        }
        ++list;
        --nlist;
    }

    switch (retVal = select(nfds, &readfds, &writefds, &exceptfds,
           (ptimeout > 0) ? &timeout : (struct timeval *)NULL))
    {
        case -1:    /* error */
            perror("select()");
            break;
        case 0:     /* timeout */
            break;
        default:    /* 1 or more events reported */
            nsets = retVal;
            nlist = npfds;
            list = pfds;
            if (list) while (nsets && nlist) {
                if (list->events & POLLIN) {
                    if (FD_ISSET(list->fd, &readfds)) {
                        list->revents |= POLLIN;
                        --nsets;
                    }
                }
                ++list;
                --nlist;
            }
            break;
    }
    return retVal;
}

#endif /* __MACH__ */

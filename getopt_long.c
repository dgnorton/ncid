/*
 * The following Copyright Notice references the use of the getopt_long
 * stub below. The GPL license is not in effect for the following code snippet
 * braced by the ifdef __MACH__. You are free to embed the following software
 * and copyright notice without the encumberances of the GNU General Public
 * License.
 *
 * Copyright (c) 2002 Mark Salyzyn
 * Copyright (c) 2004
 * All rights reserved.
 *
 * modified by John L. Chmielewski: added getopt_long.h and moved lines there
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

/*
 * Merde, getopt_long is not universally available on all platforms. Lets
 * make a minimal variant here that uses the traditional getopt. It is
 * unfortunate that the GNU variant of getopt skips none-argument
 * entries, yet the BSD variant stops at the first none-argument. The
 * following code assumes the BSD variant.
 */

#if (defined(__MACH__) || \
     defined(__USLC__) || \
     defined(__svr4)   || \
     defined(_M_XENIX) || \
     defined(__FreeBSD__))

#include "getopt_long.h"

int optopt;

int
getopt_long(int argc, char ** argv, char * args, struct option * largs,
            int * arg)
{
    extern char * optarg;
    extern int    optind;
    extern int    optopt;

    if (((optopt = getopt(argc, argv, args)) == -1)
     && (largs != (struct option *)NULL) && (optind <= argc)
     && (argv[optind-1][0] == '-') && (argv[optind-1][1] == '-'))
    for (--optind, *arg = 0; largs->name != (char *)NULL; ++largs, ++*arg) {
        if (strncmp(argv[optind]+2,largs->name,strlen(largs->name)) == 0) {
            if (*(optarg = &argv[optind][2+strlen(largs->name)]) == '\0') {
                optopt = largs->val;
                if (++optind < argc) {
                    optarg = argv[optind];
                    optind += largs->has_arg;
                }
                break;
            }
            if ((largs->has_arg == 0) || (*optarg != '=')) {
                continue;
            }
            optopt = largs->val;
            optind += largs->has_arg - 1;
            break;
        }
    }
    return optopt;
}

#endif

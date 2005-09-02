#!/bin/sh

#### OS-Dependent Information

#
#   Linux chkconfig stuff:
#
#   chkconfig: 235 99 00
#   description: Startup/shutdown script for the NCID Caller ID Daemon 
#

#
#   NetBSD 1.5+ rcorder script lines.  The format of the following two
#   lines is very strict -- please don't add additional spaces!
#
# PROVIDE: ncidd
# REQUIRE: DAEMON
#


#### OS-Dependent Configuration

case "`uname`" in
	IRIX*)
		IS_ON=/sbin/chkconfig
		;;

	NetBSD*)
        IS_ON=:
		;;

	Darwin*)
		. /etc/rc.common

		if test "${NCIDD:=-YES-}" = "-NO-"; then
			exit 0
		fi

        IS_ON=:
		;;

	Linux*)
		IS_ON=/bin/true
		;;

	FreeBSD*)
		IS_ON=/usr/bin/true
		;;

	*)
		IS_ON=/bin/true
		;;
esac

#### OS-Independent Stuff

#
# The verbose flag controls the printing of the names of
# daemons as they are started.  Currently always echos for
# all but IRIX, which can configure verbose bootup messages.
#

if test "`uname`" = "Darwin"; then
	ECHO=ConsoleMessage
else
	if $IS_ON verbose; then
		ECHO=echo
	else
		ECHO=:
	fi
fi

#
# See if the NCID server (ncidd) is running...
#

case "`uname`" in
	HP-UX* | AIX* | SINIX*)
		pid=`ps -e | awk '{if (match($4, ".*/ncidd$") || $4 == "ncidd") print $1}'`
		;;
	IRIX* | SunOS*)
		pid=`ps -e | nawk '{if (match($4, ".*/ncidd$") || $4 == "ncidd") print $1}'`
		;;
	UnixWare*)
		pid=`ps -e | awk '{if (match($6, ".*/ncidd$") || $6 == "ncidd") print $1}'`
		. /etc/TIMEZONE
		;;
	Linux* | *BSD* | Darwin* | OSF1*)
		pid=`ps ax | awk '{if (match($5, ".*/ncidd$") || $5 == "ncidd") print $1}'`
		;;
	*)
		pid=""
		;;
esac

#
# Start or stop the NCID server based upon the first argument to the script.
#

case $1 in
	start | restart | reload)
		if $IS_ON ncidd; then
			if test "$pid" != ""; then
				kill -HUP $pid
			else
				prefix=/usr/local
				exec_prefix=/usr/local
				${exec_prefix}/sbin/ncidd
			fi
#			$ECHO "ncidd: daemon ${1}ed."
			echo -n "ncidd "
		else
			$ECHO "ncidd: daemon stopped."
		fi
		;;

	stop)
		if test "$pid" != ""; then
			kill $pid
#			$ECHO "ncidd: daemon stopped."
			echo -n "ncidd "
		fi
		;;

	status)
		if test "$pid" != ""; then
			echo "ncidd: daemon is running."
		else
			echo "ncidd: daemon is not running."
		fi
		;;

	*)
		echo "Usage: ncidd {reload|restart|start|status|stop}"
		exit 1
		;;
esac

#
# Exit with no errors.
#

exit 0


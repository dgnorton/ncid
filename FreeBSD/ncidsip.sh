#!/bin/sh
#
## borrowed CUPSd startup script


#### OS-Dependent Information

#
#   Linux chkconfig stuff:
#
#   chkconfig: 235 99 00
#   description: Startup/shutdown script for the NCID Caller ID client 
#

#
#   NetBSD 1.5+ rcorder script lines.  The format of the following two
#   lines is very strict -- please don't add additional spaces!
#
# PROVIDE: ncidsip
# REQUIRE: DAEMON
#

ConfigDir=/usr/local/etc/ncid
ConfigFile=$ConfigDir/ncidscript.conf

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
		# Set the timezone, if possible...
		if test -f /etc/TIMEZONE; then
                        . /etc/TIMEZONE
                else
			if test -f /etc/sysconfig/clock; then
	                        . /etc/sysconfig/clock
        	                TZ="$ZONE"
                	        export TZ
			fi
                fi

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
# See if the NCID client (ncidsip) is running...
#

case "`uname`" in
	HP-UX* | AIX* | SINIX*)
		pid=`ps -e | awk '{if (match($5, ".*/ncidsip$") || $5 == "ncidsip") print $1}'`
		;;
	IRIX* | SunOS*)
		pid=`ps -e | nawk '{if (match($5, ".*/ncidsip$") || $5 == "ncidsip") print $1}'`
		;;
	UnixWare*)
		pid=`ps -e | awk '{if (match($7, ".*/ncidsip$") || $7 == "ncidsip") print $1}'`
		. /etc/TIMEZONE
		;;
	OSF1*)
		pid=`ps -e | awk '{if (match($6, ".*/ncidsip$") || $6 == "ncidsip") print $1}'`
		;;
	Linux* | *BSD* | Darwin*)
		pid=`ps ax | awk '{if (match($6, ".*/ncidsip$") || $6 == "ncidsip") print $1}'`
		;;
	*)
		pid=""
		;;
esac

#
# Start or stop the CUPS server based upon the first argument to the script.
#

case $1 in
	start | restart | reload)
		if $IS_ON ncidsip; then
			if test "$pid" != ""; then
				kill -HUP $pid
			else
				prefix=/usr/local
				exec_prefix=/usr/local
				opts=""
                [ -f $ConfigFile ] && . $ConfigFile
				${exec_prefix}/bin/ncidsip ${options} &
			fi
#			$ECHO "ncidsip: client ${1}ed."
			echo -n "ncidsip "
		else
			$ECHO "ncidsip: client stopped."
		fi
		;;

	stop)
		if test "$pid" != ""; then
			kill $pid
#			$ECHO "ncidsip: client stopped."
			echo -n "ncidsip "
		fi
		;;

	status)
		if test "$pid" != ""; then
			echo "ncidsip: client is running."
		else
			echo "ncidsip: client is not running."
		fi
		;;

	*)
		echo "Usage: ncidsip {reload|restart|start|status|stop}"
		exit 1
		;;
esac

#
# Exit with no errors.
#

exit 0
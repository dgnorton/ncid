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
# PROVIDE: yac2ncid
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

		if test "${YAC2NCID:=-YES-}" = "-NO-"; then
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
# See if the NCID client (yac2ncid) is running...
#

case "`uname`" in
	HP-UX* | AIX* | SINIX*)
		pid=`ps -e | awk '{if (match($5, ".*/yac2ncid$") || $5 == "yac2ncid") print $1}'`
		;;
	IRIX* | SunOS*)
		pid=`ps -e | nawk '{if (match($5, ".*/yac2ncid$") || $5 == "yac2ncid") print $1}'`
		;;
	UnixWare*)
		pid=`ps -e | awk '{if (match($7, ".*/yac2ncid$") || $7 == "yac2ncid") print $1}'`
		. /etc/TIMEZONE
		;;
	OSF1*)
		pid=`ps -e | awk '{if (match($6, ".*/yac2ncid$") || $6 == "yac2ncid") print $1}'`
		;;
	Linux* | *BSD* | Darwin*)
		pid=`ps ax | awk '{if (match($6, ".*/yac2ncid$") || $6 == "yac2ncid") print $1}'`
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
		if $IS_ON yac2ncid; then
			if test "$pid" != ""; then
				kill -HUP $pid
			else
				prefix=/usr/local
				exec_prefix=/usr/local
				opts=""
                [ -f $ConfigFile ] && . $ConfigFile
				${exec_prefix}/bin/yac2ncid ${options} &
			fi
#			$ECHO "yac2ncid: client ${1}ed."
			echo -n "yac2ncid "
		else
			$ECHO "yac2ncid: client stopped."
		fi
		;;

	stop)
		if test "$pid" != ""; then
			kill $pid
#			$ECHO "yac2ncid: client stopped."
			echo -n "yac2ncid "
		fi
		;;

	status)
		if test "$pid" != ""; then
			echo "yac2ncid: client is running."
		else
			echo "yac2ncid: client is not running."
		fi
		;;

	*)
		echo "Usage: yac2ncid {reload|restart|start|status|stop}"
		exit 1
		;;
esac

#
# Exit with no errors.
#

exit 0

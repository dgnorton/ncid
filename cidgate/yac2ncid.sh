#!/bin/bash
##
## YAC2NCID - YAC to NCID gateway service
##
## NOTE: This script requires netcat binary (nc) to operate
##       The bash location in the first line must match the if test below
##
## Copyright (c) 2007, 2008
## by Michael Lasevich(hichhiker)
## Version: 1.0 (6/14/2007)
## Version: 1.0a (6/26/2007)
##
## Version: 1.0.[123] (5/29/2008) by John L. Chmielewski
##
VERSION="1.0.4)"

ME="$(basename $0)"
ME="${ME%.sh}"
MYDIR="$(cd $(dirname $0) && pwd -P)"

## Workaround for broken trap on TiVo
## checking if date is 199?: broken bash
## could also test for TiVo: /tvbin/tivoapp
if /bin/bash --version | grep 199 > /dev/null
then
    # must use bash with broken trap
	PIDFILE=/dev/null
else
    # trap should be OK
    PIDFILE=/var/run/yac2ncid.pid

    dienice(){
        if test -f ${PIDFILE}
        then
            local line pid
            echo >> ${PIDFILE}
            read line < "${PIDFILE}"
            for pid in $line ; do
                [ -z "${pid//[0-9]/}" -a -d "/proc/$pid" ] &&
                [ $pid != $$ ] &&
                kill $pid
            done
		    rm -f ${PIDFILE}
        fi
        exit
    }

	trap dienice INT HUP QUIT TERM EXIT
fi

set -e

CONFFILE=""

ConfigDir=/usr/local/etc/ncid

VERBOSE=

YACPORT=10629
NCIDSERVER=localhost:3333
LINE="YAC"
NETCAT=

NETCAT_SEND_OPTS=""
NETCAT_LISTEN_OPTS="-p"

NETCAT_BUSYBOX_SEND_OPTS=""
NETCAT_BUSYBOX_LISTEN_OPTS="-p"

NETCAT_HOBBIT_SEND_OPTS="-w1"
NETCAT_HOBBIT_LISTEN_OPTS="-p"

NETCAT_JACKSON_SEND_OPTS="-w1"
NETCAT_JACKSON_LISTEN_OPTS=""

NETCAT_BSD_SEND_OPTS="-w1"
NETCAT_BSD_LISTEN_OPTS=""

NETCAT_CUSTOM_SEND_OPTS="-w1"
NETCAT_CUSTOM_LISTEN_OPTS="-p"

NCIDHOST="localhost"
NCIDPORT="3333"

##
## isblank(string) - returns true if string is blank
##

isblank(){
	test "z${*}" == "z"
}


##
## msg(string) - sends message
##

msg(){
	isblank $VERBOSE ||\
		echo ${ME}: $*
	true
}



##
## findfile(file, path) - find "file" in "path"
##
findfile(){
	local filename="${1}"
	local path="${2}"
	local O_IFS="${IFS}"
	local N_IFS=":"
	local fullfile=""

	IFS="${N_IFS}"
	for location in ${path:-.}
	do
		IFS="${O_IFS}"
		local fullfile="${location}/${filename}"
		test -f "${fullfile}" &&\
			echo ${fullfile} &&\
			break
		IFS="${N_IFS}"
	done
	IFS="${O_IFS}"
}

## Process a message
procMSG(){
	local nciddate=$(date +"%m%d%H%M")
	local ncidname=""
	local ncidnnumber=""

	local NCIDMSG="${*}"	

	if ! isblank $(echo "${*}" | grep '^@CALL')
	then
		ncidname=$(echo ${NCIDMSG} | cut -c6- | cut -d'~' -f1);
		ncidnumber=$(echo ${NCIDMSG} | cut -s -d'~' -f2-);
		NCIDMSG="$(printf 'CALL: ###DATE%s...LINE%s...NMBR%s...NAME%s+++' "${nciddate:-01010000}" "${LINE:--}" "${ncidnumber:-unlisted}" "${ncidname:-noname}")"

	fi	
  	echo ${NCIDMSG} | send2ncid
}



## send stdin to ncidd server
send2ncid(){
	${NETCAT:-nc} ${NETCAT_SEND_OPTS} ${NCIDHOST:-localhost} ${NCIDPORT:-3333} >/dev/null
}


## Check command line options

test "z${1}" == "z-v" &&\
	VERBOSE="yes" &&\
	msg Enabling verbose mode due to command line option;\
    msg Version ${VERSION}


CONFFILE="$(findfile ${ME%.sh}.conf "${MYDIR}:${MYDIR}/../etc:${ConfigDir}:~:/etc")"

isblank ${CONFFILE} &&\
    msg ${ME%.sh}.conf not found ||\
    {
	    msg Using ${CONFFILE}
        source ${CONFFILE}
    }


## Parse NCIDSERVER
NCIDHOST="$(echo ${NCIDSERVER:-localhost} | cut -d: -f1)"
NCIDPORT="$(echo ${NCIDSERVER:-localhost} | cut -s -d: -f2)"
msg Using NCID host: ${NCIDHOST}
msg Using NCID port: ${NCIDPORT}
msg Using YAC port: ${YACPORT}


## Make sure netcat is available
isblank ${NETCAT} &&\
	NETCAT=$(which nc 2>/dev/null || echo nc)

! test -x ${NETCAT:=nc}  &&\
	echo Unable to find netcat binary \(${NETCAT}\) &&\
	exit -1

if isblank ${NETCAT_TYPE}
then
	msg Auto-detecting the netcat type
	if test "z$(${NETCAT:-nc} -h 2>&1  | head -1 |  cut -d' ' -f1)" == 'z[v1.10]'
	then
		msg Detected \*Hobbit\* version of netcat 
		NETCAT_TYPE="HOBBIT"
	elif ! isblank "$(${NETCAT:-nc} -h 2>&1 | grep BusyBox)"
	then	
		msg Detected BusyBox version of netcat 
		NETCAT_TYPE="BUSYBOX"
	elif ! isblank "$(${NETCAT:-nc} -h 2>&1 | grep '46DdhklnrStUuvzC')"
	then
		msg Detected \"Eric Jackson\" version of netcat
		NETCAT_TYPE="JACKSON"
	elif ! isblank "$(${NETCAT:-nc} -h 2>&1 | grep '46DEdhklnrStUuvz')"
	then
		msg Detected \"BSD\" version of netcat
		NETCAT_TYPE="BSD"
	else
		msg Unknown version of netcat, using CUSTOM values
		NETCAT_TYPE="CUSTOM"
	fi
fi


case "${NETCAT_TYPE:-CUSTOM}" in
	"BUSYBOX"|"busybox")
		msg Using BusyBox settings...
		NETCAT_SEND_OPTS="${NETCAT_BUSYBOX_SEND_OPTS}"	
		NETCAT_LISTEN_OPTS="${NETCAT_BUSYBOX_LISTEN_OPTS}"	
		;;
	"HOBBIT"|"hobbit")
		msg Using Hobbit settings...
		NETCAT_SEND_OPTS="${NETCAT_HOBBIT_SEND_OPTS}"	
		NETCAT_LISTEN_OPTS="${NETCAT_HOBBIT_LISTEN_OPTS}"	
		;;
	"JACKSON"|"jackson")
		msg Using Jackson settings...
		NETCAT_SEND_OPTS="${NETCAT_JACKSON_SEND_OPTS}"	
		NETCAT_LISTEN_OPTS="${NETCAT_JACKSON_LISTEN_OPTS}"	
		;;
	"BSD"|"BSD")
		msg Using BSD settings...
		NETCAT_SEND_OPTS="${NETCAT_BSD_SEND_OPTS}"	
		NETCAT_LISTEN_OPTS="${NETCAT_BSD_LISTEN_OPTS}"	
		;;
	*)
		msg Using custom settings...
		NETCAT_SEND_OPTS="${NETCAT_CUSTOM_SEND_OPTS}"	
		NETCAT_LISTEN_OPTS="${NETCAT_CUSTOM_LISTEN_OPTS}"	
		;;
	
esac

msg Listening for new connections
## Main loop
while true
do
	MSG=$(bash -c "echo \"\$\$ \">>${PIDFILE:-/tmp/ncpid} && exec ${NETCAT:-nc} -l ${NETCAT_LISTEN_OPTS} $YACPORT")
	test "z" != "z${MSG}" &&\
		msg Got a message &&\
		procMSG "$MSG" &
done

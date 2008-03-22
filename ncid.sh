#!/bin/sh

# ncid - Network Caller-ID client

# Copyright (c) 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008
# by John L. Chmielewski <jlc@users.sourceforge.net>

# ncid is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# any later version.

# ncid is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA

# START OF LOCAL MODIFICATION SECTION
# set TCLSH variable, FreeBSD will call it something like tclsh8.4 \
TCLSH=tclsh
# set WISH variable, FreeBSD will call it something like wish8.4 \
WISH=wish
# END OF LOCAL MODIFICATION SECTION

# set nice value on TiVo, if "setpri" found \
type setpri > /dev/null 2>&1 && setpri rr 1 $$
# set up TiVo options to use out2osd \
OPTSTIVO="--no-gui --tivo --message --call-prog --program /usr/local/bin/out2osd"
# if name is tivocid, exec tivosh (for backward compatibility) \
case $0 in *tivocid) exec tivosh ncid $OPTSTIVO "$@"; esac
# set up TiVo options to use ncid-tivo \
OPTSTIVO="--no-gui --message --call-prog --program ncid-tivo"
# if name is tivoncid, exec tivosh \
case $0 in *tivoncid) exec tivosh ncid $OPTSTIVO "$@"; esac
# look for the --no-gui option \
GUI=""; for i in $*; do if [ "$i" = "--no-gui" ]; then  GUI="$i"; fi; done
# if --no-gui is not specified, look for wish and exec it \
[ -z "$GUI" ] && type $WISH > /dev/null 2>&1 && exec $WISH -f "$0" "$@"
# if --no-gui is specified, look for tclsh and exec it \
[ -n "$GUI" ] && type $TCLSH > /dev/null 2>&1 && exec $TCLSH "$0" "$@"
# wish not found, look for tclsh and exec it \
type $TCLSH > /dev/null 2>&1 && exec $TCLSH "$0" --no-gui "$@"
# tclsh not found, look for tivosh and exec it \
type tivosh > /dev/null 2>&1 && exec tivosh "$0" $OPTSTIVO "$@"
# tivosh not found, maybe using a Macintosh \
[ -d /Applications/Wish\ Shell.app ] && \
    /Applications/Wish\ Shell.app/Contents/MacOS/Wish\ Shell -f "$0" "$@"
# tcl or tk not found \
echo "wish or tclsh or tivosh not found or not in your \$PATH"; exit -1

set ConfigDir   /usr/local/etc/ncid
set ConfigFile  [list $ConfigDir/ncid.conf]

# Constants
set ProgDir     /usr/local/share/ncid
set ProgName    ncid-speak
set CygwinBat   /cygwin.bat

# global variables that can be changed by command line options
set Host        127.0.0.1
set Port        3333
set Delay       60
set Raw         0
set PIDfile     /var/run/ncid.pid
set Program     [list $ProgDir/$ProgName]
set All         0
set Verbose     0
set NoGUI       0
set Callprog    0
set CallOnRing  0
set TivoFlag    0
set MsgFlag     0

if {[file exists $ConfigFile]} {
    catch [source $ConfigFile]
}

# global variables that are fixed
set Connect     0
set Count       0
set ExecSh      0
set Ring        0
set Socket      0
set Try         0
set Version     0.70
set VersionInfo "Network CallerID Client Version $Version"
set Usage       {Usage:   ncid  [OPTS] [ARGS]
         OPTS: [--no-gui]
               [--all             | -A]
               [--call-prog       | -C]
               [--delay seconds   | -D seconds]
               [--message         | -M]
               [--pidfile FILE    | -p pidfile]
               [--program PROGRAM | -P PROGRAM]
               [--raw             | -R]
               [--ring count      | -r count]
               [--tivo            | -T]
               [--verbose         | -V]
         ARGS: [IP_ADDRESS        | HOSTNAME]
               [PORT_NUMBER]}

set About \
"
Network Caller ID Client (ncid): Version $Version
Copyright (C) 2001, 2002, 2003, 2004, 2005, 2006
Copyright (C) 2007, 2008
by John L. Chmielewski
"

# display error message and exit
proc exitMsg {code msg} {
    global NoGUI

    if $NoGUI {
        puts stderr $msg
    } else {
        option add *Dialog.msg.wrapLength 9i
        option add *Dialog.msg.font "courier 12"
        tk_messageBox -message $msg -type ok
    }
    exit $code
}

# display TCP/IP error message, then try to reconnect
proc errorMsg {msg} {
    global Connect
    global Count
    global Delay
    global Try
    global Txt
    global NoGUI
    global Verbose

    if $NoGUI {
        if $Verbose {puts -nonewline stderr $msg}
        after [expr $Delay*1000] retryConnect
    } else {
        set Connect 0
        set Count $Delay
        while {$Count > 0} {
            if {$Count == 1} {
                set Txt "$msg Try $Try in $Count second."
            } else {
                set Txt "$msg Try $Try in $Count seconds."
            }
            set Count [expr $Count - 1]
            after [expr 1000] waitOnce
            vwait Once
        }
        retryConnect
    }
}

# Count loop delay
proc waitOnce {} {
    global Once

    set Once 0
    after cancel waitOnce
}

# try to connect to CID server again
proc retryConnect {} {
    global Host
    global Port
    global NoGUI

    if $NoGUI {after cancel retryConnect}
    connectCID $Host $Port
}

# This catches a lot of errors!
proc bgerror {mess} {
    global errorInfo

    exitMsg 1 "BGError: $mess\n"
}

# Get data from CID server
proc getCID {} {
    global Connect
    global Socket
    global Host
    global Port
    global Raw
    global Try
    global VersionInfo
    global NoGUI
    global MsgFlag
    global Callprog
    global Ring
    global CallOnRing
    global cid

    set msg {CID connection closed}
    set cnt 0
    while {$cnt != -1} {
        if {[eof $Socket] || [catch {set cnt [gets $Socket dataBlock]} msg]} {
            # remove event handler
            fileevent $Socket readable ""
            close $Socket
            set Try [expr $Try + 1]
            errorMsg "$Host:$Port - $msg\n"
            return
        }
        set Try 0
        # get rid of non-printable characters at start/end of string
        set dataBlock [string trim $dataBlock]

        if $Raw {
            # output NCID data line
            displayLog [list $dataBlock]
            if {[string match 200* $dataBlock]} {
                if {!$NoGUI} { displayCID "$VersionInfo\n$dataBlock" }
            }
        } else {
            if {[string match 200* $dataBlock]} {
                # output NCID server connect message
                regsub {200 (.*)} $dataBlock {\1} dataBlock
                if $NoGUI { displayLog [list "$VersionInfo\n$dataBlock"]
                } else { displayCID "$VersionInfo\n$dataBlock" }
            }
        }
        if {[set type [checkCID $dataBlock]]} {
            if {$CallOnRing && $type == 5 && $Callprog} {
                # found CIDINFO line
                set cidinfo [getField RING $dataBlock]
                if {$Ring == $cidinfo} {sendCID $cid}
            } elseif {$type == 4} {
                # found MSG line
                regsub {MSG: (.*)} $dataBlock {\1} msg
                displayLog [list $msg]
                if {$MsgFlag} {sendMSG $msg}
            } else {
                # found CID, EXTRA, or CIDLOG line
                set cid [formatCID $dataBlock]
                # Clear display window if CIDLOG line is received
                if {!$Connect && $type == 3} {
                    set Connect 1
                    if {!$NoGUI} {clearLog}
                }
                # display CID log
                if {$type < 4} {
                    if {!$Raw} {displayLog $cid}
                }
                # display CID
                if {$type < 3} {
                    if {!$NoGUI} {
                        displayCID $cid
                        # create a pop-up, even if open, in current desktop
                        wm iconify .
                        update
                        wm deiconify .
                        raise .
                        update
                    }
                    if {!$CallOnRing && $Callprog} {sendCID $cid}
                }
            }
        }
    }
}

proc checkCID {dataBlock} {
    # ignore all but the CID or EXTRA information line
    if [string match CID:* $dataBlock] {return 1}
    if [string match *EXTRA:* $dataBlock] {return 2}
    if [string match CIDLOG:* $dataBlock] {return 3}
    if [string match MSG:* $dataBlock] {return 4}
    if [string match CIDINFO:* $dataBlock] {return 5}
    return 0
}

# must be sure the line passed checkCID
proc formatCID {dataBlock} {
    set cidname [getField NAME $dataBlock]
    set cidnumber [getField NU*MBE*R $dataBlock]
    if {![regsub \
        {1?([0-9][0-9][0-9])([0-9][0-9][0-9])([0-9][0-9][0-9][0-9])} \
        $cidnumber {(\1)\2-\3} cidnumber]} {
        if {![regsub {([0-9][0-9][0-9])([0-9][0-9][0-9][0-9])(.*)} \
        $cidnumber {BAD-\1\2\3} cidnumber]} {
        regsub {([0-9][0-9][0-9])([0-9][0-9][0-9][0-9])} \
        $cidnumber {\1-\2} cidnumber
        }
    }
    set ciddate [getField DATE $dataBlock]
    if {![regsub {([0-9][0-9])([0-9][0-9])([0-9][0-9][0-9][0-9])} \
        $ciddate {\1/\2/\3} ciddate]} {
        regsub {([0-9][0-9])([0-9][0-9].*)} $ciddate {\1/\2} ciddate
    }
    set cidtime [getField TIME $dataBlock]
    regsub {([0-9][0-9])([0-9][0-9])} $cidtime {\1:\2} cidtime
    if [string match {*\*LINE\**} $dataBlock] {
        set cidline [getField LINE $dataBlock]
        regsub {(.*)} $cidline {<\1>} cidline
    # set default line indicator
    } else {set cidline <->}
    # make default line indicator a blank
    regsub {<->} $cidline {} cidline

    return [list $ciddate $cidtime $cidnumber $cidname $cidline]
}

# get a field from the CID data
proc getField {dataString dataBlock} {
    regsub ".*\\*$dataString\\*" $dataBlock {} result
    regsub {([\w\s]*)\*.*} $result {\1} result
    return $result
}

# pass the CID information to an external program
# Input: "$ciddate $cidtime $cidnumber $cidname $cidline\n"
proc sendCID {cid} {
    global All
    global Program
    global TivoFlag
    global ExecSh

    if $All {
      # pass DATE\nTIME\nNUMBER\nNAME\n
      if $ExecSh {
        catch {exec sh -c $Program << \
          "[lindex $cid 0]\n[lindex $cid 1]\n[lindex $cid 2]\n[lindex $cid 3]\n" &} oops
      } else {
        catch {exec $Program << \
          "[lindex $cid 0]\n[lindex $cid 1]\n[lindex $cid 2]\n[lindex $cid 3]\n" &} oops
      }
      } elseif $TivoFlag {
        # pass NAME NUMBER\nLINE\n
        catch {exec $Program << \
          "[lindex $cid 3] [lindex $cid 2]\n[lindex $cid 4]\n" &} oops
      } else {
        # pass DATE\nTIME\nNUMBER\nNAME\nLINE\n
        if $ExecSh {
          catch {exec sh -c $Program << \
            "[lindex $cid 0]\n[lindex $cid 1]\n[lindex $cid 2]\n[lindex $cid 3]\n[lindex $cid 4]\n" &} oops
        } else {
          catch {exec $Program << \
            "[lindex $cid 0]\n[lindex $cid 1]\n[lindex $cid 2]\n[lindex $cid 3]\n[lindex $cid 4]\n" &} oops
        }
      }
}

# pass the MSG information to an external program
# Input: "$msg"
proc sendMSG {msg} {
    global Program
    global TivoFlag

    if $TivoFlag {
      # send "$msg\n"
      # instead of: $ciddate $cidnumber\n$cidline
      catch {exec [lindex $Program 0] << "$msg\n" &} oops
    } else {
      # send "\n\n\n$msg\n\n"
      # in place of: "$ciddate\n$cidtime\n$cidnumber\n$cidname\n$cidline\n"
      if $ExecSh {
        catch {exec sh -c $Program << "\n\n\n$msg\n\n" &} oops
      } else {
        catch {exec $Program << "\n\n\n$msg\n\n" &} oops
      }
    }
}

# display CID information
# Input: "$ciddate $cidtime $cidnumber $cidname $cidline\n"
proc displayCID {cid} {
    global Txt

    if {[llength $cid] != 5} { set Txt $cid
    } else { set Txt "[lindex $cid 3]\n[lindex $cid 2]" }
    update
}

# display Call Log
# Input: "$ciddate $cidtime $cidnumber $cidname $cidline\n"
proc displayLog {cid} {
    global Verbose
    global NoGUI
    if $NoGUI {
        if $Verbose {
            puts "[lindex $cid 0] [lindex $cid 1] [lindex $cid 4] [lindex $cid 2] [lindex $cid 3]"
        }
    } else {
        set cid "[lindex $cid 0] [lindex $cid 1] [lindex $cid 4] [lindex $cid 2] [lindex $cid 3]\n"
        .vh configure -state normal
        .vh insert end $cid
        .vh yview moveto 1.0
        .vh configure -state disabled

    }
}

# Open a connection to the CID server
proc connectCID {Host Port} {
    global Try
    global Socket
    global NoGUI

    # open socket to server
    if {[catch {set Socket [socket -async $Host $Port]} msg]} {
        set Try [expr $Try + 1]
        errorMsg "$Host:$Port - $msg\n"
    } else {
        # set socket to binary I/O and non-blocking
        fconfigure $Socket -translation {binary binary} -blocking 0 
        # get response from server as an event
        fileevent $Socket readable getCID
        if $NoGUI { displayLog "Connecting to $Host:$Port"
        } else { displayCID "Connecting to\n$Host:$Port"}
    }
}

proc getArg {} {
    global argc
    global argv
    global All
    global Raw
    global Host
    global Port
    global Delay
    global Usage
    global NoGUI
    global Verbose
    global Program
    global Callprog
    global Ring
    global CallOnRing
    global ProgDir
    global ProgName
    global TivoFlag
    global MsgFlag
    global PIDfile

    for {set cnt 0} {$cnt < $argc} {incr cnt} {
        set optarg [lindex $argv [expr $cnt + 1]]
        switch -regexp -- [set opt [lindex $argv $cnt]] {
            {^-r$} -
            {^--ring$} {
                incr cnt
                if {$optarg != ""
                    && $optarg == -1
                    || [regexp {^[023456789]$} $optarg]} {
                    set Ring $optarg
                    set CallOnRing 1
                } else {exitMsg 4 "Invalid $opt argument: $optarg\n$Usage\n"}
            }
            {^--no-gui$} {set NoGUI 1}
            {^-A$} -
            {^--all$} {set All 1}
            {^-C$} -
            {^--call-prog$} {set Callprog 1}
            {^-D$} -
            {^--delay$} {
                incr cnt
                if {$optarg != ""
                    && [regexp {^[0-9]+$} $optarg]} {
                    set Delay $optarg
                } else {exitMsg 4 "Invalid $opt argument: $optarg\n$Usage\n"}
            }
            {^-M$} -
            {^--message$} {set MsgFlag 1}
            {^-P$} -
            {^--program$} {
                incr cnt
                if {$optarg != ""} {
                    if {[regexp {^.*/} $optarg]} {
                        set Program [list $optarg]
                    } else {set Program [list $ProgDir/$optarg]}
                } else {exitMsg 6 "Missing $opt argument\n$Usage\n"}
            }
            {^-p$} -
            {^--pidfile$} {
                incr cnt
                set PIDfile $optarg
            }
            {^-T$} -
            {^--tivo$} {set TivoFlag 1}
            {^-V$} -
            {^--verbose$} {set Verbose 1}
            {^-R$} -
            {^--raw$} {set Raw 1}
            {^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$} {set Host $opt}
            {^[A-Za-z]+[.A-Za-z0-9-]+$} {set Host $opt}
            {^[0-9]+$} {set Port $opt}
            default {exitMsg 5 "Unknown option: $opt\n$Usage\n"}
        }
    }
}

proc makeWindow {} {
    frame .fr -borderwidth 2
    wm title . "Network Caller ID"
    wm protocol . WM_DELETE_WINDOW exit
    wm resizable . 0 0
    pack .fr

    frame .menubar -relief raised -bd 2
    pack .menubar -in .fr -fill x

    # create and place: call and server message display
    label .md -textvariable Txt -font {Helvetica -14 bold}
    pack .md -side bottom

    # create and place: CID history scroll window
    text .vh -width 62 -height 4 -yscrollcommand ".ys set" \
        -state disabled -font {Courier -14 bold}
    scrollbar .ys -command ".vh yview"
    pack .vh .ys -in .fr -side left -fill y

    # create and place: user message window with a label
    label .spacer -width 10
    label .ml -text "Send Message: "
    text .im -width 25 -height 1 -font {Courier -14}
    pack .spacer .ml .im -side left

    # create menu bar with File and Help
    menubutton .menubar.file -text File -underline 0 -menu .menubar.file.menu
    pack .menubar.file -side left
    menubutton .menubar.help -text Help -underline 0 -menu .menubar.help.menu
    pack .menubar.help -side right

    # create file menu items
    menu .menubar.file.menu -tearoff 0
    .menubar.file.menu add command -label "Clear Log" -command clearLog
    .menubar.file.menu add command -label "Reconnect" -command reconnect
    .menubar.file.menu add command -label Quit -command exit

    # create help menu
    menu .menubar.help.menu -tearoff 0
    .menubar.help.menu add command -label About -command aboutPopup
}

proc aboutPopup {} {
    global About

    option add *Dialog.msg.wrapLength 9i
    option add *Dialog.msg.font "Helvetica 12"
    tk_messageBox -message $About -type ok -title About
}

proc clearLog {} {

    .vh configure -state normal
    .vh delete 1.0 end
    .vh yview moveto 0.0
    .vh configure -state disabled
}

proc reconnect {} {
    global Connect
    global Socket
    global Once
    global Count
    global Host
    global Port

    # connection to server already closed
    if $Count {
        set Count 0
        return
    }

    # close connection to server
    flush $Socket
    fileevent $Socket readable ""
    close $Socket

    # delay for 0.1 seconds
    after [expr 100] waitOnce
    vwait Once

    set Connect 0
    retryConnect
}

# Handle MSG from GUI
proc handleGUIMSG {} {
  global Socket

  # get MSG and clear text input box
  set line [.im get 1.0 end]
  .im delete 1.0 end
  # get rid of non-printable characters at start/end of string
  set line [string trim $line]
  # send MSG, if $line not empty
  if {[string length $line] > 0} {
    puts $Socket $line
    flush $Socket
  }
}

# handle a PID file, if it can not be created, ignore it
proc doPID {} {
    global PIDfile
    global Verbose

    set count 0
    set PIDdir [file dirname $PIDfile]
    if {[file writable $PIDfile]} {
        # get the pid's on the first line of the pidfile
        set chan [open $PIDfile r ]
        gets $chan line
        close $chan
        # see if any pid is active
        foreach p $line {
            if {[file exists /proc/$p]} {set count 1}
        }
        if {$count == 0} {
            # no pid is active, truncate the pidfile
            set chan [open $PIDfile w ]
        } else {
            # at least one pid is active, append to the pidfile
            set chan [open $PIDfile a ]
        }
        writePID $chan
    } elseif {[file writable $PIDdir]} {
        # create the pidfile
        set chan [open $PIDfile "CREAT WRONLY" 0644]
        writePID $chan
    }
    if $Verbose {puts "Using pidfile: $PIDfile"}
}

# get process ID, write it to the pidfile, and close it
proc writePID {chan} {
        set ncidpid [pid]
        puts -nonewline $chan "$ncidpid "
        close $chan
}

getArg
if {!$NoGUI} makeWindow
if $Callprog {
    if {[file exists $Program]} {
        if {![file executable $Program]} {
            # Simple test to see if running under Cygwin
            if {[file exists $CygwinBat]} {
                # The Cygwin TCL cannot execute shell scripts
                set ExecSh 1
            } else {
                exitMsg 2 "Program Not Executable: $Program"
            }
        }
    } else {exitMsg 3 "Program Not Found: $Program"}
    if $Verbose {puts "Using output Module: $Program"}
} else {set Verbose 1}
if {$NoGUI} doPID
connectCID $Host $Port
if {!$NoGUI} {bind .im <KeyPress-Return> handleGUIMSG}

# enter event loop
vwait forever

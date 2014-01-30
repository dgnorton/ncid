#!/bin/sh

# ncid - Network Caller-ID client

# Copyright (c) 2005-2014
#  by John L. Chmielewski <jlc@users.sourceforge.net>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# START OF LOCAL MODIFICATION SECTION
# set TCLSH variable, FreeBSD will call it something like tclsh8.4 \
TCLSH=tclsh
# set WISH variable, FreeBSD will call it something like wish8.4 \
WISH=wish
# set BIN to directory where ncid is installed \
BINDIR=/usr/local/bin
# END OF LOCAL MODIFICATION SECTION

# set nice value on TiVo, if "setpri" found \
type setpri > /dev/null 2>&1 && setpri rr 1 $$
# set up TiVo options to use out2osd \
OPTSTIVO="--no-gui --tivo --program /usr/local/bin/out2osd"
# if name is tivocid, exec tivosh (for backward compatibility) \
case $0 in *tivocid) exec tivosh $BINDIR/ncid $OPTSTIVO "$@"; esac
# set up TiVo options to use ncid-tivo \
OPTSTIVO="--no-gui --program ncid-tivo"
# if name is tivoncid, exec tivosh \
case $0 in *tivoncid) exec tivosh $BINDIR/ncid $OPTSTIVO "$@"; esac
# set location of configuration file (it is also set later on for tcl/tk) \
CF=/usr/local/etc/ncid/ncid.conf
# if config file does not exist, set GUI=1 \
[ -f $CF ] || GUI=1
# if $GUI set, set GUI based on configuration file \
[ -z "$GUI" ] && if grep NoGUI $CF | grep 0 > /dev/null 2>&1; then GUI=1; fi
# if GUI set, look for the --no-gui option, if found set GUI="" \
[ -n "$GUI" ] && for i in $*; do if [ "$i" = "--no-gui" ]; then  GUI=""; fi; done
# if $DISPLAY is not in the environment, set GUI="" \
[ -z "$DISPLAY" ] && GUI=""
# if $GUI is set, look for wish and exec it \
[ -n "$GUI" ] && type $WISH > /dev/null 2>&1 && exec $WISH -f "$0" -- "$@"
# if $GUI is not set, look for tclsh and exec it \
[ -z "$GUI" ] && type $TCLSH > /dev/null 2>&1 && exec $TCLSH "$0" "$@"
# wish not found, look for tclsh and exec it \
type $TCLSH > /dev/null 2>&1 && exec $TCLSH "$0" --no-gui "$@"
# tclsh not found, look for tivosh and exec it \
type tivosh > /dev/null 2>&1 && exec tivosh "$0" --no-gui "$@"
# tivosh not found, maybe using a Macintosh \
[ -d /Applications/Wish\ Shell.app ] && \
    /Applications/Wish\ Shell.app/Contents/MacOS/Wish\ Shell -f "$0" -- "$@"
# tcl or tk not found \
echo "wish or tclsh or tivosh not found or not in your \$PATH"; exit -1

set ConfigDir   /usr/local/etc/ncid
set ConfigFile  "$ConfigDir/ncid.conf"

### Constants
set Logo        /usr/local/share/pixmaps/ncid/ncid.gif
set CygwinBat   /cygwin.bat

if {$::tcl_platform(platform) == "windows"} {
    set ConfigDir [file join $env(ProgramFiles) "ncid"]
    set ConfigFile [file join $ConfigDir "ncidconf.txt"]
    set Logo [file join $ConfigDir "ncid.gif"]
}

### global variables that can be changed by command line options
### or by the configuration file
set Host        127.0.0.1
set Port        3333
set Delay       60
set PIDfile     ""
set PopupTime   5
set Verbose     0
set NoGUI       0
set CallOnRing  0
set TivoFlag    0
set Ring        999
set NoExit      0
set WakeUp      0
set ExitOn      exit
set AltDate     0

###  global variables that only can be changed by the configuration file
set ProgDir     /usr/local/share/ncid
set ProgName    ""
set Country     "US"
set NoOne       0
set DateSepar   "/"
set WrapLines   "char"

### global variables that are used as static variables
set display_line_num    0
set awakened            0
set clock               24
set oldClock            24
set autoSave            "off"
set oldAutoSave         "off"
set Begin               0
set End                 0
set msgType            ""
set waitMsg             0
set mod_menu            0
set multi               0
set mdisabled           0

### global variables that are read from the server
set hangup              0
set ignore1             0

if {[file exists $ConfigFile]} {
    catch {source $ConfigFile}
}

if {$ProgName != ""} {
    if {[regexp {^.*/} $ProgName]} { set Program "$ProgName"
    } else {set Program "$ProgDir/$ProgName"}
} else {set Program ""}

### global variables that are fixed
set Count       0
set ExecSh      0
set Socket      0
set Try         0
set Version     "(NCID) XxXxX"
set VersionInfo "Client: ncid $Version"
set Usage       {Usage:   ncid  [OPTS] [ARGS]
         OPTS: [--no-gui]
               [--alt-date               | -A]                      
               [--delay <seconds>        | -D <delay in seconds>]   
               [--help                   | -h]                      
               [--noexit                 | -X]                      
               [--pidfile <FILE>         | -p <pidfile>]            
               [--PopupTime <1-99>       | -t <1-99 seconds>]       
               [--program <PROGRAM>      | -P <PROGRAM or MODULE>]  
               [--ring <0-9|-1|-2|-9>    | -r <0-9|-1|-2|-9]>       
               [--tivo                   | -T]                      
               [--verbose <[1-9]>        | -v <[1-9]]>              
               [--version                | -V]                      
               [--wakeup                 | -W]                      
         ARGS: [<IP_ADDRESS>             | <HOSTNAME>]              
               [<PORT_NUMBER>]}

set Author \
"
Copyright (C) 2001-2014
John L. Chmielewski
http://ncid.sourceforge.net
"

set About \
"
$VersionInfo
$Author
"

set labList \
"
CID:  Caller ID - incoming call
OUT:  Out       - outgoing call
HUP:  Hangup    - blacklisted call hangup
BLK:  Blocked   - blacklisted call blocked
PID:  Phone ID  - Caller ID from a smart phone
MSG:  Message   - message from a user or NCID
NOT:  Notice    - a smart phone message notice
"

set serverHelp \
"
\"Reload alias file\" menu entry:
    Server reloads its Alias file

If the hangup feature was enabled in the server ncidd.conf
file, the above menu entry item becomes:

\"Reload alias and list files\" menu entry:
    Server reloads its Alias, Blacklist, and Whitelist files.

\"Update current call log\" menu entry:
    Server replaces items in its cidcall.log file with aliases
    in its ncidd.alias file.

\"Update all call logs\" menu entry:
    Server replaces items in its current cidcall.log file and
    previous ones with files with aliases in its ncidd.alias file.

\"Reread call log\" menu entry:
    Server resends the cidcall.log file.

Selecting a line in the history window with a supported alias
type will enable an alias menu entry.  The hangup option also
adds the blacklist and whitelist menu entries.

You can remove a line selection by clicking below the history
window and outside the message input area.

Once you modify an alias, you must:
    Reload the alias file
    Update the current log or all logs
    Reread call log

Once you modify the Blacklist or Whitelist file, you must:
    Reload the alias, blacklist, and whitelist files
"

# display error message and exit
proc exitMsg {code msg} {
    global NoGUI

    if $NoGUI {
        puts stderr $msg
    } else {
        wm withdraw .
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

    # If $Delay == 0, do not try to reconnect
    if (!$Delay) {exit -1}

    if $NoGUI {
        puts -nonewline stderr $msg
        after [expr $Delay*1000] retryConnect
    } else {
        set Count $Delay
        while {$Count > 0} {
            if {$Count == 1} {
                set Txt "$msg Try $Try in $Count second."
            } else {
                set Txt "$msg Try $Try in $Count seconds."
            }
            set Once 0
            set Count [expr $Count - 1]
            after [expr 1000] set Once 1
            vwait Once
        }
        retryConnect
    }
}

# try to connect to CID server again
proc retryConnect {} {
    global Host
    global Port
    global NoGUI

    if $NoGUI { after cancel retryConnect }
    connectCID $Host $Port
}

# close connection to NCID server if open, then reconnect
proc Reconnect {} {
    global Connect
    global Socket
    global waitOne
    global Count

    if $Count {
        # already waiting to reconnect, force a retry
        set Count 0
        return
    }

    if {$Socket > 0} {
        # close connection to server
        flush $Socket
        fileevent $Socket readable ""
        close $Socket
        set Socket 0
    }

    # delay for 0.1 seconds
    set waitOne 0
    after [expr 100] set waitOne 1
    vwait waitOne

    retryConnect
}

# This catches a lot of errors!
proc bgerror {mess} {
    global errorInfo
    global errorCode

    exitMsg 1 "BGError: $mess\n$errorInfo\n$errorCode\n"
}

# Get data from CID server
proc getCID {} {
    global CallOnRing
    global Program
    global cid
    global Connect
    global Host
    global NoGUI
    global Port
    global Ring
    global Socket
    global Try
    global Verbose
    global VersionInfo
    global lineLabel
    global msgType
    global call
    global label
    global display_line_num
    global WakeUp busyIndicator
    global wakened targetTime doingLog Begin End remote_status waitMsg
    global hangup mod_menu argument aliasType ignore1 mdisabled

    set msg {CID connection closed}
    set cnt 0
    while {$cnt != -1} {
        if {[eof $Socket] || [catch {set cnt [gets $Socket dataBlock]} msg]} {
            # remove event handler
            fileevent $Socket readable ""
            close $Socket
            if !$NoGUI {
                set menu .menubar.server
                if $hangup {
                    $menu entryconfigure Reload* -label "Reload alias file"
                    remove .menubar.server 2
                }
                set hangup  0
                set ignore1 0
                $menu entryconfigure Reload* -state disabled
                $menu entryconfigure Update*current* -state disabled
                $menu entryconfigure Update*all*call* -state disabled
                $menu entryconfigure Reread* -state disabled
                set mdisabled 1
            }
            set Try [expr $Try + 1]
            errorMsg "$Host:$Port - $msg\n"
            return
        }
        set Try 0
        if {$mdisabled} {
            set menu .menubar.server
            $menu entryconfigure Reload* -state normal
            $menu entryconfigure Update*current* -state normal
            $menu entryconfigure Update*all*call* -state normal
            $menu entryconfigure Reread* -state normal
            set mdisabled 0
        }
        # get rid of non-printable characters at start/end of string
        set dataBlock [string trim $dataBlock]

        if {[string match 200* $dataBlock]} {
            # output NCID server connect message
            doVerbose $dataBlock 1
            set Begin [clock clicks -milliseconds]
            regsub {200 (.*)} $dataBlock {\1} dataBlock
            if {$Program != ""} {doVerbose "$VersionInfo\n$dataBlock" 1}
            if $NoGUI { 
               displayLog "$VersionInfo\n$dataBlock" 1
               set targetTime 0
            } else {
                set targetTime [expr [clock clicks -milliseconds] + 500]
                .vh configure -state normal
                set doingLog 1
                .vh insert 1.0 "\n\n\t\tReading the call log\n\n"
                update idletasks
                displayCID "$VersionInfo\n$dataBlock" 1
                }
        } elseif {[string match {25[0-3]*} $dataBlock]} {
            # NCID server sent log message
            if !$NoGUI {
                .vh delete 1.0 6.0
                .vh yview moveto 1.0
                .vh configure -state disabled
                if {[lindex [.vh yview] 0] + [lindex [.vh yview] 1] == 1.0} {
                    grid remove .ys
                } else {
                    grid .ys
                }
            }
            set doingLog 0
            if {[regexp {250} $dataBlock]} {
                doVerbose "$dataBlock - $display_line_num lines" 1
            } else {doVerbose "$dataBlock" 1}
            set End [clock clicks -milliseconds]
            set elapsed [expr $End - $Begin]
            doVerbose "$display_line_num entries in $elapsed milliseconds" 4
        } elseif {[string match 300* $dataBlock]} {
            # NCID server sent end of startup message
            doVerbose $dataBlock 1
            if {!$NoGUI && $hangup} {
                addMenuItem
            }
            continue
        } elseif {[string match 400* $dataBlock]} {
            # NCID server has sent text to be displayed
            doVerbose $dataBlock 1
            toplevel .reply
            wm title .reply "Server's Response"
            grid [text .reply.text -yscrollcommand ".reply.ys set" -setgrid 1 \
                     -height 8 -width 70] -pady 10 -padx 10 -sticky nesw
            grid [scrollbar .reply.ys -command ".reply.text yview"] \
                    -column 1 -row 0 -sticky ns -pady 10 -padx 5
            grid [button .reply.btn -text "OK" -command {destroy .reply}] \
                    -pady 10 -columnspan 2
            grid columnconfigure .reply 0 -weight 1
            grid rowconfigure .reply 0 -weight 1
            wm minsize .reply 25 4
            bind .reply <Configure> {
                if {[lindex [.reply.text yview] 0] + [lindex [.reply.text yview] 1] == 1.0} {
                    grid remove .reply.ys
                } else {
                    grid .reply.ys
                }
            }
            modal {.reply}
            continue;
        } elseif {[string match 401* $dataBlock]} {
            # NCID server has sent text to be displayed, must ACCEPT or REJECT
            doVerbose $dataBlock 1
            toplevel .reply
            wm title .reply "Server's Response"
            grid [text .reply.text -yscrollcommand ".reply.ys set" -setgrid 1 \
                    -height 8 -width 70] -pady 10 -padx 10 -sticky nesw
            .reply.text insert 1.0 "\n\n\tUpdating call logs"
            .reply.text configure -state disabled
            grid [scrollbar .reply.ys -command ".reply.text yview"] \
                    -column 1 -row 0 -sticky ns -pady 10 -padx 5
            grid [frame .reply.fr]  -pady 10 -padx 10 -columnspan 2 -row 1
            button .reply.accept_btn -text "Accept" -state disabled -command {
                    global multi

                    if {$multi} {
                        set temp "S"
                    } else {
                        set temp ""
                    }
                    puts $Socket "WRK: ACCEPT LOG$temp"
                    flush $Socket
                    destroy .reply
                    }
            button .reply.reject_btn -text "Reject" -state disabled -command {
                    global multi

                    if {$multi} {
                        set temp "S"
                    } else {
                        set temp ""
                    }
                    puts $Socket "WRK: REJECT LOG$temp"
                    flush $Socket
                    destroy .reply
                    }
            grid .reply.accept_btn .reply.reject_btn -in .reply.fr -padx 25
            grid columnconfigure .reply 0 -weight 1
            grid rowconfigure .reply 0 -weight 1
            wm minsize .reply 40 5
            bind .reply <Configure> {
                if {[lindex [.reply.text yview] 0] + [lindex [.reply.text yview] 1] == 1.0} {
                    grid remove .reply.ys
                } else {
                    grid .reply.ys
                }
            }
            set busyIndicator [showBusy 1000 "." .reply.text]
            set waitMsg 1
            modal {.reply}
            continue;
        } elseif {[string match 402* $dataBlock]} {
            doVerbose $dataBlock 1
            set remote_status ""
        } elseif {[string match 403* $dataBlock]} {
            doVerbose $dataBlock 1
            set mod_menu 1
        } elseif {[string match 410* $dataBlock]} {
            doVerbose $dataBlock 1
            .reply.text configure -state normal
            .reply.text delete end-1chars
            .reply.text configure -state disabled
            .reply.text see end
            catch {
                if {[lindex [.reply.text yview] 0] + [lindex [.reply.text yview] 1] == 1.0} {
                    grid remove .reply.ys
                } else {
                    grid .reply.ys
                }
            }
            catch {
                .reply.accept_btn configure -state normal
                .reply.reject_btn configure -state normal
            }
            continue
        } elseif {[string match 411* $dataBlock]} {
            doVerbose $dataBlock 1
            if {$mod_menu} {
                set mod_menu 0
                continue
            }
            if {[string length $remote_status] < 4} {
                set remote_status "Done."
            }
            .confirm.close configure -state active
        } elseif {[string match INFO:* $dataBlock]} {
            doVerbose $dataBlock 1
            if {$mod_menu} {
                set menu .menubar.server
                set temp [split $dataBlock " "]
                set fileType [lindex $temp 1]
                set argument [lindex $temp 2]
                switch $fileType {
                    alias {
                        set aliasType $argument
                        if {$aliasType eq "NOALIAS"} {
                            $menu entryconfigure Add*Alias* -state normal
                            $menu entryconfigure Modify* -state disabled
                        } elseif {$aliasType eq "NAMEDEP"} {
                            $menu entryconfigure Add*Alias* -state disabled
                            $menu entryconfigure Modify* -state normal
                        } else {
                            # unsupported alias type
                            $menu entryconfigure Add*Alias* -state disabled
                            $menu entryconfigure Modify* -state disabled
                            doVerbose "Unsupported alias type: $aliasType" 1
                        }
                    }
                    black {
                        $menu entryconfigure Add*Black* -state disabled
                        $menu entryconfigure Add*White* -state normal
                        $menu entryconfigure Remove*Black* -state normal
                        $menu entryconfigure Remove*White* -state disabled
                    }
                    white {
                        $menu entryconfigure Add*Black* -state disabled
                        $menu entryconfigure Add*White* -state disabled
                        $menu entryconfigure Remove*Black* -state disabled
                        $menu entryconfigure Remove*White* -state normal
                    }
                    neither {
                        if {$hangup} {
                            $menu entryconfigure Add*Black* -state normal
                            $menu entryconfigure Add*White* -state disabled
                            $menu entryconfigure Remove*Black* -state disabled
                            $menu entryconfigure Remove*White* -state disabled
                        }
                    }
                }
                continue;
            }
            .reply.text configure -state normal
            if {$waitMsg} {
                set waitMsg 0
                after cancel $busyIndicator
                .reply.text delete 1.0 end
            }
            .reply.text insert end [string range [append dataBlock " \n"] 6 end]
            .reply.text configure -state disabled
            continue
        } elseif {[string match RESP:* $dataBlock]} {
            doVerbose $dataBlock 1
            append remote_status [string range $dataBlock 6 end]
            continue
        } elseif {[string match OPT:* $dataBlock]} {
            set option [string trim [string range $dataBlock 5 end]]
            doVerbose $dataBlock 1
            doVerbose "Set $option to 1" 1
            set $option 1
        }
        if {[set label [checkType $dataBlock]]} {
            if {$label == 3} {
                # CIDINFO line
                set ringinfo [getField RING $dataBlock]
                # must use $call($lineinfo) instead of $cid
                set lineinfo [getField LINE $dataBlock]
                if {[array get call $lineinfo] != {}} {
                  if {$CallOnRing} {
                    if {$Program != "" && ($Ring == $ringinfo ||
                        ($Ring == -9 && $ringinfo > 1))} {
                      sendCID $call($lineinfo)
                      doVerbose "$dataBlock" 1
                      doVerbose "Sent $Program: $call($lineinfo)" 1
                    } else { doVerbose "$dataBlock" 5 }
                  }
                } else {
                    doVerbose "Phone line label \"$lineinfo\" not found" 1
                }
                if {$WakeUp && $ringinfo == 1} {
                    doWakeup
                    set wakened 1
                }
            } elseif {$label == 4 || $label == 5} {
                # MSG (4), NOT (4), MSGLOG (5), NOTLOG (5)
                regsub {(^...).*} $dataBlock {\1} msgType
                regsub {[A-Z]+: (.*)} $dataBlock {\1} msg
                displayLog "$msg" 1
                if {$label == 4} {
                    if {!$NoGUI} {
                        displayCID "$msg\n" 1
                        doPopup
                    }
                    if {$Program != ""} {
                        sendMSG $msg
                        doVerbose "Sent $Program $msgType: $msg" 1
                    }
                }
            } elseif {$label == 1 || $label == 2} {
                # CID (1), OUT (1), HUP (2), BLK (2), PID (2)
                if {$WakeUp} {
                    if {!$wakened} {
                        doWakeup
                    } else {set wakened 0}
                }
                set cid [formatCID $dataBlock]
                if {$label == 1} {array set call "$lineLabel [list $cid]"}
                # display log
                # $cid set above, no need for $call($lineLabel)
                displayLog $cid 0
                # display CID
                if {!$NoGUI} {
                    # $cid set above, no need for $call($lineLabel)
                    displayCID $cid 0
                    doPopup
                }
                # $cid set above, no need for $call($lineLabel)
                if {(!$CallOnRing || $Ring == -9) && $Program != ""} {
                    sendCID $cid
                    doVerbose "Sent $Program: $cid" 1
                }
            } elseif {$label == 6} {
                # CIDLOG, HUPLOG, OUTLOG, BLKLOG, PIDLOG
                set cid [formatCID $dataBlock]
                array set call "$lineLabel [list $cid]"
                # display log
                # $cid set above, no need for $call($lineLabel)
                displayLog $cid 0
                if {$targetTime && [clock clicks -milliseconds] >= $targetTime} {
                    set targetTime [expr [clock clicks -milliseconds] + 500]
                    .vh insert 3.end "."
                    update idletasks
                }
            }
        }
    }
}

proc showBusy {delay text widget} {
    global busyIndicator afterDelay afterText afterWidget
    
    $widget configure -state normal
    $widget insert end $text
    $widget configure -state disabled
    set afterDelay $delay
    set afterText $text
    set afterWidget $widget
    set rtn [ after $delay {
            set busyIndicator [showBusy $afterDelay $afterText $afterWidget]
            }
            ]
    
}

proc doWakeup {} {
    global ExecSh
    global ProgDir

    if $ExecSh {
        catch {exec sh -c $ProgDir/ncid-wakeup} oops
    } else {
        catch {exec $ProgDir/ncid-wakeup} oops
    }
}

proc doPopup {} {
    # create a popup for popup time
    # or become top most window for popup time
    global PopupTime
    global ncidwin
    global Verbose

    set ncidwin [wm state .]

    if {$ncidwin == "iconic"} {wm deiconify .}
    # the -topmost option may not be available
    if {[catch {wm attributes . -topmost 1} msg]} {
        raise .
        doVerbose "$msg" 1
    }

    after [expr $PopupTime*1000] {
        # the -topmost option may not be available
        if {[catch {wm attributes . -topmost 0} msg]} {
            doVerbose "$msg" 1
        }
        if {[focus] != "."} {
            if {$ncidwin == "iconic"} {wm iconify .}
        }
    }
}

proc checkType {dataBlock} {
    set rtn 0
    # Determine label type
    if [string match CID:* $dataBlock] {set rtn 1
    } elseif [string match OUT:* $dataBlock] {set rtn 1
    } elseif [string match HUP:* $dataBlock] {set rtn 2
    } elseif [string match BLK:* $dataBlock] {set rtn 2
    } elseif [string match PID:* $dataBlock] {set rtn 2
    } elseif [string match CIDINFO:* $dataBlock] {set rtn 3
    } elseif [string match MSG:* $dataBlock] {set rtn 4
    } elseif [string match NOT:* $dataBlock] {set rtn 4
    } elseif [string match MSGLOG:* $dataBlock] {set rtn 5
    } elseif [string match NOTLOG:* $dataBlock] {set rtn 5
    } elseif [string match CIDLOG:* $dataBlock] {set rtn 6
    } elseif [string match HUPLOG:* $dataBlock] {set rtn 6
    } elseif [string match OUTLOG:* $dataBlock] {set rtn 6
    } elseif [string match BLKLOG:* $dataBlock] {set rtn 6
    } elseif [string match PIDLOG:* $dataBlock] {set rtn 6
    } elseif [string match LOG:* $dataBlock] {set rtn 7}
    doVerbose "Assigned type $rtn for $dataBlock" 6
    return $rtn
}

# must be sure the line passed checkType
proc formatCID {dataBlock} {
    global Country
    global NoOne
    global DateSepar
    global lineLabel
    global label
    global AltDate
    global clock

    set cidname [getField NAME $dataBlock]
    set cidnumber [getField NU*MBE*R $dataBlock]
    if {$Country  == "US"} {
    # https://en.wikipedia.org/wiki/North_American_Numbering_Plan
        if {![regsub \
            {(^1)([0-9]+)([0-9]{3})([0-9]{4})} \
            $cidnumber {\1-\2-\3-\4} cidnumber]} {
            if {![regsub {([0-9]+)([0-9]{3})([0-9]{4})} \
                $cidnumber {\1-\2-\3} cidnumber]} {
                regsub {([0-9]{3})([0-9]{4})} \
                $cidnumber {\1-\2} cidnumber
            }
        } elseif {$NoOne} {
            regsub {^1-?(.*)} $cidnumber {\1} cidnumber
        }
    } elseif {$Country == "SE"} {
      # https://en.wikipedia.org/wiki/Telephone_numbers_in_Sweden#Area_codes
      if {![regsub {^(07[0-9])([0-9]+)} \
          $cidnumber {\1-\2} cidnumber]} {
       if {![regsub {^(08)([0-9]+)} \
           $cidnumber {\1-\2} cidnumber]} {
        if {![regsub {^(01[013689])([0-9]+)} \
            $cidnumber {\1-\2} cidnumber]} {
         if {![regsub {^(0[23][[136])([0-9]+)} \
             $cidnumber {\1-\2} cidnumber]} {
          if {![regsub {^(04[0246])([0-9]+)} \
              $cidnumber {\1-\2} cidnumber]} {
           if {![regsub {^(054)([0-9]+)} \
               $cidnumber {\1-\2} cidnumber]} {
            if {![regsub {^(06[02])([0-9]+)} \
                $cidnumber {\1-\2} cidnumber]} {
             if {![regsub {^(090)([0-9]+)} \
                 $cidnumber {\1-\2} cidnumber]} {
              regsub {^([0-9]{4})([0-9]+)} \
                      $cidnumber {\1-\2} cidnumber
             }
            }
           }
          }
         }
        }
       }
      }
    } elseif {$Country == "UK"} {
      # https://en.wikipedia.org/wiki/United_Kingdom_area_codes
      if {![regsub {^(011[0-9])([0-9]{3})([0-9]+)} \
        $cidnumber {\1-\2-\3} cidnumber]} {
        if {![regsub {^(01[0-9]1)([0-9]{3})([0-9]+)} \
          $cidnumber {\1-\2-\3} cidnumber]} {
          if {![regsub {^(13873|15242|19467)([0-9]{4,5})} \
            $cidnumber {\1-\2} cidnumber]} {
            if {![regsub {^(153)(94|95|96)([0-9]{4,5})} \
              $cidnumber {\1\2-\3} cidnumber]} {
              if {![regsub {^(169)(73|74|77)([0-9]{4,5})} \
                $cidnumber {\1\2-\3} cidnumber]} {
                if {![regsub {^(176)(83|84|87)([0-9]{4,5})} \
                  $cidnumber {\1\2-\3} cidnumber]} {
                  if {![regsub {^(01[0-9]{3})([0-9]+)} \
                    $cidnumber {\1-\2} cidnumber]} {
                    if {![regsub {^(02[0-9])([0-9]{4})([0-9]+)} \
                      $cidnumber {\1-\2-\3} cidnumber]} {
                      if {![regsub {^(0[389][0-9]{2})([0-9]{3})([0-9]+)} \
                        $cidnumber {\1-\2-\3} cidnumber]} {
                        if {![regsub {^(07[0-9]{3})([0-9]+)} \
                          $cidnumber {\1-\2} cidnumber]} {
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    } elseif {$Country == "DE"} {
      # https://en.wikipedia.org/wiki/Area_codes_in_Germany
      if {![regsub {^(0[1-2][0-9])([0-9]+)} \
        $cidnumber {\1-\2} cidnumber]} {
        if {![regsub {^(03[01247]|040)([0-9]+)} \
          $cidnumber {\1-\2} cidnumber]} {
          if {![regsub {^(03[35689][0-9])([0-9]+)} \
            $cidnumber {\1-\2} cidnumber]} {
            if {![regsub {^(0[456789][0-9])([0-9]+)} \
              $cidnumber {\1-\2} cidnumber]} {
            }
          }
        }
      }
    } elseif {$Country == "HR"} {
      # https://en.wikipedia.org/wiki/Telephone_numbers_in_Croatia
      if {![regsub {^(01)([0-9]+)} \
        $cidnumber {\1-\2} cidnumber]} {
        if {![regsub {^(02[0123])([0-9]+)} \
          $cidnumber {\1-\2} cidnumber]} {
          if {![regsub {^(03[12345])([0-9]+)} \
            $cidnumber {\1-\2} cidnumber]} {
            if {![regsub {^(04[0234789])([0-9]+)} \
              $cidnumber {\1-\2} cidnumber]} {
              if {![regsub {^(05[123])([0-9]+)} \
                $cidnumber {\1-\2} cidnumber]} {
                if {![regsub {^(09[125789])([0-9]+)} \
                  $cidnumber {\1-\2} cidnumber]} {
                }
              }
            }
          }
        }
      }
    }

    set ciddate [getField DATE $dataBlock]
    # slash (/) is the default date separator
    if {$AltDate} {
        # Date format: DDMMYY or DDMM
        if {![regsub {([0-9][0-9])([0-9][0-9])([0-9][0-9][0-9][0-9])} \
            $ciddate {\2/\1/\3} ciddate]} {
            regsub {([0-9][0-9])([0-9][0-9].*)} $ciddate {\2/\1} ciddate
        }
    } else {
        # Date format: MMDDYY or MMDD
        if {![regsub {([0-9][0-9])([0-9][0-9])([0-9][0-9][0-9][0-9])} \
            $ciddate {\1/\2/\3} ciddate]} {
            regsub {([0-9][0-9])([0-9][0-9].*)} $ciddate {\1/\2} ciddate
        }
    }
    if {$DateSepar == "-"} {
        # set hyphen (-) as date separator
        regsub -all {/} $ciddate - ciddate
    } elseif {$DateSepar == "."} {
        # set period (.) as date separator
        regsub -all {/} $ciddate . ciddate
    }
    set cidtime [getField TIME $dataBlock]
    regexp {(\d{2})(\d{2})} $cidtime time hours minutes
    if {$clock == 24} {
        set cidtime "$hours:$minutes"
    } else {
       set cidtime [convertTo12 $hours $minutes]
    }
    set cidline ""
    if [string match {*\*LINE\**} $dataBlock] {
        set cidline [getField LINE $dataBlock]
    }
    # set default line indicator, if needed
    if {$cidline == ""} {set cidline -}
    # create call line label
    set lineLabel $cidline
    # make default line indicator a blank
    regsub {[-]} $cidline {} cidline
    # set type of call
    if {![regsub {(\w+)LOG:.*} $dataBlock {\1} cidtype]} {
        regsub {(\w+):.*} $dataBlock {\1} cidtype
    }

    return [list $ciddate $cidtime $cidnumber $cidname $cidline $cidtype]
}

proc convertTo12 {hours minutes} {
    set AmPm "am"
    if {$hours > 12} {
        set hours [expr $hours - 12]
        set AmPm "pm"
    } elseif {$hours == 12} {
        set AmPm "pm"
    } elseif {$hours == 0} {
        set hours 12
    }
    regsub {^(0|\s|)?(\d)$} $hours { \2} hours
    return "$hours:$minutes $AmPm"
}

proc convertTo24 {hours minutes AmPm} {
    if {$hours == 12 && $AmPm eq "am"} {
        set hours 0
    } elseif {$hours != 12 && $AmPm eq "pm"} {
        set hours [expr $hours + 12]
    }
    regsub {^(0|\s|)?(\d)$} $hours {0\2} hours
    return "$hours:$minutes"
}

# get a field from the CID data
proc getField {dataString dataBlock} {
    regsub ".*\\*$dataString\\*" $dataBlock {} result
    regsub {(\**[\w\s-]*\**)\*.*} $result {\1} result
    return $result
}

# pass the CID information to an external program
# Input: "$ciddate $cidtime $cidnumber $cidname $cidline $cidtype\n"
proc sendCID {cid} {
    global Program
    global TivoFlag
    global ExecSh
    global ProgDir
    global WakeUp

      if $TivoFlag {
        # pass NAME NUMBER\nLINE\n
        catch {exec $Program << \
          "[lindex $cid 3] [lindex $cid 2]\n[lindex $cid 4]\n" > @stdout} oops
      } else {
        # pass DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n
        if $ExecSh {
          catch {exec sh -c $Program << \
            "[lindex $cid 0]\n[lindex $cid 1]\n[lindex $cid 2]\n[lindex $cid 3]\n[lindex $cid 4]\n[lindex $cid 5]\n > @stdout" &} oops
        } else {
          catch {exec $Program << \
            "[lindex $cid 0]\n[lindex $cid 1]\n[lindex $cid 2]\n[lindex $cid 3]\n[lindex $cid 4]\n[lindex $cid 5]\n > @stdout" &} oops
        }
      }
}

# pass the MSG information to an external program
# Input: "$msg"
proc sendMSG {msg} {
    global Program
    global TivoFlag
    global ExecSh
    global msgType

    if $TivoFlag {
      # send "$msg\n"
      catch {exec [lindex $Program 0] << "$msg\n" > @stdout} oops
    } else {
      # send "\n\n\n$msg\n\n$msgType\n"
      # not: "$ciddate\n$cidtime\n$cidnumber\n$cidname\n$cidline\n$cidtype\n"
      if $ExecSh {
        catch {exec sh -c $Program << "\n\n\n$msg\n\n$msgType\n" > @stdout} oops
      } else {
        catch {exec $Program << "\n\n\n$msg\n\n$msgType\n" > @stdout} oops
      }
    }
}

# display CID information or message
# Input: "$ciddate $cidtime $cidnumber $cidname $cidline $cidtype\n"
#        "mesage line"
# ismsg = 0 for CID and 1 for message
proc displayCID {cid ismsg} {
    global Txt

    if {$ismsg} { set Txt $cid
    } else { set Txt "[lindex $cid 3]\n[lindex $cid 2]" }
}

# display Call Log
# Input: "$ciddate $cidtime $cidnumber $cidname $cidline $cidtype\n"
# Input: "message"
proc displayLog {cid ismsg} {
    global Program
    global NoGUI
    global msgType
    global display_line_num maxNumberWidth doingLog
    
    if $NoGUI {
        if {$Program == ""} {
            if $ismsg {
                puts $cid
            } else {
                puts "[lindex $cid 0] [lindex $cid 1]  [lindex $cid 5] [lindex $cid 4] [lindex $cid 2] [lindex $cid 3]"
            }
        }
        incr display_line_num
    } else {
        incr display_line_num
        if {! $doingLog} {.vh configure -state normal}
        if $ismsg {
            .vh insert end "\n$msgType: " purple $cid blue
        } else {
            set ciddate [lindex $cid 0]
            set cidtime [lindex $cid 1]
            set cidnmbr [format "%-${maxNumberWidth}s " [lindex $cid 2]]
            set cidname [lindex $cid 3]
            set cidline [format "%-4s " [lindex $cid 4]]
            set cidtype [lindex $cid 5]

            .vh insert end "\n$cidtype: " purple "$ciddate " \
                    blue "$cidtime " red $cidline purple $cidnmbr blue \
                    "$cidname" red
        }
        if {! $doingLog} {
            if {$display_line_num == 1} {
                .vh delete 1.0 2.0
            }
            .vh yview moveto 1.0
            .vh configure -state disabled
            if {[lindex [.vh yview] 0] + [lindex [.vh yview] 1] == 1.0} {
                grid .ys
            }
        }
    }
}

# Open a connection to the NCID server
proc connectCID {Host Port} {
    global Try
    global Socket
    global NoGUI

    # open socket to server
    if {[catch {set Socket [socket $Host $Port]} msg]} {
        set Try [expr $Try + 1]
        errorMsg "$Host:$Port - $msg\n"
    } else {
        # set socket to non-blocking
        fconfigure $Socket -blocking 0 
        # get response from server as an event
        fileevent $Socket readable getCID
        if $NoGUI { displayLog "Connected to $Host:$Port" 1
        } else {
            clearLog
            displayCID "Connected to\n$Host:$Port" 1
        }
    }
}

proc getArg {} {
    global argc
    global argv
    global Host
    global Port
    global Delay
    global Usage
    global NoGUI
    global Verbose
    global Program
    global Ring
    global CallOnRing
    global ProgDir
    global TivoFlag
    global PIDfile
    global PopupTime
    global NoExit
    global AltDate
    global WakeUp
    global Version
    global WrapLines

    set showUsage 0;
    for {set cnt 0} {$cnt < $argc} {incr cnt} {
        set optarg [lindex $argv [expr $cnt + 1]]
        switch -regexp -- [set opt [lindex $argv $cnt]] {
            {^-r$} -
            {^--ring$} {
                incr cnt
                if {$optarg != ""
                    && [regexp {^-[129]$} $optarg]
                    || [regexp {^[0123456789]$} $optarg]} {
                    set Ring $optarg
                    set CallOnRing 1
                } else {exitMsg 4 "Invalid $opt argument: $optarg\n$Usage\n"}
            }
            {^--no-gui$} {set NoGUI 1}
            {^-A$} -
            {^--alt-date$} {set AltDate 1}
            {^-C$} -
            {^--classic-display$} {set Classic 1 # obsolete, can be removed}
            {^-D$} -
            {^--delay$} {
                incr cnt
                if {$optarg != ""
                    && [regexp {^[0-9]+$} $optarg]} {
                    set Delay $optarg
                } else {exitMsg 4 "Invalid $opt argument: $optarg\n$Usage\n"}
            }
            {^-h$} -
            {^--help$} {set showUsage 1}
            {^-M$} -
            {^--message$} {set MsgFlag 1; # obsolete, can be removed}
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
            {^-t$} -
            {^--PopupTime$} {
                incr cnt
                if {$optarg != ""
                    && [regexp {^[1-9][0-9]?$} $optarg]} {
                    set PopupTime $optarg
                } else {exitMsg 4 "Invalid $opt argument: $optarg\n$Usage\n"}
            }
            {^-v$} -
            {^--verbose$} {
                incr cnt
                if {$optarg != ""
                    && [regexp {^[1-9]+$} $optarg]} {
                    set Verbose $optarg
                } else {exitMsg 4 "Invalid $opt argument: $optarg\n$Usage\n"}
            }
            {^-V$} -
            {^--version$} {
                puts $Version
                exit 0
            }
            {^-X} -
            {^--noexit} {set NoExit 1}
            {^-W$} -
            {^--wakeup$} {set WakeUp 1}
            {^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$} {set Host $opt}
            {^[A-Za-z]+[.A-Za-z0-9-]+$} {set Host $opt}
            {^[0-9]+$} {set Port $opt}
            default {exitMsg 5 "Unknown option: $opt\n$Usage\n"}
        }
    }
    if {$showUsage} {
        exitMsg 1 "$Usage\n"
    }
}

proc do_nothing {} {
}

proc makeWindow {} {
    global ExitOn
    global env
    global rcfile Verbose WrapLines
    global fontList clock oldClock autoSave oldAutoSave m maxNumberWidth NoOne
    global hangup

    doVerbose "Platform: $::tcl_platform(platform)\nOS: $::tcl_platform(os)" 1
    switch $::tcl_platform(platform) {
      "unix" {
        # Macintosh
        if {$::tcl_platform(os) == "Darwin"} {
          set rcfile [file join \
              $env(HOME)/Library/Preferences "ncid gui preferences"]
        } else {
          # UNIX or Linux
          set rcfile "$env(HOME)/.ncid"
        }
      }
      "windows" {
        set rcfile [file join $env(AppData) "ncid.dat"]
      }
    }

    if [expr [file exists $rcfile] && [file isfile $rcfile]] {
        set id [open $rcfile]
        set data [read $id]
        close $id
        set lines [split $data "\n"]
        foreach line $lines {
            if [regexp {geometry\s+\S+\s+[0-9x]+} $line] {
                eval $line
            } elseif [regexp {font\s+create} $line] {
                eval $line
            } elseif [regexp {(:?fontList|clock|autoSave)\s+} $line] {
                eval $line
            }
        }
    }
    set oldClock $clock
    set oldAutoSave $autoSave
    set auto [expr \"$autoSave\" eq \"off\" ? \"normal\" : \"disabled\"]
    if {![info exists fontList]} {
        scanFonts
    }
    if {[catch {font configure FixedFontH}]} {
        if {[catch {font configure currentFontH}]} {
            set currentFont [lindex $fontList 0]
        }
        font create FixedFontH -family "$currentFont" -size 11
        font create FixedFontM -family "$currentFont" -size 12
        write_rc_file "FixedFontH" \
                "font create FixedFontH [font configure FixedFontH]"
        write_rc_file "FixedFontM" \
                "font create FixedFontM [font configure FixedFontM]"
    }

    wm title . "Network Caller ID"
    wm protocol . WM_DELETE_WINDOW $ExitOn

    # menu options: no tearoff and help menu on far right
    option add *background #d9d9d9
    option add *highlightBackground #d9d9d9
    option add *tearOff 0
    option add *Menu.useMotifHelp 1
    option add *Text.relief sunken
    option add *Text.background #f0f0ff
    option add *Text.borderWidth 2
    option add *highlightThickness 1

    # create menubar
    menu .menubar
    . configure -menu .menubar
    . configure -background #d9d9d9

    # create File, Preferences and Help menus
    set m .menubar
    menu $m.file
    menu $m.file.auto
    menu $m.server
    menu $m.prefs
    menu $m.help
    $m add cascade -menu $m.file -label File -underline 0
    $m add cascade -menu $m.server -label Server -underline 0
    $m add cascade -menu $m.prefs -label Preferences -underline 0
    $m add cascade -menu $m.help -label Help -underline 0

    # create File menu items
    $m.file add command -label "Clear Log" -command clearLog
    $m.file add command -label "Reconnect" -command Reconnect
    $m.file add separator
    $m.file add cascade -menu $m.file.auto -label "Auto Save"
    $m.file add command -label "Save Size" -state $auto -command {saveSize 0}
    $m.file add command -label "Save Size & Pos" -state $auto -command {saveSize 1}
    $m.file add separator
    $m.file add command -label Quit -command exit

    $m.file.auto add radiobutton -label "Size" -variable autoSave -value "size" -command {logAuto $m.file}
    $m.file.auto add radiobutton -label "Size & Position" -variable autoSave -value "both" -command {logAuto $m.file}
    $m.file.auto add radiobutton -label "Off" -variable autoSave -value "off" -command {logAuto $m.file}

    # create Server menu items
    $m.server add command -label "Reload alias file" -command {
                Disable $m
                puts $Socket "REQ: RELOAD"
                flush $Socket
            }
    $m.server add command -label "Update current call log" -command {
                global multi

                Disable $m
                puts $Socket "REQ: UPDATE"
                flush $Socket
                set multi 0
            }
    $m.server add command -label "Update all call logs" -command {
                global multi

                Disable $m
                puts $Socket "REQ: UPDATES"
                flush $Socket
                set multi 1
            }
    $m.server add command -label "Reread call log" -command {
                global display_line_num
                set display_line_num 0
                .vh configure -state normal
                .vh delete 1.0 end
                set doingLog 1
                .vh insert 1.0 "\n\n\t\tReading the call log\n\n"
                Disable $m
                puts $Socket "REQ: REREAD"
                flush $Socket
            }
    $m.server add separator
    $m.server add command -label "Add to Alias File" -state disabled -command {
                DoList alias add "[.vh dump -text sel.first sel.last]" ""
            }
    $m.server add command -label "Modify or Remove Alias" -state disabled -command {
                DoList alias modify "[.vh dump -text sel.first sel.last]" ""
            }

    # create Preferences menu items
    $m.prefs add command -label "Font..." -command {changeFont}
    $m.prefs add separator
    $m.prefs add radiobutton -label "12 hour time" -variable clock -value 12 -command {logClock .vh}
    $m.prefs add radiobutton -label "24 hour time" -variable clock -value 24 -command {logClock .vh}

    # create Help menu item
    $m.help add command -label About -command aboutPopup
    $m.help add command -label "Line Labels" -command labInfo
    $m.help add command -label "Server Menu" -command serverInfo

    # create and place: CID history scroll window
    text .vh -width 57 -height 4 -yscrollcommand ".ys set" \
        -state disabled -font {FixedFontH} -setgrid 1 -wrap $WrapLines
    scrollbar .ys -command ".vh yview"
    grid .vh -row 1 -sticky nsew -padx 2 -pady 2
    grid .ys -row 1 -column 1 -sticky ns -pady 2

    # create and place: user message window with a label
    frame .fr
    grid .fr -row 2 -columnspan 2
    label .ml -text "Send Message: " -height 1 -font {FixedFontM} -fg blue
    text .im -width 25 -height 1 -font {FixedFontM} -fg red
    grid .ml .im -in .fr

    # create and place: call and server message display
    label .md -textvariable Txt -font {FixedFontM} -fg blue -height 2
    grid .md -row 3 -sticky ew -columnspan 2
    
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 1 -weight 1

    update
    set geometry [wm grid .]
    wm minsize . [lindex $geometry 0] [lindex $geometry 1]

    switch $autoSave {
        "size" {
            $m.file entryconfigure Quit -command {saveSize 0; exit}
            wm protocol . WM_DELETE_WINDOW {saveSize 0; $ExitOn}
        }
        "both" {
            $m.file entryconfigure Quit -command {saveSize 1; exit}
            wm protocol . WM_DELETE_WINDOW {saveSize 1; $ExitOn}
        }
    }
    .vh tag configure blue -foreground blue
    .vh tag configure red -foreground red
    .vh tag configure purple -foreground purple
    if $NoOne {set maxNumberWidth 12} else {set maxNumberWidth 14}

    if {$Verbose >= 4} {
        set temp "[font configure FixedFontH]"
        regsub {\s+\-slant.+$} $temp {} temp
        puts "History window font set to: $temp"
        set temp "[font configure FixedFontM]"
        regsub {\s+\-slant.+$} $temp "" temp
        puts "Message window and display font set to: $temp"
        set temp [wm geometry .]
        regsub {(\d+x\d+)\+(\d+)\+(\d+)} $temp {\1 at x=\2 y=\3} temp
        puts "Window geometry set to: $temp"
    }
    bind . <Configure> {
            if {[lindex [.vh yview] 0] + [lindex [.vh yview] 1] == 1.0} {
                grid remove .ys
            } else {
                grid .ys
            }
    }
    bind .fr  <Button-1> {
        Disable $m
    }
    bind .ml  <Button-1> {
        Disable $m
    }
    bind .md  <Button-1> {
        Disable $m
    }
    bind .vh <ButtonRelease-1> {
        .vh tag remove sel 1.0 end
        set first [.vh index @%x,%ylinestart]
        set last [.vh index @%x,%ylineend]
        .vh tag add sel $first $last
        .vh mark unset anchor
        .vh mark unset tk::anchor1
        .vh mark set insert 1.0
        .vh mark set current 1.0
        set dataDump [.vh dump -text $first $last]
        set dataDump1 [.vh dump $first $last]
        set label [string trimright [lindex $dataDump 1]]
        set number [string trimright [lindex $dataDump 13]]
        set name [string trimright [lindex $dataDump 16]]
        set selected [.vh get $first $last]
        if {[regexp {[0-9]+-} $number]} {
            set number [regsub -all -- {-} $number ""]
        }
        if {$label eq "MSG:" || $label eq "NOT:"} {
            doVerbose "$label unsupported line label" 1
            set menu .menubar.server
            $menu entryconfigure Add*Alias* -state disabled
            $menu entryconfigure Modify* -state disabled
        } else {
            if {!$Try} {
                puts $Socket "REQ: INFO $number&&$name"
                flush $Socket
                doVerbose "REQ: INFO $number&&$name" 1
            } else { doVerbose "Server not connected for a REQ: INFO" 1}
        }
        break
    }
}

proc addMenuItem {} {
    set menu .menubar.server
    $menu add separator
    $menu add command -label "Add to Blacklist File" -state disabled -command {
                DoList black add "[.vh dump -text sel.first sel.last]" ""
            }
    $menu add command -label "Remove from Blacklist File" -state disabled -command {
                global argument
                DoList black remove "[.vh dump -text sel.first sel.last]" $argument
            }
    $menu add command -label "Add to Whitelist File" -state disabled -command {
                DoList white add "[.vh dump -text sel.first sel.last]" ""
            }
    $menu add command -label "Remove from Whitelist File" -state disabled -command {
                global argument
                DoList white remove "[.vh dump -text sel.first sel.last]" $argument
            }
    $menu entryconfigure Reload* -label "Reload alias and list files"
}

proc Disable {menu} {
    .vh tag remove sel 1.0 end
    set last [$menu.server index last]
    set found 0
    for {set index 0} {$index <= $last} {incr index} {
        set type [$menu.server type $index]
        if {! $found && $type eq "separator"} {
            set found 1
            continue
        }
        if {$found && $type ne "separator"} {
            $menu.server entryconfigure $index -state disabled
        }
    }
}

proc remove {menu block} {
    set last [$menu index last]
    set found [expr $block == 0 ? 1 : 0]
    for {set index 0} {$index <= $last} {incr index} {
        set type [$menu type $index]
        if {$found} {
            $menu delete $index
            set index [expr $index - 1]
            if {$type eq "separator"} {
                break
            }
        } elseif {$type eq "separator"} {
            set block [expr $block - 1]
            set found [expr $block == 0 ? 1 : 0]
            continue
        }
    }
}

proc DoList {list action entry which} {
    global entry_ action_ list_ remote_status replace_ comment_ name_
    global aliasType ignore1
    set comment_ ""
    
    set entry [list [string trim [lindex $entry 13]] [string trim [lindex $entry 16]]]
    if {$ignore1} {regsub {1-(.*)} $entry {\1} entry}
    set entry_ [lindex $entry 0]
    toplevel .confirm
    wm title .confirm "Confirmation"
    wm resizable .confirm 0 0
    if {[lindex $entry 1] eq "NO NAME"} {
        set entry [lreplace $entry 1 1]
    }
    set action_ $action
    set list_ $list
    set name_ [lindex $entry 1]
    if {$list eq "black" || $list eq "white"} {
        if {$action eq "add"} {
            set _entry [join $entry "\" or \""]
        } elseif {$which eq "name"} {
            set entry_ [set _entry [lindex $entry 1]]
            set entry ""
        } else {
            set entry_ [set _entry [lindex $entry 0]]
            set entry ""
        }
        set _action [string toupper $action 0 0]
        set prep [expr {$action} eq "{add}" ? "{to}" : "{from}"]
        grid [label .confirm.lab -text "$_action \"$_entry\"\n$prep the server's ${list}list"] \
                -columnspan 2 -padx 12 -pady 10
        if {[llength $entry] == 2} {
            grid [radiobutton .confirm.rb1 -text [lindex $entry 0] -variable entry_ \
                    -value [lindex $entry 0]] -pady 5 -columnspan 2
            grid [radiobutton .confirm.rb2 -text [lindex $entry 1] -variable entry_ \
                    -value [lindex $entry 1]] -pady 5 -columnspan 2
            set row 3
        } else {
            set row 1
        }
        if {$action eq "add"} {
            grid [label .confirm.lab1 -text "Comment:"] -sticky w
            grid [entry .confirm.entry -textvariable comment_] -sticky ew -columnspan 2 -padx 8
            set row [expr $row + 2]
        }
    } elseif {$action eq "modify"} {
        set temp [lindex $entry 0]
        set temp1 [lindex $entry 1]
        set replace_ $temp1
        grid [label .confirm.lab -text "Change the association of $temp\nfrom $temp1 to the\nvalue entered below for future calls."] \
                -columnspan 2 -padx 12 -pady 10
        grid [entry .confirm.entry -textvariable replace_] -columnspan 2 -padx 12 -pady 10
        .confirm.entry selection range 0 end
        focus .confirm.entry
        set row 2
    } else {
        set replace_ ""
        grid [label .confirm.lab -text "Associate  the value entered below\nwith $entry for future calls."] \
                -columnspan 2 -padx 12 -pady 10
        grid [entry .confirm.entry -textvariable replace_] -columnspan 2 -padx 12 -pady 10
        focus .confirm.entry
        set row 2
    }
    grid [frame .confirm.fr] -pady 10 -columnspan 2 -row $row
    incr row
    grid [label .confirm.fr.lab1 -text "Status:"] -padx 3
    grid [label .confirm.fr.lab2 -textvariable remote_status] -column 1 -row 0 -padx 3
    grid [button .confirm.cancel -text "Cancel" -command {destroy .confirm}] \
             -pady 10
    if {$list eq "alias"} {
        if {$aliasType eq "NOALIAS"} { set aliasType "NAMEDEP" } 
        grid [button .confirm.ok -text "Apply" -command {doit $action_ $list_ $entry_&&$replace_ "$aliasType&&$name_"}] \
                 -pady 10 -row $row -column 1
    } else {
        grid [button .confirm.ok -text "Apply" -command {doit $action_ $list_ $entry_ $comment_}] \
                 -pady 10 -row $row -column 1
    }
    incr row
    grid [button .confirm.close -text "Close"  -command {
            Disable .menubar
            destroy .confirm} \
             -state disabled ] -columnspan 2 -row $row -pady 10
    grid remove .confirm.close
    set remote_status "Waiting for user action..."
    modal {.confirm}
}

proc doit {action list entry extra} {
    global Socket  remote_status Try

    if {$Try} {
        set remote_status "Server not connected ..."
        doVerbose "Server not connected for a REQ:" 1
        return
    }
    set remote_status "Working ..."
    grid forget .confirm.cancel .confirm.ok
    grid .confirm.close
    puts $Socket "REQ: $list $action \"$entry\" \"$extra\""
    flush $Socket
    doVerbose "REQ: $list $action \"$entry\" \"$extra\"" 1
}

proc aboutPopup {} {
    global About
    global Logo

    if [file exists $Logo] {
        image create photo ncid -file $Logo
        option add *Dialog.msg.image ncid
        option add *Dialog.msg.compound top
    }

    option add *Dialog.msg.wrapLength 9i
    option add *Dialog.msg.font "Helvetica 14"
    tk_messageBox -message $About -type ok -title About
}

proc labInfo {} {
    global labList
    global Logo

    if [file exists $Logo] {
        image create photo ncid -file $Logo
        option add *Dialog.msg.image ncid
        option add *Dialog.msg.compound top
    }

    option add *Dialog.msg.wrapLength 9i
    option add *Dialog.msg.font FixedFontM
    tk_messageBox -message $labList -type ok -title "Line Label Descriptions"
}

proc serverInfo {} {
    global serverHelp
    global Logo

    if [file exists $Logo] {
        image create photo ncid -file $Logo
        option add *Dialog.msg.image ncid
        option add *Dialog.msg.compound top
    }

    option add *Dialog.msg.wrapLength 9i
    option add *Dialog.msg.font FixedFontM
    tk_messageBox -message $serverHelp -type ok -title "Server Menu Help"
}

proc clearLog {} {
    global display_line_num

    set display_line_num 0
    .vh configure -state normal
    .vh delete 1.0 end
    .vh yview moveto 0.0
    .vh configure -state disabled
}

proc saveSize {flag} {
    global Txt
    
    set save $Txt
    set Txt ""
    update
    set geometry [wm geometry .]
    set Txt $save
    if {$flag == 0} {
        regexp {(\d+x\d+)\+} $geometry -> geometry
    }
    write_rc_file "geometry\\s+\\S+\\s+\[0-9x\]+" "wm geometry . $geometry"
}

proc write_rc_file {regexpr command} {
    global rcfile

    if [file exists $rcfile] {
        if [file isdirectory $rcfile] {
            doVerbose "Unable to save data to $rcfile because it is a directory" 1
            return
        }
        set id [open $rcfile]
        set data [read $id]
        close $id
        set lines [lrange [split $data "\n"] 0 end-1]
        set index 0
        foreach line $lines {
            if [regexp $regexpr $line] {
                break
            }
        incr index
        }
        if {$index >= [llength $lines]} {
            lappend lines "$command"
        } else {
            lset lines $index "$command"
        }
        set data [join $lines "\n"]
        set id [open $rcfile w]
        puts $id $data
    } else {
        set id [open $rcfile w]
        puts $id $command
    }
    close $id
}

# Change Font
proc changeFont {} {
    global fontList
    global spinvalH
    global spinvalM
    global boldH
    global boldM
    global SelectionFontH

    toplevel .f
    wm title .f "Change Fixed Font"
    wm resizable .f 0 0

    eval [concat {font create SelectionFontH} [font configure FixedFontH]]
    eval [concat {font create SelectionFontM} [font configure FixedFontM]]
    set spinvalH [font configure FixedFontH -size]
    set boldH [font configure FixedFontH -weight]
    set spinvalM [font configure FixedFontM -size]
    set boldM [font configure FixedFontM -weight]
    set currentFont [font configure FixedFontH -family]
    
    grid [labelframe .f.fn -text "Font Name" -labelanchor "nw"] -pady 8 -padx 4 -sticky "ew"
    grid [ttk::combobox .f.fn.cb -values $fontList -textvariable currentFont] -padx 15 -pady 5
    grid [button .f.fn.btn -text "Re-scan"] -column 0 -row 1 -pady 5
    .f.fn.cb set $currentFont

    grid [labelframe .f.fh -text "History Window Font" -labelanchor "nw"] -column 0 -pady 8 -padx 4 -sticky "ew"
    grid [checkbutton .f.fh.cb -text "Bold" -variable boldH -onvalue "bold" \
                -offvalue "normal" -command \
                {font configure SelectionFontH -weight $boldH}] -pady 5 -padx 5
    grid [label .f.fh.label -text "Size: "] -column 1 -row 0 -pady 5 -padx 5
    grid [spinbox .f.fh.size -from 8 -to 36 -width 3 -textvariable spinvalH \
                -state readonly -command {font configure SelectionFontH -size $spinvalH}] \
                -column 2 -row 0 -pady 5 -padx 5
    grid [label .f.fh.sample -text "Sample text 0123456789" -font SelectionFontH] -row 1 -columnspan 3 -pady 5

    grid [labelframe .f.fm -text "Message Font" -labelanchor "nw"] -column 0  -pady 8 -padx 4 -sticky "ew"
    grid [checkbutton .f.fm.cb -text "Bold" -variable boldM  -onvalue "bold" \
                -offvalue "normal" -command \
                {font configure SelectionFontM -weight $boldM}] -pady 5 -padx 5
    grid [label .f.fm.label -text "Size: "] -column 1 -row 0 -pady 5 -padx 5
    grid [spinbox .f.fm.size -from 8 -to 36 -width 3 -textvariable spinvalM \
                -state readonly -command {font configure SelectionFontM -size $spinvalM}] \
                -column 2 -row 0 -pady 5
    grid [label .f.fm.sample -text "Sample text 0123456789" -font SelectionFontM] -row 1 -columnspan 3 -pady 5

    grid [frame .f.f]  -column 0 -sticky "ew" -pady 8
    grid [button .f.f.cancel -text "Cancel"] -padx 10 -pady 6
    grid [button .f.f.apply -text "Apply"] -column 1 -row 0 -padx 10
    grid [button .f.f.ok -text "OK"] -column 2 -row 0 -padx 10

    # change font family
    bind all <<ComboboxSelected>> {
        font configure SelectionFontH -family "$currentFont"
        font configure SelectionFontM -family "$currentFont"
    }

    bind Button <ButtonRelease-1> {+
        set temp [%W cget -text]
        switch $temp {
            "Cancel" {
                destroy .f
                break
            }
            "OK" -
            "Apply" {
                font configure FixedFontH -family "$currentFont" \
                    -size $spinvalH -weight $boldH
                font configure FixedFontM -family "$currentFont" \
                    -size $spinvalM -weight $boldM
                logFont
                if {$temp eq "OK"} {
                    destroy .f
                }
                break
            }
            "Re-scan" {
                .f.fn.cb configure -values {}
                unset fontList
                scanFonts
                .f.fn.cb configure -values $fontList
                break
            }
        }
    }

    modal {.f}

    font delete SelectionFontH
    font delete SelectionFontM
}

proc logFont {} {
    set tempH "[font configure FixedFontH]"
    set tempM "[font configure FixedFontM]"
    write_rc_file "FixedFontH" "font create FixedFontH $tempH"
    write_rc_file "FixedFontM" "font create FixedFontM $tempM"
    doVerbose "history window font set to: $tempH" 1
    doVerbose "message window and display font set to: $tempM" 1
}

proc logClock {widget} {
    global  clock oldClock

    if {$clock == $oldClock} { return }
    set oldClock $clock
    write_rc_file "set clock" "set clock $clock"
    doVerbose "Time display has been changed to: $clock hours" 1
    $widget configure -state normal
    for {set line 0} {1} {incr line} {
        set temp [$widget dump -text "1.0 + $line l" "1.0 + $line l lineend"]
        if {$temp eq ""} {break}
        if {![regexp {^(?:CID|HUP|OUT)} [lindex $temp 1]]} {continue}
        set time [lindex $temp 7]
        set start [lindex $temp 8]
        set stop [lindex $temp 11]
        if {$clock == 12} {
            set hours [string range $time 0 1]
            set minutes [string range $time 3 4]
            set time [convertTo12 $hours $minutes]
        } else {
            set hours [string range $time 0 1]
            set minutes [string range $time 3 4]
            set AmPm [string range $time 6 7]
            set time [convertTo24 $hours $minutes $AmPm]
        }
        $widget insert "$stop - 1 c" "$time"
        $widget delete "$start" "$stop - 1 c"
    }
    $widget configure -state disabled
}

proc logAuto {menu} {
    global      ExitOn autoSave oldAutoSave m

    if {$autoSave eq $oldAutoSave} { return }
    set oldAutoSave $autoSave
    write_rc_file "set autoSave" "set autoSave \"$autoSave\""
    switch $autoSave {
        "size" {
            set temp "save size only"
            $menu entryconfigure *Size -state disabled
            $menu entryconfigure *Pos -state disabled
            $menu entryconfigure Quit -command {saveSize 0; exit}
            wm protocol . WM_DELETE_WINDOW {saveSize 0; $ExitOn}
        }
        "both" {
            set temp "save size and position"
            $menu entryconfigure *Size -state disabled
            $menu entryconfigure *Pos -state disabled
            $menu entryconfigure Quit -command {saveSize 1; exit}
            wm protocol . WM_DELETE_WINDOW {saveSize 1; $ExitOn}
        }
        "off" {
            set temp "off"
            $menu entryconfigure *Size -state normal
            $menu entryconfigure *Pos -state normal
            $menu entryconfigure Quit -command {exit}
            wm protocol . WM_DELETE_WINDOW $ExitOn
        }
    }
    doVerbose "Auto save has been set to $temp" 1
}

# Handle MSG from GUI
proc handleGUIMSG {} {

  # get MSG and clear text input box
  set line [.im get 1.0 end]
  .im delete 1.0 end
  # get rid of non-printable characters at start/end of string
  set line [string trim $line]
  # send MSG to server, if $line not empty
  if {[string length $line] > 0} {handleMSG $line}
}

# Handle MSG sent to server
proc handleMSG {msg} {
  global Socket

  puts $Socket "MSG: $msg"
  flush $Socket
}

# Handle verbosity levels
proc doVerbose {msg level} {
    global Verbose
    if {$Verbose >= $level} {puts "$msg"}
}

# handle a PID file, if it can not be created, ignore it
proc doPID {} {
    global PIDfile
    global Verbose

    if {$PIDfile != ""} {
        set activepid ""
        set PIDdir [file dirname $PIDfile]
        if {[file writable $PIDfile]} {
            # get the pid's on the first line of the pidfile
            set chan [open $PIDfile r ]
            gets $chan line
            close $chan
            # save any active pid
            foreach p $line {
                if {[file exists /proc/$p]} {set activepid "$p "}
            }
            # truncate the pidfile
            set chan [open $PIDfile w ]
            if {$activepid == ""} {
                # write current PID into pidfile
                puts $chan [pid]
            } else {
                # write active PID's and current PID into pidfile
                puts $chan "$activepid [pid]"
            }
            close $chan
        } elseif {[file writable $PIDdir]} {
            # create the pidfile
            set chan [open $PIDfile "CREAT WRONLY" 0644]
            puts $chan [pid]
            close $chan
        }
        doVerbose "Using pidfile: $PIDfile" 1
    } else {doVerbose "Not using a PID file" 1}
}

proc scanFonts {} {
    global fontList

    set numberFonts 0
    set numberFixed 0
    # find a fixed-width font and use it
    foreach family [font families] {
        incr numberFonts
        #Next line is for Apple Mac. Microsoft Word font Bauhaus93 triggers
        #an error in Wish:
        #    CoreText: Invalid 'kern' Table In CTFont <name: Bauhaus93....
        if {$family == "Bauhaus 93"} {continue} 

        if {[font metrics \"$family\" -fixed]} {
            incr numberFixed
            doVerbose "detected fixed font $family" 4
            lappend fontList $family
            if {![info exists currentFont]} {
                set currentFont $family
            }
        }
    }
    doVerbose "$numberFixed fixed fonts out of $numberFonts fonts" 1
    set fontList [lsort -dictionary $fontList]
    write_rc_file "fontList " "set fontList \"$fontList\""
}

proc modal {window} {
    grab $window
    wm transient $window .
    wm protocol $window WM_DELETE_$window {grab release $window; destroy $window}
    raise $window
    tkwait window $window
}


# This is the default, except when using freewrap or on the TiVo
if {[catch {encoding system utf-8} msg]} {
    doVerbose "$msg" 1
}

getArg

doVerbose "$VersionInfo" 1
doVerbose "Verbose Level: $Verbose" 1
doVerbose "Config file: $ConfigFile" 1
doVerbose "Delay between reconnect tries to the server: $Delay (seconds)" 1


 if {!$NoGUI} {
    package require tile
    doVerbose "GUI Display" 1
    doVerbose "Popup time: $PopupTime" 1
    if {$NoExit} {
        set ExitOn do_nothing
        doVerbose "The \"Close Window\" button is disabled" 1
    }
    if {![regexp {^(:?char|word|none)$} $WrapLines]} {
        doVerbose "WrapLines set to invalid value of \"$WrapLines\", using default" 1
        set WrapLines "char"
    }
    makeWindow
}
if {$Country != "US" && $Country != "SE" && $Country != "NONE" && \
    $Country != "UK" && $Country != "DE" && $Country != "HR"} {
    exitMsg 7 "Country Code \"$Country\" is not supported.Please change it."
}
doVerbose "Country Code: $Country" 1
if {$NoOne} {
    doVerbose "Ignore leading 1" 1
} else {doVerbose "Using leading 1" 1}
if {$DateSepar != "/" && $DateSepar != "-" && $DateSepar != "."} {
    exitMsg 7 "Date separator \"$DateSepar\" is not supported. Please change it."
}
if $AltDate {
    doVerbose "Date Format: DD${DateSepar}MM${DateSepar}YYYY" 1
} else { doVerbose "Date Format: MM${DateSepar}DD${DateSepar}YYYY" 1 }
if {$WakeUp} {
    if {![file executable $ProgDir/ncid-wakeup]} {
        set WakeUp 0
        doVerbose "Module ncid-wakeup not found or not executable, wakeup option removed" 1
    }
}
if {$Program != ""} {
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
    doVerbose "Using output Module: $Program" 1
    # change module name from <path>/ncid-<name> to ncid_<name>
    regsub {.*-(.*)} $Program {ncid_\1} modopt
    # if it exists, set the module option variable in $$modopt
    if {[catch {eval [subst $$modopt]} oops]} {
        doVerbose "No optional \"$modopt\" variable in ncid.conf" 1
    } else {
        regsub {.*set *(\w+)\s+.*} [eval concat $$modopt] {\1} modvar
        regsub {.*set *(\w+)\s+(\w+).*} [eval concat $$modopt] {\2} modval
        if {$modvar == "Ring"} { set CallOnRing 1 }
        doVerbose "Optional \"$modopt\" variable set \"$modvar\" to \"$modval\" in ncid.conf" 1
    }
    if {$CallOnRing} {
      switch -- $Ring {
        -9 {doVerbose "Will execute $Program every ring after CID" 1}
        -2 {doVerbose "Will execute $Program after hangup after answer" 1}
        -1 {doVerbose "Will execute $Program after hangup with no answer" 1}
         0 {doVerbose "Will execute $Program when ringing stops" 1}
         default {doVerbose "Will execute $Program at Ring $Ring" 1}
      }
    } elseif {$Program != ""} {
       doVerbose "Will execute $Program when CID arrives" 1
    }
}
if {$NoGUI} doPID
connectCID $Host $Port
if {!$NoGUI} {bind .im <KeyPress-Return> handleGUIMSG}

# enter event loop
vwait forever

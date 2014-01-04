Last edited: Mon Dec 30, 2013 

## <a name="verbose_top"></a>Verbose Levels

> [Table of Contents](#doc_top)

### Index

> [ncid verbose levels](#verbose_ncid)  
  [ncid2ncid verbose levels](#verbose_ncid2ncid)  
  [ncidd verbose levels](#verbose_ncidd)  
  [rn2ncid verbose levels](#verbose_rn2ncid)  
  [sip2ncid verbose levels](#verbose_sip2ncid)  
  [wc2ncid verbose levels](#verbose_wc2ncid)  

### <a name="verbose_ncid"></a>ncid verbose levels
>  Higher levels include lower levels.

> LEVEL9:
>> not used

> LEVEL8:
>> not used

> LEVEL7:
>> not used

> LEVEL6:
>> display the line type as a numeric

> LEVEL5:
>> show CIDINFO line

> LEVEL4:
>> shows fixed font family  
   display history entries in  milliseconds

> LEVEL3:
>> not used

> LEVEL2:
>> not used

> LEVEL1:
>> indicate if using PID file or not  
   display about  
   indicate if a output module is being used and which one  
   indicate if optional module variable is not being used  
   indicate if optional module variable is being used and ring count  
   display received data if in raw mode  
   indicate when call log is completely received  
   show CIDINFO line on ring count match  
   show data sent to module  
   indicate if phone line label not found  
   show message sent to module  
   show CID data sent to module  
   display popup message

### <a name="verbose_ncid2ncid"></a>ncid2ncid gateway verbose levels
>  Higher levels include lower levels.

> LEVEL9:
>> (can only be set by the command line)  
   Indicate reading socket

> LEVEL8:
>> (can only be set by the command line)  
   Show all data received from all servers

> LEVEL7:
>> not used

> LEVEL6:
>> not used

> LEVEL5:
>> not used

> LEVEL4:
>> not used

> LEVEL3:
>> not used

> LEVEL2:
>> not used

> LEVEL1:
>> indicate cannot create or open existing logfile  
   show start date and time  
   show server version  
   indicate Debug mode  
   indicate no config file  
   indicate config file processed  
   indicate set command skipped in config file  
   show error line in config file  
   show verbose level  
   indicate not using PID file, there was no '-P' option  
   indicate found stale pidfile  
   indicate wrote pid in pidfile  
   show Receiving Host host:port  
   show server greeting line  
   show configured Sending Hosts host:port  
   show configured servers greeting line  
   indicate client disconnected  
   indicate client reconnected  
   indicate Hung Up  
   indicate Poll Error  
   indicate Removed client, invalid request  
   indicate Removed client, write event not configured  
   indicate line cannot be sent to receiving NCID server  
   indicate line sent to receiving NCID server  
   indicate removed pidfile  
   show terminated with date and time

### <a name="verbose_ncidd"></a>ncidd server verbose levels
>  Higher levels include lower levels.

> LEVEL9:
>> (can only be set by the command line)  
   show poll() events flag

> LEVEL8:
>> (can only be set by the command line)  
   show alias table  
   show blacklist  and whitelist tables  
   indicate client sent empty line

> LEVEL7:
>> not used

> LEVEL6:
>> not used

> LEVEL5:
>> not used

> LEVEL4:
>> show optional files failed to open  
   show lastring and ring count if ring detected

> LEVEL3:
>> show number of tries to init modem  
   show modem responses  
   show client connect/disconnect  
   indicate Non 7-bit ASCII message deleted  
   indicate Gateway sent CALL data  
   indicate Gateway sent CALLINFO data  
   indicate Client sent text message  
   indicate client sent unknown data  
   show call data input  
   show CIDINFO line  
   show CID line

> LEVEL2:
>> indicate network client hung up  
   indicate device or modem returned no data
   show line sent to cidupdate
   show line sent to ncidutil
   show INFO lines
   show WRK lines
   show RESP lines

> LEVEL1:
>> show started with date and time  
   show server version  
   indicate if could not create ncidd logfile  
   indicate name and location of ncidd logfile  
   indicate if no config file  
   indicate config file processed  
   indicate set command skipped in config file  
   show error line in config file  
   indicate error in opening ncidd log file  
   indicate what is configured to send to the clients  
   show verbose level  
   indicate data type sent to clients  
   indicate alias file messages  
   indicate if leading 1 needed for aliases  
   indicate blacklist  and whitelist file messages  
   indicate alias, blacklist, and whitelist total/maximum entries, if any  
   indicate cid logfile messages  
   indicate if no data logfile  
   indicate name and location of data logfile  
   show Telephone Line Identifier  
   show TTY port opened  
   show TTY port speed  
   show name and location of TTY lockfile  
   indicate TTY port control signals enabled or disabled  
   indicate CallerID from serial device and optional gateways  
   indicate CallerID from AT Modem and optional gateways  
   indicate Handles modem calls without Caller ID  
   indicate Does not handle modem calls without Caller ID  
   indicate CallerID from Gateway  
   indicate hangup option  
   show network port  
   indicate not using PID file if no '-P' option  
   indicate pid file already exists  
   indicate found stale pidfile  
   indicate cannot write pidfile  
   indicate wrote pid in pidfile  
   indicate TTY in use with date and time  
   indicate TTY free with date and time  
   indicate cannot init TTY and terminated with date and time  
   indicate Modem initialized.  
   indicate Initialization string for modem is null.  
   indicate Modem set for CallerID.  
   indicate CallerID initialization string for modem is null.  
   indicate CallerID TTY port initialized  
   indicate serial device hung up and terminated with date and time  
   indicate device error and terminated with date and time  
   indicate serial device error and terminated with date and time  
   indicate poll error  
   indicate invalid request from serial device,terminated  with date and time  
   indicate Invalid Request, removed client  
   indicate Write event not configured, removed client  
   indicate device or modem read error  
   indicate Device returns no data, Terminated with date and time  
   indicate network connect error  
   indicate network NOBLOCK error  
   indicate too many network clients  
   indicate network client read error  
   indicate cid log is too large  
   indicate sending log to client  
   indicate removed pidfile  
   indicate signal received and terminate program with date and time  
   indicate SIGHUP received and reload alias files  
   indicate SIGPIPE received and ignored with date and time  
   indicate Failed to remove stale lockfile  
   indicate Removed stale lockfile

### <a name="verbose_rn2ncid"></a>rn2ncid gateway verbose levels
>  Higher levels include lower levels.

> LEVEL9:
>> not used

> LEVEL8:
>> not used

> LEVEL7:
>> not used

> LEVEL6:
>> not used

> LEVEL5:
>> Show call log from ncidd, if received  
   Show Caller ID line from ncidd

> LEVEL4:
>> not used

> LEVEL3:
>> Show notification type  
   Show Call line if type RING  
   Show PING or Battery message as notice  
   Show notice of a SMS or MMS message  
   Show unknown notification type  
   Show id notification was rejected

> LEVEL2:
>> not used  
   Show Phone On Hook

> LEVEL1:
>> Show Started  
   Show command line and any options on separate lines  
   Show logfile name and opened as append or overwrite or could not open  
   Show processed config file or config file not found  
   Show name and version  
   Show verbose level  
   Show debug mode if in debug mode  
   Show test mode if in test mode  
   Show reject option values or none  
   Show pid or some PID problem  
   Show connected to NCID address:port or error exit  
   Show greeting line from NCID  
   Show listening port or error exit  
   Show NCID server disconnected if it goes away and trying to reconnect

### <a name="verbose_sip2ncid"></a>sip2ncid gateway verbose levels
>  Higher levels include lower levels.

> LEVEL9:
>> (can only be set by the command line)  
   show lines received from the NCID server

> LEVEL8:
>> not used

> LEVEL7:
>> not used

> LEVEL6:
>> not used

> LEVEL5:
>> show linenum array and number as they are compared for a call  
   indicate checked for "Call ID: call-" and outcall value

> LEVEL4:
>> UDP packet from address  
   UDP packet to address  
   IP protocol  
   UDP source port  
   UDP destination port  
   UDP data size in bytes  
   indicate Alarm Timeout and msgsent flag

> LEVEL3:
>> show UDP SIP packets  
   give character count of lines received from the NCID server  
   show alarm timeout, pcap\_loop() return value, and msgsent flags

> LEVEL2:
>> indicate cannot write pidfile  
   show packet number received  
   show Duplicate INVITE Packet <pkt#> with <invpkt#>  
   show Ignoring Trying Packet <pkt#>  
   show Ignoring Ringing Packet <pkt#>  
   show Warning: could not connect to the NCID server

> LEVEL1:
>> indicate cannot create or open existing logfile  
   show start date and time  
   show server version  
   indicate test mode  
   indicate Debug mode  
   indicate no config file  
   indicate config file processed  
   indicate set command skipped in config file  
   show error line in config file  
   indicate Reading from dumpfile  
   indicate Writing to dumpfile  
   show verbose level  
   show status: Warn clients: 'No SIP packets' & 'SIP packets returned'  
   show status:  Remove duplicate INVITE Packets?  
   show NCID server host:port  
   show network interface used  
   show applied filter  
   indicate no filter applied  
   indicate No SIP packets received  
   indicate SIP packets returned  
   indicate not using PID file, there was no '-P' option  
   indicate pid file already exists  
   indicate found stale pidfile  
   indicate wrote pid in pidfile  
   alarm SIP packets returned  
   Warning: SIP Packet truncated  
   Warning: simultaneous calls exceeded  
   invalid IP header length  
   show registered line number  
   indicate Number of telephone lines exceed  
   show CID line sent to NCID  
   indicate packet parse problems  
   indicate caller hangup before answer  
   indicate hangup after answer  
   Warning: cannot get CallID  
   Warning: Warning no SIP packets  
   indicate pcap\_loop error  
   indicate removed pidfile  
   indicate program terminated with date and time

### <a name="verbose_wc2ncid"></a>wc2ncid gateway verbose levels
>  Higher levels include lower levels.

> LEVEL9:
>> not used

> LEVEL8:
>> not used

> LEVEL7:
>> not used

> LEVEL6:
>> not used

> LEVEL5:
>> Show call log from ncidd, if received  
   Show Caller ID line from ncidd

> LEVEL4:
>> Show hex dump of received packet

> LEVEL3:
>> Show unit and serial numbers from Whozz Calling device  
   Show Call line from Whozz Calling device

> LEVEL2:
>> Show CALL and CALLINFO lines sent to ncidd  
   Show Phone Off Hook  
   Show Phone On Hook

> LEVEL1:
>> Show Started  
   Show command line and any options on separate lines  
   Show version  
   Show verbose level  
   Show debug mode if in debug mode  
   Show test mode if in test mode  
   Show logfile name and whether opened as append or overwrite  
   Show logfile could not be opened  
   Show processed config file or config file not found  
   Show connected to NCID address:port or error exit  
   Show greeting line from NCID  
   Show opened broadcast port  
   Show closed broadcast port  
   Show opened WC device port  
   Show closed WC device port  
   Show commands sent  
   Show Pause after sending ^^Id-V  
   Show checking and setting required flags  
   Indicate command data received or timeout in seconds  
   Show data from some commands

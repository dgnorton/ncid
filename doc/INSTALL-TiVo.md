Last edited: Sum Mar 23, 2014

## <a name="instl_tivo_top"></a>TiVo TAR Package Install

> The ncid client replaces the old tivocid package.  It
  functions exactly like TiVoCID, if it is called tivocid,
  or if it is given the proper options.  The ncid client
  requires the out2osd package to be installed to display
  the CID information on the TV screen.

> The ncid client is also called tivoncid and uses the new
  ncid-tivo output module that uses /tvbin/text2osd to
  display the CID information.

> The NCID package includes both the client and server.
  For a series1, the server would normally be ignored unless
  you have a DirecTiVo, a hardware modified internal modem,
  or a modem connected to the serial port.

> [Table of Contents](#doc_top)

### Sections:

> * [COMPILE NCID](#instl_tivo_comp)  
> * [Install TiVoCID, TiVoNCID, sip2ncid, and ncidd](#instl_tivo_inst)  
> * [Optional: Install the TiVo OUT2OSD display program](#instl_tivo_out)  
> * [Optional: Install Perl](#instl_tivo_ip)  
> * [Configure ncidd, if you are running it on the TiVo](#instl_tivo_cs)  
> * [Start and verify the ncid package is working](#instl_tivo_sv)  
> * [Completing ncidd setup](#instl_tivo_cn)  
> * [Test using a Modem](#instl_tivo_mt)  
> * [TEST USING sip2ncid:](#instl_tivo_st)  
> * [TEST USING yac2ncid:](#instl_tivo_yt)  
> * [Install ncidd on a separate computer, if not using it on the TiVo](#instl_tivo_is)  
> * [Test the TiVo CID Client (if using tivocid)](#instl_tivo_cc)  
> * [Test the TiVo NCID Client (if using tivoncid)](#instl_tivo_nc)  
> * [Files installed and modem information](#instl_tivo_fi)  
> * [Notes](#instl_tivo_note)  

### <a name="instl_tivo_comp"></a>COMPILE NCID

> See the [Compile](#instl_generic_compile) section of [INSTALL (generic)](#instl_generic_top).

### <a name="instl_tivo_inst"></a>Install TiVoCID, TiVoNCID, sip2ncid, and ncidd

> You have a choice of using either tivocid or tivoncid as your display
  client.  Tivocid uses out2osd which does not work on all TiVo software
  hardware combinations.  Tivoncid should work on all TiVo software and
  hardware combinations.

> It is recomended you use tivoncid.

> If this is an upgrade, you need to save the configuration filesfirst:
>>  cp -a /var/hack/etc/ncid /var/hack/etc/ncid.old

> If you have a series 1 TiVo, Copy ncid-VERSION-tivo-ppc.tgz to the tivo.  
> If you have a series 2 TiVo, Copy ncid-VERSION-tivo-mips.tgz to the tivo.

> - tar -xzvf ncid-VERSION-tivo-mips.tgz -C /var

          EXAMPLE:
          tar -xzvf ncid-0.5-tivo-mips.tgz -C /var

> If this is an upgtade, modify any of the configuration files previously
  modified and saved in /var/hack/etc/ncid.old.  The new configuration
  files may have new comments and lines that can be modified so do not
  replace a new configuration with the old one.  Normally you would have
  modified just ncidd.conf and ncidd.alias.

### <a name="instl_tivo_out"></a>Optional: Install the TiVo OUT2OSD display program 

> The tivocid script uses out2osd for display.  The out2osd
  program only works on a Series 1 and a Series 2.  It is
  recomended you use the tivoncid script instead of tivocid.

> Get and install the latest OUT2OSD display program.
  It is available as either a source tar file, or a
  TiVo binary tar package.

### <a name="instl_tivo_ip"></a>Optional: Install Perl

> If you would like to use the cidcall, cidalias, and update
  scripts, you need to get and install Perl into /var/hack/bin

### <a name="instl_tivo_cs"></a>Configure ncidd, if you are running it on the TiVo

> Ncidd is compiled to use directories under /var/hack.
  You can change this if you like, by using the
  command line to specify the location of the config
  file, and then using the config file to set the
  options for your new directory structure.

> If you are using a modem:

>> The ncidd.conf file is preconfigured for a TiVo.
   These are the lines enabled for a Series1 and a Series2:

            set sttyclocal = 1  
            set modem = /dev/ttyS1 # TiVo Modem Port  
            set lockfile = /var/tmp/modemlock # needed for TiVo Modem Port

>>  If you are using a standalone series1 without the modem hardware
    modification to enable Caller ID, you need to uncomment the line:

            # set modem = /dev/ttyS3 # TiVo Serial Port

>> and comment out the line::

            set modem = /dev/ttyS1 # TiVo Modem Port

> If you are using using sip2ncid or yac2ncid instead of a modem:

>> You need to uncomment the line:

            # set noserial = 1

### <a name="instl_tivo_sv"></a>Start and verify the ncid package is working

> Use the startncid script to start NCID and use stopncid to
  stop all running NCID programs.

> After you configure and start startncid as indicated below,
  check that the programs are running:

>> pgrep -fl ncid

> If you are running the server and client on the TiVo
and are using tivoncid with a modem:

>> use the startncid script:  
>>> /var/hack/bin/startncid

>> startncid executes these commands:
>>> ncidd  
    tivoncid &

> If you are running the server and client on the TiVo
  and are using tivoncid with sip2ncid:

>> uncomment one of the timesone lines, for example:
>>> TZ=EST5EDT,M3.2.0,M11.1.0    # EASTERN TIME

>> uncomment this line in startncid:
>>> SIPGW=sip2ncid

>> use the startncid script:
>>> /var/hack/bin/startncid

>> startncid executes these commands:
>>> ncidd  
    sip2ncid
    tivoncid &

> If you are running the server and client on the TiVo
> and are using tivoncid with yac2ncid:

>> uncomment this line in startncid:
>>> YACGW=yac2ncid

>> use the startncid script:
>>> /var/hack/bin/startncid

>> startncid executes these commands:
>>> ncidd  
    yac2ncid  
    tivoncid &

> If you are only running the client on the TiVo:

>> modify ncid.conf:

            change this line: set Host        127.0.0.1  
            to this line:     set Host        < NCID server IP address >

>> example using the command line:
>>> tivoncid IP.Server.Address &

>> If the server is at 192.168.0.10, the above becomes:

>>> tivoncid 192.168.0.10 &

> If you are running the server and client on the TiVo
  and are using tivocid with a modem:

>> comment the OSDCLIENT line in startncid:
>>> \#OSDCLIENT=tivoncid

>> uncomment the OSDCLIENT line in startncid:
>>> OSDCLIENT=tivocid

>> use the startncid script:
>>> /var/hack/bin/startncid

>> startncid executes these commands:
>>> ncidd  
    tivocid &

> Call yourself and see if it works, if not, kill off ncidd, if
  it is running, and continue reading the test sections.

> Once you are satisfied that everything is working OK, complete the
  setup of NCID.


### <a name="instl_tivo_cn"></a>Completing ncidd setup

> NCID has a start up script, /var/hack/bin/startncid, to start the
  server, gateway, cliets you are using, and to set up the environment.
  It is preconfigured to start ncidd, and tivoncid.  You need to edit
  it if you want to set up your local timezone, or if you want to start
  tivoncid instead of tivocid, sip2ncid, ncid-yac, or ncid-initmodem.
  Do not configure both tivocid and tivoncid or both will try to display
  the Caller ID on screen.

> After you customise startncid, add /var/hack/bin/startncid to the
  /etc/rc.d/rc.sysinit.author file.

> If you have a problem with your modem dropping out of Caller ID,
  you can use the ncid-initmodem module to re-initialize the modem
  when a call is detected without Caller ID.  This module must only
  be used when you are using a modem to obtain the Caller ID.  The
  modem must provide ring detection for this to work.

> You can also use /var/hack/bin/initmodem manually or call it from
  cron to re-initialize the modem.  It can be used with ncid-initmodem.

### <a name="instl_tivo_mt"></a>Test using a Modem

> The easiest way to test the setup is to run ncidd in debug mode,
  it will stay attached to the terminal and not go into daemon mode:
>> ncidd -D

> to get more information, add the verbose flag:
>> ncidd -Dv3

> to also look at the alias structure
>> ncidd -Dv5

> The last three lines will be similar to:

          Modem set for CallerID.  
          Port: 3333  
          pid 20996 in pidfile: /var/run/ncidd.pid  

> Call yourself and you should see the CallerID information.  

> - If you just see RING and no Caller ID lines,
    the modem does not support caller ID.

> - If you see: /dev/ttyS1: No such file or directory
    you need to set sttyclocal in ncidd.conf
                                                                  
> - At any point, you can use command lines options to vary
    things like modem init and CID init.

> Once it works, you would normally start it:

          ncidd    

> or, if, for example, you use /hack instead of /var/hack:  

          ncidd -C /hack/etc/ncidd.conf

### <a name="instl_tivo_st"></a>TEST USING sip2ncid:

> - Start (in this order):

          ncidd  
          sip2ncid (may need to add options, review [sip2ncid setup](#gateways_sip))  
          or tivoncid

> - Call yourself

>> if you have problems, start ncidd in debug mode:

          ncidd -D

>> to get more information, add the verbose flag:

          ncidd -Dv3

>> to also look at the alias structure

          ncidd -Dv5

> - The last three lines will be similar to:

          CallerID only from CID gateways  
          Network Port: 3333  
          Wrote pid 20996 in pidfile: /var/run/ncidd.pid

> - Once you solve any problems, restart ncidd normally

### <a name="instl_tivo_yt"></a>TEST USING yac2ncid:

> - Start (in this order):

>> ncidd  
   yac2ncid (may need to add options)  
   tivocid or tivoncid

> - Call yourself

>> if you have problems, start ncidd in debug mode:

            ncidd -D

>> to get more information, add the verbose flag:

            ncidd -Dv3

>> to also look at the alias structure

            ncidd -Dv5

>> The last three lines will be similar to:

            CallerID only from CID gateways  
            Port: 3333  
            pid 20996 in pidfile: /var/run/ncidd.pid

> - Once you solve any problems, restart ncidd normally

### <a name="instl_tivo_is"></a>Install ncidd on a separate computer, if not using it on the TiVo

> Get, install, and test the latest NCID server/client package
  for the computer you will run it on, if it is not the TiVo.

> NCID is available as either a source tar file, or a Redhat RPM package,

### <a name="instl_tivo_cc"></a>Test the TiVo CID Client (if using tivocid)

> Start tivocid:

> - If ncidd is on the TiVo:

          tivocid -V  
          You should see the Server connect message.

> - If ncidd is on another computer:

          tivocid -V IP.Server.Address.  
          You should see the Server connect message.

> If it dosen't start, the error message should give you a clue.

> There is one report of tivocid aborting with a message similar to:

          bash-2.02# Tmk Assertion Failure:  
          FsAllocateFunction, line 131 ()

> If tivosh dies in the wrong place, the tivo will restart:

          Tmk Fatal Error: Thread tivosh <252> died due to signal -2
          f9c51c 100df1c 100e18c 100e1dc dabe9c dab55c 400c50 108a0b0 
          Restarting system.

> The fix is to start it this way:

          tivosh ncid --no-gui -T --call-prog --program /var/hack/bin/out2osd &

> Call yourself.  The display should show up for 10 seconds
  and then erase itself.

> If tivocid dosen't display the Caller ID information, try:

          tivocid -R -V IP.Server.Address.

> This will show everything received from the server, and
  the CID information it processes.

> If tivocid works, kill off tivocid and restart it:

>> If ncidd is on the TiVo:

          tivocid &

>> If ncidd is on another computer:

          tivocid IP.Server.Address &

### <a name="instl_tivo_nc"></a>Test the TiVo NCID Client (if using tivoncid)

> Start tivoncid:

>> If ncidd is on the TiVo:

          tivoncid -V  

>> You should see the Server connect message.

>> If ncidd is on another computer:

          tivoncid -V IP.Server.Address.

>> You should see the Server connect message.

> If it does not start, the error message should give you a clue.

> There is one report of tivocid aborting with a message similar to:

          bash-2.02# Tmk Assertion Failure:  
          FsAllocateFunction, line 131 ()

> If tivosh dies in the wrong place, the tivo will restart:

          Tmk Fatal Error: Thread tivosh <252> died due to signal -2
          100df1c 100e18c 100e1dc dabe9c dab55c 400c50 108a0b0 Restarting

> The fix for this is to start it this way:

          tivosh ncid --no-gui --call-prog --program ncid-tivo &

> Call yourself.  The display should show up for 10 seconds
  and then erase itself.

> If tivocid does not display the Caller ID information, try:

          tivoncid -R -V IP.Server.Address.

> This will show everything received from the server, and
  the CID information it processes.

> If tivoncid works, kill off tivoncid and restart it:

>> If ncidd is on the TiVo:

          tivoncid &

>> If ncidd is on another computer:

          tivoncid IP.Server.Address &

### <a name="instl_tivo_fi"></a>Files installed and modem information

> The series1 tivo requires a hardware modification to support
  Caller ID, but you can hang a modem off of the serial port using
  the TiVo serial cable and a modem serial cable connected together.

> Series1 information on the hardware modification needed, various
  CID init strings, and another Caller ID program can be found here:

>> [Caller-id program for DirecTivo](http://archive.tivocommunity.com/tivo-vb/showthread.php?s=&threadid=54469&highlight=Elseed)

> [TiVo Modems](#modems_tivo) gives some information about the TiVo modems.

> The tar file creates and populates the following directories

            hack
              |-- bin
              |-- sbin
              |-- etc -- ncid -- conf.d
              |-- log
              |-- doc -- ncid -- man
              |-- dev
              |-- share -- ncid


### <a name="instl_tivo_note"></a>Notes

            tivocid is a symbolic link to ncid  
            tivoncid is also a symbolic link to ncid

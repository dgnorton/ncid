Last edited: Fri Mar 7, 2014 

## <a name="instl_cygwin_top"></a>Cygwin TAR Package Install

> If NCID does not work, see [INSTALL](#instl_generic_top) for some simple tests.  

> If using sip2ncid, review [sip2ncid setup](#gateways_sip).

> If using wc2ncid, review [wc2ncid setup](#gateways_wc).

> If using yac2ncid, review [yac2ncid setup](#gateways_yac).

> [Table of Contents](#doc_top)


### Sections:
> [NOTES](#instl_cygwin_note)  
  [INSTALL](#instl_cygwin_inst)  
  [CONFIGURE](#instl_cygwin_conf)  
  [START](#instl_cygwin_st)  
  [REBASE](#instl_cygwin_reb)  
  [RUN AS A QUASI-SERVICE](#instl_cygwin_run)  

### <a name="instl_cygwin_note"></a>NOTES:

> The server has been tested with sip2ncid.

> - The server does not function with a modem so it is configured
    for "noserial".  It requires sip2ncid and yac2ncid to function.
> - the supplied yac2ncid gateway requires YAC to control the modem
    http://search.cpan.org/CPAN/authors/S/SA/SAPER
> - Net-Pcap requires WinPcap: http://www.winpcap.org/
> - The Net-Pcap module has been successfully built under cygwin
> - Latest Versions Tested: WpdPack\_41b.zip and Net-Pcap-0.14.tar.gz

### <a name="instl_cygwin_inst"></a>INSTALL:

> Install WinPcap from http://www.winpcap.org/

> - download WinPcap\_4\_0\_1.exe or later version
> - run WinPcap\_4\_0\_1.exe or later version

> Install Cygwin from http://cygwin.com/

> - download setup.exe into a empty folder
> - Run setup.exe
> - select cygwin download site
> - Let default setup download
> - It is strongly recommended you enable cut and paste in the Cygwin window.
>> - Left click on the icon in upper left
>> - Select Properties
>> - Check Mark the QuickEdit Mode in Edit Options
    
> Install ncid:

> - The NCID package normally installs in /usr/local:
> - If a binary package is available:
  + Copy ncid-VERSION-cygwin.tgz to cygwin, then:
  + tar -xzvf ncid-VERSION-cygwin.tgz -C /
  + EXAMPLE: tar -xzvf ncid-0.64-cygwin.tgz -C /
> - if there is no binary package, you need to compile the source
    (usually not required):

          - Copy ncid-VERSION-src.tar.gz to cygwin, then:
          - tar -xzvf ncid-VERSION-src.tar.gz
          - cd ncid
          - make cygwin
            (compiles for /usr/local, see top of Makefile)
          - make cygwin-install

> If phone system is VoIP and you want to use sip2ncid:

> - nothing else to do

> If you want to use your modem, you need YAC

> - download and install YAC from http://sunflowerhead.com/software/yac/
> - configure the YAC server for a listener at localhost (127.0.0.1)

### <a name="instl_cygwin_conf"></a>CONFIGURE:

> The Makefile configures ncidd.conf for the Cygwin, but you may
   want to change some of the defaults.

> You need to configure sip2ncid to use the Network Interface.
   To find out the network interface name, you need to use the "-l"
   option to sip2ncid.  You should see your Network interface names
   listed.  Select the active one and use it with the "-i" option to
   sip2ncid.

### <a name="instl_cygwin_st"></a>START:

> If this is your first time, you should do
  the [Test Using `sip2ncid`](#instl_generic_sip)
  and [Test Using `yac2ncid`](#instl_generic_yac) procedures in
  the [INSTALL (generic)](#instl_generic_top) section first.

> start the server and clients:

> - ncidd

> If using [sip2ncid](#gateways_sip)

        - sip2ncid -l (list NETWORK_INTERFACES)  
        - sip2ncid -i NETWORK_INTERFACE  

        (Note: display is < INTERFACE : DESCRIPTION >)

> If using [wc2ncid](#gateways_wc):

        - wc2ncid &

> If using [yac2ncid](gateways_yac)

        - yac2ncid &

> If using ncid:

        - ncid &

> Call yourself and see if it works.

### <a name="instl_cygwin_reb"></a>REBASE:

> One of the idiosyncrasies of Cygwin is the need to rebase the dll's
  (set a base dll load address) so they don't conflict and create
  forking errors. The easiest way to do this is documented here:
>> http://cygwin.wikia.com/wiki/Rebaseall
	  
> Just start an ash or dash prompt from \cygwin\bin, and then type
>> rebaseall -v  
   exit
		
### <a name="instl_cygwin_run"></a>RUN AS A QUASI-SERVICE:

> - Don't do this process until you have ncidd and sip2ncid or other processes
    running properly. Once you have things setup though, you can set ncidd and
    sip2ncid to (sort of) run as a service in Windows. I only say "sort of"
    because it's not technically a service, but is called from another
    Cygwin component that is a service.
	  
> - Re-run the setup.exe that you used to install Cygwin, and install the
    cygrunsrv package. It's under Admin

> - Go to a cygwin command line, and type the following to install ncidd as a
    service:

          cygrunsrv -I ncidd -n -p /usr/local/bin/ncidd
                    -f "Network CallerID daemon(ncidd)" -a -D
		 
>> Explaining these parameters:

          -I indicates install  
          -n indicates that the service never exits by itself (I don't
             recall why this has to be set, but it doesn't work otherwise)
          -p /usr/local/bin/ncidd:
             Application path which is run as a service.
          -f "Network CallerID daemon (ncidd)":
             Optional string which contains  the service description
             (the desc you see in the Services listing)
          -a -D: passes the parameter "-D" to the ncidd program so it
                 runs in debug mode. This keeps ncidd running in the
                 "foreground" of the  cygrunsrv process.
		 
> - Likewise, to remove the ncidd service: cygrunsrv -R ncidd
		
> - To install sip2ncid to run in the background, the command line is similar:

          cygrunsrv -I sip2ncid -n -p /usr/local/bin/sip2ncid -y ncidd \  
                    -a '-i "/Device/NPF_{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}" \
                    -D' -f "Service to pick SIP packets from network and send to ncidd" \  
                    --termsig KILL
		
>> Explaining these parameters:

		  -I indicates install
		  -n indicates that the service never exits by itself (I don't
             recall why this has to be set, but it doesn't work otherwise)
		  -p /usr/local/bin/sip2ncid: Application path which is run as
             a service.
		  -y ncidd: adds a service dependency with the ncidd service so
             that the ncidd service gets started automatically when you
             start sip2ncid
		  -a '-i "/Device/NPF_{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}" -D':
			     note the single and double quotes in this section. You need to
			     replace XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX in the above
			     with NETWORK_INTERFACE from way above. To be clear, you want to
			     replace /Device/NPF_{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
			     with NETWORK_INTERFACE from way above.
		  -f "Service to pick SIP packets from network and send to ncidd":
		     Optional string which contains the service description
			 (the desc you see in the Services listing)
		  --termsig KILL: termination signal to send. If you don't include
		                  this the service doesn't always get stopped.

> - Likewise, to remove the sip2ncid service:

          cygrunsrv -R sip2ncid

> - To install ncid-notify to run in the background, the command
	  line is similar:

          cygrunsrv -I ncid-notify -p /bin/sh.exe -a \
		            '-c "/usr/local/bin/ncid --no-gui --message --program ncid-notify"' \
		            -f "Service to use notify service to send ncid messages to iPad"
		
>> Explaining these parameters:

          -I indicates install
          -p /bin/sh.exe: Application path to run, which in this case is 
             just sh.exe because ncid-notify is a shell script            
          -a '-c "/usr/local/bin/ncid --no-gui  --program ncid-notify"'
                 these are the parameters that get sent to sh.exe:
          -c "/usr/local/bin/ncid: this is the path to the ncid script
          --no-gui: tells ncid not to have a gui
          --program ncid-notify: tells ncid to pass data to "ncid-notify"
          -f "Service to use notify service to send ncid messages to iPad":

>> Optional string which contains the service description
   (the desc you see in the Services listing)

          -y ncidd: you COULD also add this line to add a service dependency
                    with the ncidd service so that the ncidd service gets started
                    automatically when you start ncid-notify. I don't do this,
                    because strictly speaking, you could be running ncidd on a
                    different computer.
			 
> - Likewise, to remove the ncid-notify service: cygrunsrv -R ncid-notify

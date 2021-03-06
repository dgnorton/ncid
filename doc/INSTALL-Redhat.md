Last edited: Sun Mar 23, 2014

## <a name="instl_red_top"></a>Redhat/Centos/Enterprise RPM Package Install

> If NCID does not work, see [INSTALL](#instl_generic_top) for some simple tests.  

> If using sip2ncid, see [sip2ncid setup](#gateways_sip).

> If using wc2ncid, see [wc2ncid setup](#gateways_wc).

> If using yac2ncid, see [yac2ncid setup](#gateways_yac).

> [Table of Contents](#doc_top)

### Sections:

> [COMPILE:](#instl_red_comp)    
  [INSTALL or UPGRADE:](#instl_red_iu)    
  [CONFIGURE:](#instl_red_conf)    
  [FIRST STARTUP:](#instl_red_fs)    
  [START/STOP/RESTART/RELOAD/STATUS:](#instl_red_ss)    
  [AUTOSTART:](#instl_red_as)  

### <a name="instl_red_comp"></a>COMPILE:

> The following packages are required:

> - sudo yum install libpcap-devel

> See [INSTALL (generic)](#instl_generic_top) for compile instructions

### <a name="instl_red_iu"></a>INSTALL or UPGRADE:

> NCID requires the server and client RPM packages to function.  The
  server is required on one computer or device, but the client can be
  installed on as many computers as needed.

> The client has a few output modules in its RPM package, and there
  are optional output modules in their own RPM packages.

> - Download server and client RPM Packages from Fedora repositories  

          ncid RPM Package         - server and gateways  
          ncid-client RPM Package  - client and default output modules

> - Download any optional output modules wanted:  

          ncid-MODULE RPM Package  - optional client output modules

> - Install or Upgrade the packages:

          Using the file viewer:
              * Open the file viewer to view the NCID RPM packages
              * Select the RPM packages
              * right click selections and select "Open with Package installer"

          Using YUM:
              * sudo yum install ncid\*.rpm

### <a name="instl_red_conf"></a>CONFIGURE:

> The ncidd.conf file is used to configure ncidd.

> - The default modem port in ncidd is /dev/modem.  This is just a
    symbolic link to the real modem port. It is probably best to
    set your modem port in ncidd.conf.  This assumes serial port 1:

          set ttyport = /dev/ttyS0

> - If you are using a SIP or YAC gateway instead of a local modem,
    you need to set noserial to 1:

          set noserial = 1

> - If you are using a local modem with or without a SIP or YAC gateway:

          set noserial = 0  (this is the default)

### <a name="instl_red_fs"></a>FIRST STARTUP:

> - if you are running the server and client on the same computer
    and using a modem:

          sudo service ncidd start  
          ncid &

> - If you are running the server and using a SIP gateway:

          service ncidd start  
          sudo service sip2ncid start  
          ncid &

> - If you are running the server and using a Whozz Calling gateway:

          sudo service wc2ncid start  
          sudo service wc2ncid start  
          ncid &

> - If you are running the server and using a YAC gateway:  

          sudo service ncidd start  
          sudo service yac2ncid start  
          ncid &

> - Call yourself and see if it works, if not,

          + stop the gateway used:  
            sudo service sip2ncid stop

          + stop the server:  
            sudo service ncidd stop

          + and continue reading the test sections.

> - If everything is OK, enable the NCID server, gateways, and
      client modules, your are using, to autostart at boot.  The
      GUI ncid client must be started after login, not boot.

> #### NOTE:
>> The ncid client normally starts in the GUI mode and there is no
   ncid.init script to start or stop it.

>> There are rc.init scripts for starting ncid with output modules,
   for example:

>> ncid-page, ncid-kpopup, etc.

### <a name="instl_red_ss"></a>START/STOP/RESTART/RELOAD/STATUS:

> Use the service command to start any of the daemons.  The service
  commands are: start, stop, restart, reload, and status.  The client
  can also be started using the output module name instead of ncid.
  All output modules can be run at the same time.

> Here are some examples:

> - start the NCID server:

          sudo service ncidd start

> - stop the ncid2sip server:

          sudo service sip2ncid stop

> - reload the server alias file:

          sudo service ncidd reload

> - start ncid with ncid-page:

          sudo service ncid-page start

> - get the status of ncid with ncid-speak:

          sudo service ncid-speak status

> Review the man page (man service).

### <a name="instl_red_as"></a>AUTOSTART:

> Use the chkconfig command to turn the service on/off for starting at boot.

> Here are some examples:

> - autostart ncidd at boot:

          sudo chkconfig ncidd on

> - autostart ncid-page at boot:

          sudo chkconfig ncid-page on

> - autostart ncid-kpopup at boot:

          sudo chkconfig ncid-kpopup on

> - list runlevels for sip2ncid:

          sudo chkconfig --list sip2ncid

> - remove ncid-speak from starting at boot:

          sudo chkconfig ncid-speak off

> Review the manpage (man chkconfig).

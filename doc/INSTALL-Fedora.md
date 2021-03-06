Last edited: Fri Mar 7, 2013

## <a name="instl_fed_top"></a>Fedora RPM Package Install

> If NCID does not work, see [INSTALL](#instl_generic_top) for some simple tests.  

> If using sip2ncid, see [sip2ncid setup](#gateways_sip).  

> If using wc2ncid, see [wc2ncid setup](#gateways_wc).

> If using yac2ncid, see [yac2ncid setup](#gateways_yac).

> [Table of Contents](#doc_top)

### Sections:

> [COMPILE:](#instl_fed_comp)  
  [INSTALL or UPGRADE:](#instl_fed_iu)  
  [CONFIGURE:](#instl_fed_conf)  
  [FIRST STARTUP:](#instl_fed_fs)  
  [START/STOP/RESTART/RELOAD/STATUS:](#instl_fed_ss)  
  [AUTOSTART:](#instl_fed_as)

### <a name="instl_fed_comp"></a>COMPILE:

> The following package is required:

         sudo yum install libpcap-devel

> See INSTALL for compile instructions

### <a name="instl_fed_iu"></a>INSTALL or UPGRADE:

> NCID requires the server and client RPM packages to function.  The
  server is required on one computer or device, but the client can be
  installed on as many computers as needed.

> The client has a few output modules in its RPM package, and there
  are optional output modules in their own RPM packages.

> Download the server and client RPM packages using yum from the
  Fedora repositories.  You can also download any optional output
  modules you want.

> - List the NCID packages

          sudo yum list ncid\*

> - the most recent versions may be here:

          sudo yum install fedora-release-rawhide  
          sudo yum --enablerepo=rawhide list ncid\*

> - Download the server and client packages:

          sudo yum install ncid-< rpm package >  
          sudo yum install ncid-client-< rpm package >

> - Download any optional module packages wanted:

          sudo yum install ncid-< module rpm package >

> If the current release is not in the Fedora repositories, download
  the RPM packages from https://sourceforge.net/projects/ncid/


> - Download server and client RPM Packages from sourceforge

          ncid RPM Package         (server and gateways)  
          ncid-client RPM Package  (client and default output modules)


> - Download any optional output modules wanted from sourceforge:

          ncid-MODULE RPM Package  (optional client output modules)

> - Install or Upgrade the packages:

         Using the file viewer:
         - Open the file viewer to view the NCID RPM packages
         - Select the RPM packages
         - right click selections and select "Open with Package installer"
         Using YUM:
         - sudo yum install ncid\*.rpm

### <a name="instl_fed_conf"></a>CONFIGURE:

> The ncidd.conf file is used to configure ncidd.

> - The default modem port in ncidd is /dev/modem.  This is just a
    symbolic link to the real modem port. It is probably best to
    set your modem port in ncidd.conf.  This assumes serial port 1:
>> set ttyport = /dev/ttyS0
> - If you are using a Gateway to get the Caller ID instead of a
    local modem, you need to set noserial to 1:
>> set noserial = 1
> - If you are using a local modem with or without a Gateway:
>> set noserial = 0  (this is the default)

### <a name="instl_fed_fs"></a>FIRST STARTUP:

> - If you are running the server and client on the same computer
    and using a modem:

          sudo systemctl start ncidd  
          ncid &

> - If you are running the server and using a SIP gateway:

          sudo systemctl start ncidd sip2ncid  
          ncid &

> - If you are running the server and using a Whozz Calling gateway:

          sudo systemctl start ncidd wc2ncid  
          ncid &

> - If you are running the server and using a YAC gateway:

          sudo systemctl start ncidd yac2ncid
          ncid &

> - Call yourself and see if it works, if not,

>> stop the gateway and server:  

          sudo systemctl stop sip2ncid ncidd  

>> and continue reading the test sections.

> - If everything is OK, enable the NCID server, gateways, and
    client modules you are using, to autostart at boot.

>> For example, to start ncidd and sip2ncid at boot:

          sudo systemctl enable ncidd sip2ncid

>> The GUI ncid client must be started after login, not boot.

>> NOTE:
>>> ncid normally starts in the GUI mode and there is no
    ncid.service script to start or stop it.  There are
    service scripts for starting ncid with output modules,
    for example: ncid-page, ncid-kpopup, etc.

### <a name="instl_fed_ss"></a>START/STOP/RESTART/RELOAD/STATUS:

> Use the 'systemctl' command to start any of the daemons.  The service
  commands are: start, stop, restart, reload, reload-or-restart, and status.
  The client can also be started using the output module name instead
  of ncid.  All output modules can be run at the same time.

> Here are some examples:

> - start the NCID server:

          sudo systemctl start ncidd.service

> - stop the ncid2sip server:


> - reload the server alias file:

          sudo systemctl reload-or-restart ncidd.service

> - restart ncid using ncid-page:

          sudo systemctl restart ncid-page.service

> - get the status of ncid using ncid-speak:

          sudo systemctl status ncid-speak.service

> Review the man page (man systemctl).

### <a name="instl_fed_as"></a>AUTOSTART:

> Use the 'systemctl' command to enable/disable a service to start at boot.

> Here are some examples:

> - autostart ncidd at boot:

          sudo systemctl enable ncidd

> - autostart ncidd and sip2ncid at boot:

          sudo systemctl enable ncidd sip2ncid

> - remove ncid-speak from starting at boot:

          sudo systemctl disable ncid-speak

> Review the manpage (man systemctl).

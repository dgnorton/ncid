Last edited: Sun Mar 23, 2014

## <a name="instl_ubuntu_top"></a>Ubuntu DEB Package Install

> If NCID does not work, see [INSTALL](#instl_generic_top) for some simple tests.  

>  If using sip2ncid, see [sip2ncid setup](#gateways_sip).  

> If using wc2ncid, see [wc2ncid setup](#gateways_wc).

> If using yac2ncid, see [yac2ncid setup](#gateways_yac).

> [Table of Contents](#doc_top)

### Sections:

> [COMPILE:](#instl_ubuntu_comp)  
  [INSTALL or UPGRADE:](#instl_ubuntu_iu)  
  [CONFIGURE:](#instl_ubuntu_conf)  
  [FIRST STARTUP:](#instl_ubuntu_fs)  
  [START/STOP/RESTART/RELOAD/STATUS:](#instl_ubuntu_ss)  
  [AUTOSTART:](#instl_ubuntu_as)
  [Package Removal:](#instl_ubuntu_rm)

### <a name="instl_ubuntu_comp"></a>COMPILE:

> The following packages are required:

        - sudo apt-get install build-essential
        - sudo apt-get install libpcap0.8-dev
    
> See INSTALL for compile instructions

### <a name="instl_ubuntu_iu"></a>INSTALL or UPGRADE:

> NCID requires the server and client DEB packages to function.  The
    server is required on one computer or device, but the client can be
    installed on as many computers as needed.

> The client has a few output modules in its DEB package, and there
    are optional output modules in their own DEB packages.

> If installing from 3rd Party Repository: GetDeb Apps

> - Add the repository if needed:

          wget -q -O - http://archive.getdeb.net/getdeb-archive.key | sudo apt-key add -  
          sudo sh -c "echo 'deb http://archive.getdeb.net/ubuntu precise-getdeb apps' >> /etc/apt/sources.list"

> - Update the apt cache:

          sudo apt-get update

> - List the available packages:

          sudo apt-cache search ncid

> - Install the server and client:

          sudo apt-get install ncid ncid-client

> - Install any optional output modules wanted:

          sudo apt-get install ncid-<module>

> #### IMPORTANT:

> - the repository install usually makes all servers start
    at boot, this will cause problems when the systen is
    rebooted.  Disable any servers you are not using:

          sudo update-rc.d sip2ncid disable
          sudo update-rc.d wc2ncid disable
          sudo update-rc.d rn2ncid disable
          sudo update-rc.d yum2ncid disable

> If the latest packages are not available at the repository:

> - Download the latest NCID deb packages from sourceforge

          ncid DEB Package

          ncid-client DEB Package
         (client and default output modules)

> - Download any optional output modules wanted:

          ncid-MODULE DEB Package
          (optional client output module)

> Use gdebi to install the local NCID packages and dependent packages.
> 
> + Using "sudo dpkg -i <package>"  
    will not install dependent packages.  
> + Using "sudo apt-get install <package>"  
    will not install local packages.

> - Install or Upgrade the packages using gdebi (command line):

         - Install gdebi if needed:  
           sudo apt-get install gdebi
         - Install the NCID server and gateways:  
           sudo gdebi ncid-<version>_armhf.deb  
         - Install the client package and default modules:  
           sudo gdebi ncid-client-<version>_all.deb
         - Install any optional modules:  
           sudo gdebi ncid-<module-<version>_all.deb  
>      Notes:  
        <version> would be something like: 0.89-1  
        <module> would be a module name like: kpopup, mythtc, samba
<br><br>

> - Install or Upgrade the packages using gdebi-gtk (GUI):

           If needed use the the menu item "Add/Remove.."
           to install the GDebi Package Installer.

           Using the file viewer:  
           - Open the file viewer to view the NCID DEB packages  
           - Select the DEB packages  
           - double click selections or right click selections and select
             "Open with GDebi Package installer"

### <a name="instl_ubuntu_conf"></a>CONFIGURE:

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

### <a name="instl_ubuntu_fs"></a>FIRST STARTUP:

> - if you are running the server and client on the same computer
      and using a modem:

          sudo invoke-rc.d ncidd start
          ncid &

> - If you are running the server and using a SIP gateway:

          sudo invoke-rc.d ncidd start
          sudo invoke-rc.d sip2ncid start
          ncid &

> - If you are running the server and using a Whozz Calling gateway:
      You need to install the Data::HexDump Perl module using cpan
      and then start the server, gateway, and client:

          cpan
            (interactive mode, first use will enter configure
            configure as much as possible automatically
            choose sudo from: Choose 'local::lib', 'sudo' or 'manual'
            automatically choose some CPAN mirror
            at cpan prumpt install module)

            install Data::HexDump
            quit

          sudo invoke-rc.d ncidd start
          sudo invoke-rc.d wc2ncid start
          ncid &

> - If you are running the server and using a YAC gateway:

          sudo invoke-rc.d ncidd start  
          sudo invoke-rc.d yac2ncid start  
          ncid &

> - Call yourself and see if it works, if not:

          - stop the gateway used:
            sudo invoke-rc.d sip2ncid stop
          - stop the server:
            sudo invoke-rc.d ncidd stop
          - continue reading the test sections.

> - If everything is OK, enable the NCID server, gateways, and
    client modules, your are using, to autostart at boot.  The
    GUI ncid client must be started after login, not boot

>> NOTE:

>> ncid normally starts in the GUI mode and there is no
    ncid.init script to start or stop it.

>> There are rc.init scripts for starting ncid with output modules, for
    example:

          ncid-page, ncid-kpopup, etc.

### <a name="instl_ubuntu_ss"></a>START/STOP/RESTART/RELOAD/STATUS:
START/STOP/STATUS:

> Use the invoke-rc.d command to start any of the daemons.  The invoke-rc.d
  actions are: start, stop, restart, reload, and status.  The client
  can also be started using the output module name instead of ncid.
  All output modules can be run at the same time.

> Here are some examples:

        - start the NCID server:
          sudo invoke-rc.d ncidd start  
        - stop the ncid2sip server:
          sudo invoke-rc.d sip2ncid stop  
        - reload the server alias file:
          sudo invoke-rc.d ncidd reload  
        - start ncid with ncid-page:
          sudo invoke-rc.d ncid-page start  
        - status of ncid with ncid-speak:
          sudo invoke-rc.d ncid-speak status

> Review the man page.  
  (man invoke-rc.d).

### <a name="instl_ubuntu_as"></a>AUTOSTART:

> Use the update-rc.d command to enable/disable the service at boot.

> Here are some examples:

       - start ncidd at boot:
         sudo update-rc.d ncidd defaults  
       - start ncid-page at boot:
         sudo update-rc.d ncid-page defaults

> Review the man page.  
  (man update-rc.d)

### <a name="instl_ubuntu_rm"></a>Package Removal:

> Use apt-get to remove the lcdncidi package:

       - normal removal without removing configuration files and dependencies:
         apt-get remove lcdncid
       - complete removal including dependencies:
         sudo apt-get --purge autoremove lcdncid

> Review the man page.  
  (man apt-get)

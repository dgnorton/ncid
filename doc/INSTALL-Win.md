Last edited: Sum Mar 23, 2014 

## <a name="instl_win_top"></a>Windows Install

> Install either the Windows client package or the complete package.

> [Table of Contents](#doc_top)

### Sections:

> [WINDOWS CLIENT INSTALL:](#instl_win_inst)  
  [WINDOWS COMPLETE COMPILE:](#instl_win_cc)  
  [WINDOWS COMPLETE INSTALL:](#instl_win_ci)  
  [NCID.TCL INSTALL:](#instl_win_tcl)  

### <a name="instl_win_inst"></a>WINDOWS CLIENT INSTALL:

> Install this package if you only need the client.

> - Execute the ncid installer:

          ncid-?.?-setup.exe  

>>  where ?.? is the version number, for example:

          ncid-0.89-setup.exe

> - Configure ncid in the configure screen.  The default address is
    127.0.0.1, so you will need to change it to the address of your
    ncid server, for example:

          "ncid.sourceforge.net" or "192.168.22.10"

> - The installer will not auto start ncid at login, you can create
    a link in the start menu if you like.  See below for configuring
    the link.

### <a name="instl_win_cc"></a>WINDOWS COMPLETE COMPILE:

> See [INSTALL (generic)](#instl_generic_top) and  
  [INSTALL-Cygwin](#instl_cygwin_top) or  
  [INSTALL-Ubuntu](#instl_ubuntu_top).

### <a name="instl_win_ci"></a>WINDOWS COMPLETE INSTALL:

> [INSTALL-Ubuntu](#instl_ubuntu_top) on Windows or  
  [INSTALL-Cygwin](#instl_cygwin_top)

> if you need to install the
  complete NCID package, including server, client, and gateways.

> The serial port functions of ncidd do not work under Windows or
  Cygwin so you must use the SIP or YAC gateway with it.  It is
  unknown if a modem will work under Ubuntu so you may need to
  use a gateway with it also.  If a modem is usable, it should
  be a modem that supports Linux like the USB modems described
  in [Incomplete list of working modems](#modems_list).

> NCID under Cygwin is a fairly complex command line install, and there
  are some performance issues with it.  It is recommended you try Ubuntu.  

> See [INSTALL-Cygwin](#instl_cygwin_top) if you want to install Cygwin 
  and NCID.

> NCID under Ubuntu is an easy install.  You can use the GUI based
  package manager to install/update/remove it.  

> See [INSTALL-Ubuntu](#instl_ubuntu_top) if you want to install 
  Ubuntu and NCID.

### <a name="instl_win_tcl"></a>NCID.TCL INSTALL:

> Use this method only if you want to run ncid.tcl instead of ncid.exe
  This was the original install method.  You need to get ncid.tcl from
  the source package.

> Download the tcl/tk interpreter:

> - http://aspn.activestate.com/ASPN/Downloads/ActiveTcl/
> - click on download
> - click on next
> - click on ActiveTcl ?.?.?.? Self-extracting AS Package

> Install tcl/tk:

> - Run the file downloaded: ActiveTcl?.?.?.?-win32-ix86.exe

> Install ncid:

> - Unzip ncid-0.?.zip to c:\ or any location you prefer
    it will add a directory called ncid with files in it.

> - Create a shortcut on the desktop to ncid.tcl, for example:  

          c:\ncid\ncid.tcl

> - If the server is not on the same computer, open the
    shortcut properties and include the IP address (or the
    DNS name) with the program name in "Target:" field.

>> for example, if Target has C:\ncid

>> add IP address:

            C:\ncid 192.168.0.1

>> or, if path, in Target has spaces:

            E:\Program Files\ncid

>> add quotes around path, then add the IP address or DNS name:  

            "E:\Program Files\ncid" 192.168.0.1

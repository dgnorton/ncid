Last edited: Sun Mar 9, 2014

## <a name="instl_generic_top"></a>Generic INSTALL and Overview

>  If using sip2ncid, see [sip2ncid setup](#gateways_sip).  
   If using wc2ncid, see [wc2ncid setup](#gateways_wc).  
   If using yac2ncid, see [yac2ncid setup](#gateways_yac).

> [Table of Contents](#doc_top)

### Index

> * [Layout](#instl_generic_layout)
  * [Compile](#instl_generic_compile)
  * [Install](#instl_generic_install)
  * [Test Using a Modem](#instl_generic_modem)
  * [Test Using a Device (like the NetCallerID box)](#instl_generic_device)
  * [Test Using `sip2ncid`](#instl_generic_sip)
  * [Test Using `wc2ncid`](#instl_generic_wc)
  * [Test Using `yac2ncid`](#instl_generic_yac)

### <a name="instl_generic_layout">Layout</a>

* The programs go into `$prefix/bin` and `$prefix/sbin`.
* The config file goes into `$prefix2/etc`.
* The modem link or driver is expected in `$prefix3/dev`.
* The LOG file is expected in `$prefix3/var/log`.
* The man pages go into `$MAN` which is `$prefix/share/man`.
* The defaults are `prefix=/usr/local`, `prefix2=$prefix` and `prefix3=`.

> ####Fedora####
* The init scripts go into `$prefix2/etc/rc.d/init.d`.

> ####Debian, Ubuntu or Raspberry Pi (RPi)####
* The init scripts go into `$prefix2/etc/init.d`.

> ####FreeBSD####
* The rc scripts go into `$prefix2/etc/rc.d`.

> ####Macintosh OSX####
* The plist scripts go into `$(prefix3)/Library/LaunchDaemons`.

### <a name="instl_generic_compile">Compile</a>

>**Note:** The Makefile requires GNU make.
See the top of the Makefile for more information on targets.

* The `libpcap` library and header files must be installed
    to compile the `sip2ncid` gateway.

* Obtain `libpcap` from [TCPDUMP & LIBPCAP](http://www.tcpdump.org/)
  or the package depository of your Linux distribution.
  For example, if your distribution uses yum try:

      `yum install libpcap libpcap-devel`

* To configure programs and config file for /usr/local:

      `make local`

* To compile programs for /usr, and the config file for /etc:

      `make package`

* To compile programs for Fedora:

      `make fedora`

* To compile programs for RHEL (Red Hat Enterprise Linux):

      `make redhat`

* To compile programs for Debian, Ubuntu or Raspberry Pi:

      `make ubuntu`

* To compile programs for Macintosh OSX:

      `make mac` *OR* `make mac-fat`

* To cross-compile for the TiVo:

      `make tivo-s1`  
      (requires TiVo PPC cross-development):  
      `/usr/local/tivo`

      `make tivo-s2`  
      (requires TiVo MIPS cross-development):  
      uses `$(MIPSXCOMPILE)` prefix

### <a name="instl_generic_install">Install</a>

>**Note:** See the top of the Makefile for more information on targets.

* To install in `/usr/local` (man pages go into `/usr/local/share/man`):

      `make install`

* To install in `/usr/local` (man pages go into `/usr/local/man`):

      `make install MAN=/usr/local/man`

* To install programs in `/usr`,  
  config file in `/etc`,  
  and man pages in `/usr/share/man`:

      `make package-install`

      This also works:

      `make install prefix=/usr prefix2=`

* To install programs for Fedora:

      `make fedora-install`

* To install programs for RHEL (Red Hat Enterprise Linux):

      `make redhat-install`

* To install programs for Debian, Ubuntu or Raspberry Pi

      `make ubuntu-install`

* To install programs for Macintosh OSX

      `make mac-install`

### <a name="instl_generic_modem">Test Using a Modem</a>

* Start in this order:  

    `ncidd`  
    `ncid`

    Call yourself.

* If you have problems, start `ncidd` in debug mode:  

        ncidd -D

* To get more information, add the verbose flag:  

        ncidd -Dv3

* To also look at the alias structure:  

        ncidd -Dv9

* The last three lines will be similar to:  

        Modem set for CallerID.  
        Network Port: 3333  
        Wrote pid 20996 in pidfile: /var/run/ncidd.pid

* If ncidd aborts when you call yourself with something like:

        Modem set for CallerID.
        Modem Error Condition. (Phone rang here)
        /dev/ttyS1: No such file or directory

      You need to set `ncidd` to ignore modem signals.
      Uncomment the following line in `ncidd.conf`:

        #set sttyclocal = 1

* You should see the Caller ID lines between the first and second RING.

* If Caller ID is not received from the modem, and if *gencid* is not set
  you will only see RING for each ring.

      If *gencid* is set (the default), you will get a CID at RING number 2:

        07/13/2010 15:21  RING No Caller ID

      This indicates one of three problems:

          The modem is not set for Caller ID
          The modem does not support Caller ID
          The Telco is not providing Caller ID

> Once you solve the problems, restart ncidd normally.

### <a name="instl_generic_device">Test Using a Device (like the NetCallerID box)</a>

* Start in this order:

    `ncidd`  
    `ncid`

    Call yourself.

*  If you have problems, start `ncidd` in debug mode:

      ncidd -D

* To get more information, add the verbose flag:

      ncidd -Dv3

* To also look at the alias structure:

      ncidd -Dv9

* The last three lines will be similar to:

         CallerID TTY port initialized.
         Port: 3333
         pid 20996 in pidfile: /var/run/ncidd.pid

* Once you solve any problems, restart `ncidd` normally.

### <a name="instl_generic_sip">Test Using sip2ncid</a>

* Start in this order:

    `ncidd`  
    `sip2ncid` (review Setup-sip2ncid)  
    `ncid`

    Call yourself.

* If you have problems, start `ncidd` in debug mode:

        ncidd -D

* To get more information, add the verbose flag:

        ncidd -Dv3

* To also look at the alias structure:

        ncidd -Dv9

* The last three lines will be similar to:

        CallerID only from CID gateways
        Network Port: 3333
        Wrote pid 20996 in pidfile: /var/run/ncidd.pid

* Once you solve any problems, restart `ncidd` normally.

### <a name="instl_generic_wc">Test Using wc2ncid:</a>

* Start in this order:

    `ncidd`  
    `wc2ncid` (review Setup-wc2ncid)  
    `ncid`

    Call yourself.

* If you have problems, start `ncidd` in debug mode:

        ncidd -D

* To get more information, add the verbose flag:

        ncidd -Dv3

* To also look at the alias structure:

        ncidd -Dv9

* The last three lines will be similar to:

        CallerID only from CID gateways
        Network Port: 3333
        Wrote pid 20996 in pidfile: /var/run/ncidd.pid`


* Once you solve any problems, restart `ncidd` normally.

### <a name="instl_generic_yac">Test Using yac2ncid</a>

* Start in this order:

    `ncidd`  
    `yac2ncid` (may need to add options)  
    `ncid`

    Call yourself.

 * If you have problems, start `ncidd` in debug mode:

        ncidd -D

 * To get more information, add the verbose flag:

        ncidd -Dv3

 * To also look at the alias structure:

        ncidd -Dv9

* The last three lines will be similar to:

        CallerID only from CID gateways
        Network Port: 3333
        Wrote pid 20996 in pidfile: /var/run/ncidd.pid

* Once you solve any problems, restart `ncidd` normally.

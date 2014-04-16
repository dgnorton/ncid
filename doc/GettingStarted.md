Last edited: Sun Feb 9, 2014

## <a name="getstarted_top"></a>Getting Started

> [Table of Contents](#doc_top)

> NCID can be overwhelming for users who have never used it. 
  Current users of NCID are probably not aware of all of its features, 
  or how to use them properly. This document will try to help with 
  those cases.  The [FAQ](#faq_top) should also be of some help.

> In this document:

> - NCID is the package name
> - ncidd is the server name
> - ncid is the client name
> - Unix is a generic term to mean any UNIX-like or Linux-like
    operating system, e.g., Fedora, FreeBSD, Mac OS X, Debian, etc.
> - Uncommenting a line means to remove the **#**

### Getting Started Index

> * [Install the NCID package](#getstarted_pkg)
> * [Configure the ncidd server](#getstarted_cs)
> * [Configure the ncid client](#getstarted_cc)
> * [NCID startup](#getstarted_ns)

### <a name="getstarted_pkg"></a>Install the NCID package

> See the list of 
  [Package Distributions](http://ncid.sourceforge.net/#Distributions).

> SourceForge distributes NCID packages for several operating systems.
  In addition, operating system specific third parties distribute NCID.
  For example, there are Ubuntu and Fedora repositories that include NCID,
  making it easy to install with their package management applications; 
  however, they are not always up-to-date with the latest version at
  SourceForge.

> The first step is to download and install the NCID package that contains
  the server, gateways, and client for your operating system.  If you are
  using Fedora, Ubuntu, or Raspbian, you can download the rpm or deb package 
  directly from SourceForge. There are many distributions based on Redhat or
  Ubuntu so the Fedora or Ubuntu packages may install just fine. (For example,
  Linux Mint is an operating system based on Ubuntu.) Refer to the 
  **INSTALL-"operating system"** section for your "operating system".

> If you cannot locate a package, you can download the source, compile,
  and install it.  Refer to the [INSTALL (generic)](#instl_generic_top) section
  of this documentation.

### <a name="getstarted_cs"></a>Configure the ncidd server

> Now that you have installed NCID, you need to configure the method used
  to obtain Caller ID:

  > - [a Caller ID modem connected to a Unix computer](#getstarted_modem)
  > - [the serial NetCallerID device connected to a Unix computer](#getstarted_netc)
  > - [a Caller ID modem on a Windows computer via the NCID YAC 
      (Yet Another Caller ID) gateway](#getstarted_yac)
  > - [VoIP (Voice over Internet Protocol) phones via the NCID SIP 
      (Session Initiation Protocol) gateway](#getstarted_sip)
  > - [Whozz Calling (WC) Ethernet Link network device via the NCID WC 
      gateway](#getstarted_wc)
  > - [an Android smart phone via the NCID Remote Notifier (RN) gateway](#getstarted_rn)


> ####  <a name="getstarted_modem"></a> **Using a modem connected to a Unix computer**

>> Most modern modems support Caller ID but to determine if yours does follow
   the steps below and then refer to [Modem Caller ID Test](#modems_test).

>> The server needs to know which port the modem is on.  You do this
   by editing **ncidd.conf** and either uncomment one of these lines, 
   or add a line with the correct port:

            # The default tty port: /dev/modem
            # set ttyport = /dev/cu.modem # default Mac OS X internal modem
            # set ttyport = /dev/cu.usbmodem24680241 # Mac OS X USB modem (DualComm, Zoom)
            # set ttyport = /dev/ttyS0 # Linux Serial Port 0
            # set ttyport = /dev/ttyACM0 # Linux USB modem 0

>> If you wish to use the hangup feature, you need to uncomment this line:

            # set hangup = 1

>> After modifying **ncidd.conf**, ncidd must be started.

> ####  <a name="getstarted_netc"></a> **Using a serial NetCallerID device connected to a Unix computer**

>> The serial 
   [NetCallerID](http://bedford.nyws.com/BI.asp?Page=CBG/BI/Feb2002/eye.htm#2)
   device is no longer manufactured by Ugotcall, but you can sometimes find 
   it on eBay.

>> Even though it supports Caller ID, the NetCallerID device is not a modem
   and it does not support the NCID hangup feature. Start by hooking it
   up to a serial port and making the changes [above](#getstarted_modem). Once that is completed, 
   make these additional changes to **ncidd.conf**:

>> Uncomment this line:

            # set nomodem = 1

>> Leave this line commented:

            # set hangup = 1

>> After modifying **ncidd.conf**, ncidd must be started.

> ####  <a name="getstarted_yac"></a> **Using a Caller ID modem on a Windows computer via the NCID YAC gateway**

>> You would use the YAC gateway if you are using a YAC server on a
   Windows computer running Microsoft Windows 98 or later.

>> We have a complete section devoted to the YAC gateway. See
   [yac2ncid setup](#gateways_yac)
   in the [Gateways](#gateways_top) topic for more information.

> ####  <a name="getstarted_sip"></a> **Using the SIP Gateway**

>> You would use the sip2ncid gateway if your VoIP phone is using SIP.

>> We have a complete section devoted to the SIP gateway. See
   [sip2ncid setup](#gateways_sip)
   in the [Gateways](#gateways_top) topic for more information.

> ####  <a name="getstarted_wc"></a> **Using the Whozz Calling (WC) gateway**

>> You would use the wc2ncid gateway if you are using a Whozz 
   Calling Ethernet Link device. Serial Whozz Calling units are not
   currently supported.

>> We have a complete section devoted to the WC gateway. See
   [wc2ncid setup](#gateways_wc)
   in the [Gateways](#gateways_top) topic for more information.

> ####  <a name="getstarted_rn"></a> **Using the Android smart phone Remote Notifier (RN) gateway**

>> You would use the rn2ncid gateway if you are using an Android smart phone.

>> We have a complete section devoted to the RN gateway. See
   [rn2ncid setup](#gateways_rn) 
   in the [Gateways](#gateways_top) topic document for more information.

### <a name="getstarted_cc"></a>Configure the ncid client

> Normally the client does not need to be configured, but
  you should review **ncid.conf** to see if you want to change 
  the defaults for displaying the number format, displaying the 
  date format, and ring options if using an output module. There 
  are other changes you can also make.

> After making any changes to **ncid.conf**, start the ncid client.

> **IMPORTANT:** The ncidd server and any needed gateways should
   already be running.

### <a name="getstarted_ns"></a>NCID Startup

> At this point you should have NCID functional. The [INSTALL](#instl_generic_top)
  section for your operating system explains how to make sure NCID is 
  working properly.

> The [INSTALL](#instl_generic_top) section also explains how to start NCID at boot
  and how to manually start the server, gateways, and client.

> If you are having any problems you can ask for assistance in the NCID
  [Help](http://sourceforge.net/p/ncid/discussion/275237/) or
  [Open Discussion](http://sourceforge.net/p/ncid/discussion/275236/) 
  forums on SourceForge.

Last edited: Mon Dec 30, 2013

## <a name="faq_top"></a>NCID FAQ

> [Table of Contents](#doc_top)

### FAQ Index

> [General](#faq_gen)

> - [What is Caller ID?](#faq_cid)
> - [What is NCID?](#faq_ncid)
> - [Does NCID only support one client?](#faq_notone)
> - [Can I have multiple servers and clients?](#faq_mult)
> - [Can I run the NCID client under Windows?](#faq_win)
> - [How do I determine if my modem supports Caller ID?](#faq_modem)
> - [What is an NCID gateway?](#faq_gate)
> - [Can NCID be used with YAC (Yet Another Caller ID)?](#faq_yacok)
> - [Does NCID support more than one phone line?](#faq_line)
> - [What packages are distributed?](#faq_pkg)

> [Server](#faq_ser)

> - [What is an "alias" and how do I configure one?](#faq_alias)
> - [What is a "blacklisted" caller and how do I configure one?](#faq_bl)
> - [What is a "whitelisted" caller and how do I configure one?](#faq_wl)
> - [How do I configure NCID to auto hangup on specific calls?](#faq_hup)

> [Gateways](#faq_gw)

> - [How do I configure NCID to use the SIP Gateway?](#faq_sip)
> - [How do I configure NCID to use the YAC (Yet Another Caller ID) Gateway?](#faq_yac)
> - [How do I configure NCID to use the Whozz Calling (WC) Gateway?](#faq_wc)
> - [How do I configure NCID to use the Remote Notifier Gateway?](#faq_rn)

> [Client](#faq_cli)

> - [How many ways does the client display the Caller ID?](#faq_disp)

> [Client Output Modules](#faq_out)

> - [What is an output module?](#faq_mod)
> - [What output modules are available?](#faq_avail)
> - [Can output modules be configured?](#faq_modconf)
> - [How are output modules started?](#faq_modst)
> - [How do I configure the page module to send the CID
    information to my cell phone?](#faq_page)

### <a name="faq_gen"></a>General
- <a name="faq_cid"></a> **What is Caller ID?**

> This is best explained in this
   [Caller ID](http://en.wikipedia.org/wiki/Caller_IDi/)
   article on Wikipedia.

- <a name="faq_ncid"></a> **What is NCID?**

> NCID is a Network Caller ID package that distributes Caller
  ID over a network to a variety of devices and computers.

> NCID consists of:

> + A server (`ncidd`) that normally uses a device to monitor a
    telephone line for CID information.
> + A Universal Client (`ncid`) that obtains the CID information
    from the NCID server and displays it.
> + Multiple gateways that obtain the Caller ID information
    and send it to the NCID server as a CID message.
> + Command line tools that deal with the Whozz Calling (WC) 
    Ethernet Link device, and edit or list the **cidcall.log**, 
    **ncidd.alias**, **ncidd.blacklist**, and **ncidd.whitelist**
    files.

> The Universal Client has output modules that can be used
  to push CID to other computers and devices:

> - TiVo
> - MythTV
> - pager
> - cell phone, using the email-to-SMS gateway of the carrier
> - smartphones and tablets running Android or iOS
> - "speak", using a text-to-speech converter
> - LCD displays

> See the
  [NCID](http://en.wikipedia.org/wiki/NCID)
  article on Wikipedia.

- <a name="faq_notone"></a> **Does NCID only support one client?**

> The NCID package only comes with one client, but other clients
  are available such as `NCIDPop` and `LCDncid`.

> [Third party clients](http://ncid.sourceforge.net/#OtherPackages)
  are also available:

> - Apple iPhone, iPod Touch, iPad
> - Apple Mac OS X
> - GoogleTV and other Android devices
> - GB-PVR, a fully featured Personal Video Recorder (PVR) and media center

- <a name="faq_mult"></a> **Can I have multiple servers and clients?**

> There should only be one server per phone line.

> NCID is designed to have multiple clients.  For example:
  a client on a TiVo, a client on each computer in your
  network, and a client to handle your cell phone.


- <a name="faq_win"></a> **Can I run the NCID client under Windows?**

> The GUI client is the only part of NCID that runs directly under
  Windows.  Output modules are not supported.

> If you want to run the complete NCID distribution, you need to
  install 
  [Cygwin](http://www.cygwin.com).
  You need to configure the NCID server
  so it will only use its gateways to obtain the Caller ID.  If you
  want to use a modem, you need to also install a YAC server.

- <a name="faq_modem"></a> **How do I determine if my modem supports Caller ID?**

> The modem documentation should tell you if the modem supports
  Caller ID and how to set it up.  NCID will try two ways to
  configure a modem for Caller ID, and the configuration file
  (**ncidd.conf**) has other methods you can try.

> NCID documentation has a section called [Modems](#modems_top) that gives
  some information on configuring a modem for Caller ID,
  and there is also a section called [Modem Caller ID Test](#modems_test)
  that tells how to use ncidd to test the modem.

- <a name="faq_gate"></a> **What is an NCID gateway?**

> An NCID gateway obtains the Caller ID information
  and sends it to the NCID server as a CID message. Currently included 
  gateways are:  

> - A SIP Gateway that obtains the CID information
    using VoIP SIP packets and sends it to the NCID server.  
> - A YAC (Yet Another Caller ID) Gateway that obtains the CID 
    information from a YAC modem server.  
> - A [Whozz Calling](http://www.callerid.com/products/ethernet-link/)
   (WC) Ethernet Link device gateway that obtains the CID information 
   from multiple POTS (Plain Old Telephone Service) lines.  
> - A gateway for the Android app "Remote Notifier" that obtains smart phone 
    CID and text messages.  
> - An NCID-to-NCID Gateway that sends the CID information
    from one or more NCID servers to a selected NCID server.
  

- <a name="faq_yacok"></a> **Can NCID be used with YAC (Yet Another Caller ID)?**

> Yes. NCID has a YAC output module and a YAC Gateway.

> The YAC output module is used with the NCID client to obtain 
  the CID information from the NCID server and send it to YAC 
  listeners.

> The YAC gateway receives the CID information from a YAC 
  modem server, formats it and sends it to the NCID server 
  as a CID message. If your windows PC has a modem, you can install
  YAC and configure it to send the CID to the YAC Gateway.

- <a name="faq_line"></a> **Does NCID support more than one phone line?**

> Yes, NCID supports one modem or serial device, multiple SIP
  Gateways, multiple YAC Gateways, and multiple [Whozz Calling](http://www.callerid.com/products/ethernet-link/)
  (WC) devices using a WC gateway.

> Each SIP Gateway can support multiple VoIP telephone connections.

> Each WC device can support either 2, 4, or 8 POTS (Plain Old Telephone Service) lines.

- <a name="faq_pkg"></a> **What packages are distributed?**

> - NCID: Package includes a server, client, and gateways.
> - NCID Applet: A Gnome2 applet NCID client.
> - LCDncid: An NCID client that outputs to a LCD display using LCDproc.
> - NCIDPop: An NCID popup client for Mac OS X and Windows.
> - NCIDmod: TivoWebPlus modules for viewing the NCID caller log.
> - OUT2OSD: A TiVo display program used by TiVoCID.

### <a name="faq_ser"></a>Server

- <a name="faq_alias"></a> **What is an "alias" and how do I configure one?**

> An "alias" allows you to replace a generic Caller ID name 
  with a custom one that is more meaningful. You can configure several
  hundred aliases if you want.  Aliases are stored in the **ncidd.alias**
  file.
  
> For example, if an incoming call has the name "WIRELESS CALLER" you can use
  an alias to change it to the real name of the caller. You would use
  this form of alias:

>> **alias NAME "FROM" = "TO" if "TELEPHONE_NUMBER"**

> Since we do not care what name is there, we will use '\*' in
  the FROM field.  The TO field can contain spaces so in our
  case we want it to say: "John on cell".  The most important
  field is the TELEPHONE_NUMBER; this must match the number
  ncidd receives, and in most cases, it includes a '1', even
  though it is not displayed.  Putting in the values, our alias
  looks like this:

>> **alias NAME * = "John on cell" if 14075551212**

> The complete documentation for aliases is in the **ncidd.alias**
  man page, and as comments in the **ncidd.alias** file.

- <a name="faq_bl"></a> **What is a "blacklisted" caller and how do I configure one?**

> The blacklist is a list of names or numbers that NCID will automatically
  hangup.  The blacklisted names and numbers are stored in the **ncidd.blacklist**
  file.

> The name or number in the blacklist is treated as a substring of the
caller name or number.  For example, using a 10 digit US number:

>> 3215551212 will only match 3215551212  
   321555 will match any number with 321555 in it  
   ^321555 will match any number  beginning with 321555

> The **ncidd.blacklist** file comes preconfigured for PRIVATE
  names, a spoofing area code, and a few expensive area codes.

> The complete documentation for the blacklist is in the **ncidd.blacklist**
  man page, and as comments in the **ncidd.blacklist** file.

- <a name="faq_wl"></a> **What is a "whitelisted" caller and how do I configure one?**

> The whitelist is a list of names or numbers in the **ncidd.whitelist**
  file.  If a call matches a name or number in the **ncidd.blacklist**
  file, the whitelist file is consulted to see if the call should be
  allowed.

> As an example, the blacklist file comes preconfigured to blacklist
  the entire 999 unused area code.  If you want to allow a specific number
  from area code 999, you would add it to **ncidd.whitelist**:

>> 9995551212

> You might notice there are 2 entries in the blacklist file for each
  of the blacklisted area codes.  This is because in the US some systems
  have send a leading **1** and some do not.  Not knowing which system a
  user might have, two entries are made to work with both types. Thus
  the above example becomes:

>> 9995551212 19995551212

> The complete documentation for the whitelist is in the **ncidd.whitelist**
  man page, and as comments in the **ncidd.whitelist** file.

- <a name="faq_hup"></a> **How do I configure NCID to auto hangup on specific calls?**

> The server hangup feature is configured in the "Automatic Call 
  Hangup" section of the **ncidd.conf** file. Just remove the '#' from
  the line:

>> **\# set hangup = 1**

> Once you change **ncidd.conf**, you must start/restart ncidd to read it.

> You need to enter the caller name or telephone number in the 
  **ncidd.blacklist** file, usually one name or number per line.

> If there is a match on the name or number when a call comes in,
  it will immediately be terminated. When a call is terminated,
  an "HUP" entry is made in the **ncidd.log** file.

### <a name="faq_gw"></a>Gateways

- <a name="faq_sip"></a> **How do I configure NCID to use the SIP gateway?**

> You need to configure your network, ncidd, and the sip2ncid gateway
  for the ports that SIP Invite uses.

> You can test for network packets in general, or SIP packets
  for a particular port, using sip2ncid.  You would need to
  use the -T|--testall or the -t|--testudp option. Once you
  determine the ports being used, enter them in **sip2ncid.conf**.

> If you have SIP packets on your home network, your network
  is already configured and ready to use.  However, a home network
  may need to be configured to receive SIP packets.
  For a router/phone device you may need to put your computer
  in the Demilitarized Zone (DMZ) to see SIP packets; usually port
  forwarding will not work.  You should also review this tutorial:
  [Configuring your home network for SIP-based callerID](http://www.files.davidlaporte.org/sipcallerid.html)

> If you are using a POTS  (Plain Old Telephone Service) line and SIP,
  no additional ncidd configuration is necessary.  If you are only using
  SIP you need to set *noserial* in **ncidd.conf**. Once you change **ncidd.conf**, 
  you must start/restart ncidd to read it.

- <a name="faq_yac"></a> **How do I configure NCID to use the YAC (Yet Another Caller ID) Gateway?**

> You need to configure ncidd, yac2ncid, and your YAC server.

> If you are using a POTS  (Plain Old Telephone Service) line and
  YAC, no additional ncidd configuration is necessary.  If you are
  only using YAC, or SIP and YAC, you need to set *noserial* in
  **ncidd.conf**. Once you change **ncidd.conf**, you must start/restart ncidd to read it.

> If the YAC server is on the same computer as ncidd,
  no configuration is necessary.  If it is on a different
  computer, the IP address of NCID needs to be inserted
  into the **yac2ncid.conf** file.

> The NCID YAC Gateway is a YAC Listener, so the YAC server
  needs the address IP address of the computer running yac2ncid.

- <a name="faq_wc"></a> **How do I configure NCID to use the Whozz Calling (WC) Gateway?**

> You need a [Whozz Calling](http://www.callerid.com/products/ethernet-link/) Ethernet Link device.
  You can get either a basic or a deluxe 2, 4, or 8 port model. 
  You can configure as many as you would like, in any combination
  of 2, 4, or 8 port units.

> You need to configure ncidd, wc2ncid, and the Whozz Calling device.

> Because the POTS (Plain Old Telephone Service) lines are connected
  directly to the Whozz Calling device, you need to set *noserial* in **ncidd.conf**.
  Once you change **ncidd.conf**, you must start/restart ncidd to read it.

>   If your local network uses 192.168.0.x you do not need to configure
  **wc2ncid.conf**.  If you have a different network, say 192.168.1.x, then you
  need to modify **wc2ncid.conf**:

>> Edit **wc2ncid.conf**:  
   change the line: wcaddr = 192.168.0.90  
   to: wcaddr = 192.168.1.90

> The wc2ncid gateway script needs to be run at least once before using it with NCID. It also needs to be run whenever you change *wcaddr* in **wc2ncid.conf**.
>> wc2ncid --set-wc

> Make sure the Whozz Calling device is set properly. Start wc2ncid in test mode:
>> wc2ncid -t

- <a name="faq_rn"></a> **How do I configure NCID to use the Remote Notifier Gateway?**

> You need to install the free 
  [Remote Notifier for Android](https://play.google.com/store/apps/details?id=org.damazio.notifier&hl=en) 
  app from Google Play. 

> You need to configure the Remote Notifier app, ncidd, and rn2ncid.

> Launch Remote Notifier configure the IP address of the computer running
  the NCID server.

> If you are using a POTS (Plain Old Telephone Service) line and Remote 
  Notifier, no additional ncidd configuration is necessary. If you are 
  only using Remote Notifier, set *noserial* in **ncidd.conf**. 
  Once you change **ncidd.conf**, you must start/restart ncidd to read it.

> Normally rn2ncid does not need to be configured unless you are using 
  ncid-page to send calls and messages to your smart phone. In that 
  case you need to edit the *reject* line at the end of the **rn2ncid.conf** 
  file: Specify the "from" of SMS/MMS messages to be rejected and not passed
  through to the NCID server. This is usually an email address dedicated to
  the SMS-to-email service of your carrier.

> Test rn2ncid without connecting it to the ncidd server.

>>  rn2ncid --test

> Choose the Remote Notifier "Send test notification" option.

### <a name="faq_cli"></a>Client

- <a name="faq_disp"></a> **How many ways does the client display the Caller ID?**

> The client receives the Caller ID from the server and displays
  it in one of three ways:

> - **Its GUI Window**
> - **A Terminal Window**
> - **Using a Output Module**

> An output module can also send the information to a smart phone, pager,
  email address, and more.

### <a name="faq_out"></a>Client Output Modules

- <a name="faq_mod"></a> **What is an output module?**

> An output module receives the Caller ID information from the
  ncid client and gives the client new functionality.

> There are various output modules than come with NCID and there
  are also third party ones.

- <a name="faq_avail"></a> **What output modules are available?**

> The following output modules are distributed:

> - ncid-alert: Send NCID call or message desktop notifications.
> - ncid-initmodem: Reinitialize the modem when "RING" is received
    as the number.
> - ncid-kpopup: Uses KDE to create a popup for the Caller ID.
> - ncid-mythtv: Displays the Caller ID on MythTV.
> - ncid-notify: Sends the Caller ID on an iOS device or an Android device.
> - ncid-page: Sends the Caller ID to a cell phone or pager.
> - ncid-samba: Creates a popup for the Caller ID on windows using Samba.
> - ncid-skel: Just echos the Caller ID.  Modify it to write new modules.
> - ncid-speak: Sends the Caller ID to a text-to-speech program.
> - ncid-tivo: Displays the Caller ID on a TiVo.
> - ncid-yac: Sends the Caller ID to YAC clients.
> - ncid-wakeup: Wakeup X-Windows.

- <a name="faq_modconf"></a> **Can output modules be configured?**

> Output modules are configured using files in the conf.d/
  directory.  There will be a separate file for each module
  that needs one, for example, conf.d/**ncid-tivo.conf**.

> For more information, see the comments in the individual files
  in the conf.d/ directory and the man page for each module.

- <a name="faq_modst"></a> **How are output modules started?**

> If you are using Debian, Fedora, Ubuntu, FreeBSD, OSX, or Raspbian
  you would use the OS specific ncid service script to activate
  the service.

> For distributions not based on Debian, Fedora, or BSD the modules
  need to be started manually, Here are three examples:

>> **ncid --no-gui --program ncid-page &**  
   **ncid --no-gui --program ncid-notify &**  
   **ncid --no-gui --program ncid-speak &**

> Each of the above commands start ncid using an output module
  and puts it in the background.  
  The first line starts ncid using the page output module.  
  The second line starts ncid using the notify output module.  
  The third line starts ncid using the speak output module.

- <a name="faq_page"></a> **How do I configure the page module to send the CID information to my cell phone?**

> You need to modify one line in **ncid-page.conf** and maybe one line
  in **ncid.conf**.
  
> Find this line in **ncid.conf**:

>> **PageTo=**

> *PageTo* needs to be set to your mobile provider's SMS e-mail address.
  Here are addresses for the major ones in the US:

>> **Sprint: phonenumber@messaging.sprintpcs.com**  
   **Verizon: phonenumber@vtext.com**  
   **T-Mobile: phonenumber@tmomail.com**  
   **AT&T: phonenumber@txt.att.net**  

> For example, if your provider is AT&T and your cell number is 1-321-555-1212,
  then your *PageTo* line becomes:
  <pre>
  PageTo=13215551212@txt.att.net</pre>
  
> If you want a page anytime the phone rings, you are finished.

> if you only want a page if the phone call is unanswered or is at a certain
  ring count, you need to uncomment the <i>ncid_page</i> line in **ncid.conf**,
  then change the ring count as desired.

> Be careful, all Caller ID devices do not indicate rings. If RING
  is not sent by the modem, a ring count will not work and the page
  will never be sent.

> If you are using a modem, there is no indication of whether the
  the phone was answered or not.  The modem sends RING to ncidd each
  time it gets the ringing signal.  When RING is not sent anymore ncidd
  will indicate the end of ringing.
  A ring count of 4 is a good value to assume the phone was not answered.
  Remove the '#' so you have this line:

>> **set ncid_page {set Ring 4}**

> If you are using SIP, you can configure it to send the page on
  hangup without an answer by modifying the above line to:

>> **set ncid_page {set Ring -1}**

> See the comments in the **ncid.conf** file for more information
  on configuring the ring option line.

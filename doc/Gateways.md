Last edited: Wed Apr 16, 2014

## <a name="gateways_top"></a>NCID Gateways

> [Table of Contents](#doc_top)

### Gateway Index

> [sip2ncid setup](#gateways_sip)  
  [wc2ncid setup](#gateways_wc)  
  [rn2ncid setup](#gateways_rn)  
  [yac2ncid setup](#gateways_yac)  

### <a name="gateways_sip"></a>sip2ncid setup

> How to setup VoIP Caller ID using sip2ncid.

> ### Sections:

>  [REQUIREMENT](#gateways_sipr)  
   [CONFIGURATION](#gateways_sipc)  
   [TESTING](#gateways_sipt)  
   [START/STOP/RESTART/STATUS/AUTOSTART](#gateways_sips)  

> #### <a name="gateways_sipr"></a>REQUIREMENT:

> VoIP telephone service using SIP.

> Configure your LAN for SIP.  
  See
  <a href="http://nomad.dyndns.org/ncid/doc/NCID_Documentation.html#devices_ata">ATA (Analog Terminal Adapter)</a>

> #### <a name="gateways_sipc"></a>CONFIGURATION:

> The ncidd server defaults to a using a modem to get Caller ID.  if
  you have a standard telephone line (POTS) modem configured, and you
  have at least one VoIP telephone line, all you need to do is 
  start sip2ncid to get Caller ID from VoIP.  The server will handle
  a modem and the sip2ncid gateway easily.

> If you are only using VoIP and do not want to use a modem, you
  need to configure ncidd by uncommenting this line in **ncidd.conf**:

          # set noserial = 1

> This tells ncidd to run without a serial device or modem connected.

> Once you change **ncidd.conf**, you must start/restart ncidd to read it.

> (Note: Do not confuse the *noserial* and *nomodem* settings.
  See [Note 1](#gateways_note1) for an explanation of the differences.)

> Use the sip2ncid `--listdevs` or `-l` option to see your network devices:

          sudo sip2ncid `--listdevs`

> If you are using a DirecTiVo and the command does not return anything, you
  need to load the af_packet kernel module:

          insmod /lib/modules/af_packet.o  
          (http://www.tivocommunity.com/tivo-vb/showthread.php?p=5728255#post5728255)

> #### <a name="gateways_sipt"></a>TESTING:

> To determine if you can receive any network packets, use the `--testall`
  or `-T` option:

          sudo sip2ncid `--testall`

> This will display a packet count and a packet type. It does not know
  all packet types so you may get some UNKNOWN packet types.  It also
  sets debug mode and verbose level 3. You can increase the verbose level
  to see more detail, but if you decrease it below 3, you will not
  see any packets.

> To determine if you can receive SIP data packets, use the `--testudp` or
  `-t` option:
  
          sudo sip2ncid `--testudp`

> This will display SIP packets and what, if anything, it does.  It also
  sets debug mode and verbose level 3.  You can also change the verbose
  level.  If you set verbose to 1, sip2ncid will display lines sent to
  the server instead of the packet contents:
  
          sudo sip2ncid `-tv1`

> If no packets are received in about 45 seconds:

          No SIP packets at port XXXX in XX seconds

> If sip2ncid terminates you should be able to see why and fix it.

> You can get a detailed usage message by executing:

          sip2ncid `--help`

> Sometimes it picks the wrong default interface. If you are using eth0:

          sudo sip2ncid `-ti` eth0

> If you need to see what interfaces are present you can use the
  `--interface` or `-i` option: 

          sudo sip2ncid `--listdevs`

> The display is:

          <interface> : <description>

>  The interface name is everything up to the first space.

> If you do not see any SIP packets, change to port 5061 and try again:

          sudo sip2ncid `--testudp` `--sip :5061`

> You should see something like:

          Network Interface: eth0  
          Filter: port 10000 and udp

> Then about every 20 seconds you should see something like:

          Packet number 1:
          Protocol: UDP  
          SIP/2.0 200 OK  
          Via: SIP/2.0/UDP 70.119.157.214:10000;branch=z9hG4bK-22b185d1  
          From: 321-555-7722 <sip:13215551212@atlas2.atlas.vonage.net:10000>;tag=46f26356c0a3394bo0  
          To: 321-555-7722 <sip:13215551212@atlas2.atlas.vonage.net:10000>  
          Call-ID: fa72d1c2-ead1bdcf@70.119.157.214  
          CSeq: 86785 REGISTER  
          Contact: 321-555-1212 <sip:13215551212@70.119.157.214:10000>;expires=20  
          Content-Length: 0

          Registered Line Number: 13215551212

> The Registered Line Number line will only appear in packet number 1.

> If you do not get the above, you may need to specify an address and/or port
  for sip2ncid to listen for the SIP Invite.  You cannot continue unless you
  get the above.

> If you are using the Linksys RT31P2 Router, you will not see any packets
  unless the computer is in its DMZ (Demilitarized Zone).  Port forwarding 
  the UDP port will not work.  You must set up the DMZ.  If you are using a 
  different VoIP router, try to put the computer in the DMZ and see if that 
  works.  If not, view the SIP tutorial:

> [Configure your home network for SIP-based Caller ID](http://www.files.davidlaporte.org/sipcallerid.html).

> Once you receive the above packets, call yourself.  If you do not get a
  Caller ID message sent to ncidd, you should get an error message saying
  what is wrong.  This has been tested with Vonage and may need tweaking
  for other VoIP service providers.

> If you had Caller ID sent to a client, setup is complete.  You can then
  restart sip2ncid without the test option so it will not display anything.
  You can also set it up to start at boot, along with ncidd.  If any options
  are needed at boot, add them to **sip2ncid.conf**.

> #### <a name="gateways_sips"></a>START/STOP/RESTART/STATUS/AUTOSTART:

> Normally sip2ncid is started using the provided init, service, rc, or
  plist script for your OS. For more information, refer to the 
  [INSTALL](#instl_generic_top) section for your OS.  If none is provided 
  you need to start sip2ncid manually:

          sudo sip2ncid &

> You can also set it up to start at boot, along with ncidd.  If any options
  are needed, add them to **sip2ncid.conf**.

> If sip2ncid did not work, you should have enough information to ask for help.

### <a name="gateways_wc"></a>wc2ncid setup

> How to setup one or more Whozz Calling Ethernet Link (WC) devices for
 Caller ID using wc2ncid.

> #### Sections:

>>  [REQUIREMENT](#gateways_wcr)  
    [CONFIGURATION](#gateways_wcc)  
    [TESTING](#gateways_wct)  
    [START/STOP/RESTART/STATUS/AUTOSTART](#gateways_wcs)  

> #### <a name="gateways_wcr"></a>REQUIREMENT:

> A Whozz Calling Ethernet Link (WC) device (see: http://callerid.com)
  connects to POTS (Plain Old Telephone System) lines and can handle
  2, 4, or 8 lines.  Some models only handle incoming calls while
  others handle incoming and outgoing calls.

> The Whozz Calling user manual tells how to hook up the device.
  You plug your POTS telephone lines into the device and you connect
  the device to your local network.

> #### <a name="gateways_wcc"></a>CONFIGURATION:

> All WC devices must have an IP address within your network in order
  for them to be configured for use by wc2ncid.  This limitation will
  be removed in a future release.  When you try to configure a device
  with an address outside your network, wc2ncid will either give a warning
  or an error message and terminate.  You can then use the wct script to
  change the IP address to one that is in your network.  Use the discover
  option of wct to locate the device:

          wct `--discover`

> The ncidd server defaults to using a modem to get Caller ID.  If
  you have a standard telephone line (POTS) modem configured, you
  can keep the modem and use the WC device to handle additional
  POTS or VoIP lines, or you can replace the modem with the WC device.

> It is recommended that you *not* use a modem so you need to configure ncidd
  by uncommenting this line in **ncidd.conf**:

          # set noserial = 1

> This tells ncidd to run without a serial device or modem connected.

> Once you change **ncidd.conf**, you must start/restart ncidd to read it.

> (Note: Do not confuse the *noserial* and *nomodem* settings.
  See [Note 1](#gateways_note1) for an explanation of the differences.)

> Next, edit **wc2ncid.conf** to configure one or more devices. Look for this
  line:
          wcaddr = 192.168.0.90

>   If your network is on 192.168.0 and the above address is not used,
    you can leave it.  If your network is on 192.168.1 you can set the
    IP address for WC device number 1 (WC-1), for example, by changing the
    line to be:

          wcaddr = 192.168.1.90

>   If you have 2 devices and want to use addresses 192.168.2.90 and
    192.168.2.91, WC device 1 is 192.168.2.90 and WC device 2 is
    192.168.2.91.

          wcaddr = 192.168.2.90, 192.168.2.91

> #### <a name="gateways_wct"></a>TESTING:

> Once you set the IP address for the WC device in **wc2ncid.conf**, start
  wc2ncid and tell it to configure the WC device:

          wc2ncid [`--test`] `--set-wc`

> The `--test` parameter is optional, but it is a good idea to use it so
  wc2ncid does not connect to the NCID server during the configuration
  process.

> If you have 2 or more WC devices, and they are both set to the same
  address or the factory default of 192.168.0.90, you need to change
  both addresses in **wc2ncid.conf**. For example:

          wcaddr = 192.168.0.91, 192.168.0.92

> Turn on one device and execute:

          wc2ncid [`--test`] `--set-wc`

> Terminate wc2ncid with `<CTRL><C>`. Leave the first device turned on, then
  turn on the second device and execute:

          wc2ncid [`--test`] `--set-wc`

> Both devices should be configured and operational.  Terminate wc2ncid
  with `<CTRL><C>`.

> If this is the first time you set wc2ncid up, you should test wc2ncid
  without connecting it to the ncidd server:

          wc2ncid `--test`

> The above command puts wc2ncid in test and debug modes at verbose level 3.
  It will display verbose statements on the terminal, ending with "Waiting
  for calls".  It should show the configured address for each device.
  Test mode prevents wc2ncid from connecting with ncidd.

> If wc2ncid terminates you should be able to see why and fix it.

> You can get a detailed usage message by executing:

          wc2ncid `--help`

> or print out the manual page by executing:

          wc2ncid `--man`

> Call yourself.  You should see more verbose messages as the call is
  processed.  If it looks OK, terminate wc2ncid with `<CTRL><C>`.

> Next, restart wc2ncid in debug mode so it will connect to ncidd:

          wc2ncid `-Dv3`

> Call yourself.  If you do not get a Caller ID message sent to ncidd,
  you should get an error message saying what is wrong.

> If you had Caller ID sent to a client, setup is complete.

> #### <a name="gateways_wcs"></a>START/STOP/RESTART/STATUS/AUTOSTART:

> Normally wc2ncid is started using the provided init, service, rc, or
  plist script for your OS. For more information, refer to the 
  [INSTALL](#instl_generic_top) section for your OS.  If none is provided
  you need to start wc2ncid manually:

          sudo wc2ncid &

> You can also set it up to start at boot, along with ncidd.  If any options
  are needed, add them to **wc2ncid.conf**.

> If wc2ncid did not work, you should have enough information to ask for help.

### <a name="gateways_rn"></a>rn2ncid setup
> How to setup Remote Notifier on an Android smart phone to
  send Caller ID and messages via the rn2ncid gateway.

> #### Sections:

>>  [REQUIREMENT](#gateways_rnr)  
    [CONFIGURATION](#gateways_rnc)  
    [TESTING](#gateways_rnt)  
    [START/STOP/RESTART/STATUS/AUTOSTART](#gateways_rns)  

> #### <a name="gateways_rnr"></a>REQUIREMENT:

>   The smart phone needs to be running Remote Notifier for Android from
    [Google Play](https://play.google.com/store/apps/details?name=org.damazio.notifier&hl=en)

>   Install it and configure it for the address of the computer running
    ncidd.

>   (The main web site for the android-notifier project is located at
    [Google Code](https://code.google.com/p/android-notifier), however,
    you do not need to download anything from there. You only need the
    app from
    [Google Play](https://play.google.com/store/apps/details?name=org.damazio.notifier&hl=en))

> #### <a name="gateways_rnc"></a>CONFIGURATION:

>   The ncidd server defaults to using a modem to get Caller ID.  If
    you have a standard telephone line (POTS) modem configured, you
    can keep the modem and use the rn2ncid gateway.


>   If you do not use a modem and you are not using another gateway,
    you need to configure ncidd by uncommenting this line in **ncidd.conf**:

          # set noserial = 1

> This tells ncidd to run without a serial device or modem connected.

> Once you change **ncidd.conf**, you must start/restart ncidd to read it.

> (Note: Do not confuse the *noserial* and *nomodem* settings.
  See [Note 1](#gateways_note1) for an explanation of the differences.)

> Normally rn2ncid does not need to be configured unless you are using 
  ncid-page to send calls and messages to your smart phone. In that 
  case you need to edit the *reject* line at the end of **rn2ncid.conf** 
  and specify the "from" of SMS/MMS messages to be rejected and not passed
  through to the NCID server. (If you do not do this, the result will be an
  endless loop which could result in excessively high data or text charges
  by your cell phone carrier.) The setting for *reject* is usually of the
  form root@[hostname] where [hostname] is the result of executing the
  Unix `hostname` command on the computer running ncidd.

> For example:

>> **$** hostname  
   smurfzoo.private  
   **$**
   

> Edit **rn2ncid.conf**:

          reject = root@smurfzoo.private

> #### <a name="gateways_rnt"></a>TESTING:

> If this is the first time you set rn2ncid up, you should test rn2ncid
  without connecting it to ncidd.

          rn2ncid `--test`

> The above command puts rn2ncid in test and debug modes at verbose level 3.
  It will display verbose statements on the terminal, ending with
  "Listening at port 10600".  It should show configured options.
  Test mode prevents rn2ncid from connecting with ncidd.

> If rn2ncid terminates you should be able to see why and fix it.

> You can get a detailed usage message by executing:

          rn2ncid `--help`

> or print out the manual page by executing:

          rn2ncid `--man`

> On your smart phone, launch Remote Notifier and choose
  "Send test notification".  rn2ncid should show something like this:

          NOT: PHONE 0123: PING Test notification

> (Note: 0123 is the phone ID and will be different for your phone.)

> If it looks OK, terminate rn2ncid with `<CTRL><C>`.
    
> Next, restart rn2ncid in debug mode so it will connect to ncidd:

          rn2ncid -Dv3

> Do the "Send test notification" again and it should be sent to the server
  and its clients.  If you do not get a "NOT" (short for "NOTIFY") message 
  sent to the server, you should instead get an error message saying what
  is wrong.

> If you had the PING "Test notification" sent to a client, setup is complete.

> #### <a name="gateways_rns"></a>START/STOP/RESTART/STATUS/AUTOSTART:

> Normally rn2ncid is started using the provided init, service, rc, or
  plist script for your OS. For more information, refer to the
  [INSTALL](#instl_generic_top) section for your OS.  If none is provided
  you need to start rn2ncid manually:

          sudo rn2ncid &

> You can also set it up to start at boot, along with ncidd.  If any options
  are needed, add them to **rn2ncid.conf**.

> If rn2ncid did not work, you should have enough information to ask for help.

### <a name="gateways_yac"></a>yac2ncid setup

> How to setup a YAC modem server for Caller ID using yac2ncid.

> #### Sections:

>>  [REQUIREMENT](#gateways_yacr)  
    [CONFIGURATION](#gateways_yacc)  
    [TESTING](#gateways_yact)  
    [START/STOP/RESTART/STATUS/AUTOSTART](#gateways_yacs)  

> #### <a name="gateways_yacr"></a>REQUIREMENT:

> A YAC server on a Windows computer running Microsoft Windows 98 or later.

> Go to the
  [YAC](http://www.sunflowerhead.com/software/yac/) homepage to download 
  the YAC server program. Follow the installation instructions.

> #### <a name="gateways_yacc"></a>CONFIGURATION:

>  Configure the YAC server by giving it the IP address where ncidd is running. 
   Do this by right-clicking the YAC icon in the System Tray, and then select 
   "Listeners...".

>  To configure NCID, uncomment this line in **ncidd.conf**:

          # set noserial = 1

> This tells ncidd to run without a serial device or modem connected.

> Once you change **ncidd.conf**, you must start/restart ncidd to read it.

> (Note: Do not confuse the *noserial* and *nomodem* settings.
  See [Note 1](#gateways_note1) for an explanation of the differences.)

> Normally yac2ncid does not need to be configured, but
  you should review **yac2ncid.conf** to see if you want to change 
  any of its defaults.

> After modifying **ncidd.conf** and **yac2ncid.conf**, you must
  start/restart ncidd first and then the yac2ncid gateway.

> #### <a name="gateways_yact"></a>TESTING:

> Make sure the YAC server is running on the Windows computer.

> Run the yac2ncid gateway with the verbose option:

          yac2ncid `-v`

> Call yourself. If you do not get a Caller ID message sent to ncidd,
  you should get an error message saying what is wrong.

> If you had Caller ID sent to a client, setup is complete. You can 
  then restart yac2ncid without the verbose option so it will not 
  display anything. You can also set it up to start at boot, along
  with ncidd.

> #### <a name="gateways_yacs"></a>START/STOP/RESTART/STATUS/AUTOSTART:

> Normally yac2ncid is started using the provided init, service, rc, or
  plist script for your OS. For more information, refer to the 
  [INSTALL](#instl_generic_top) section for your OS.  If none is provided 
  you need to start yac2ncid manually:

          sudo yac2ncid &

> You can also set it up to start at boot, along with ncidd.  If any options
  are needed, add them to **yac2ncid.conf**.

> If yac2ncid did not work, you should have enough information to ask for help.

<a name="gateways_note1"></a>
Note 1: In **ncidd.conf** there is an important difference between
the settings *noserial* and *nomodem*:

> - You would use *noserial* when you have no serial device connected at all.
> - You would use *nomodem* if you <u>do</u> have a serial device connected
    but it is not a modem. At the present time, the only *nomodem* device known
    to be used with NCID is the [NetCallerID](#gateways_id).

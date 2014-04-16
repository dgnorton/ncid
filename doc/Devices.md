Last edited: Wed Apr 16, 2014

## <a name="devices_top"></a>Supported Devices

> [Table of Contents](#doc_top)

### Devices Index

> * [Modems](#devices_modem)
> * [ATA (Analog Terminal Adapter)](#devices_ata)
> * [Whozz Calling](#devices_wc)
> * [NetCallerID](#devices_id)

### <a name="devices_modem"></a>Modems

> Any Caller ID serial or USB modem supported by the operating system
  can be used.
  See the [Incomplete list of working modems](#modems_list) in the
  [Modems](#modems_top) section.

> NCID can also use those rare modems that do not support Caller
    ID by configuring *gencid* in **ncidd.conf**, but such modems 
    are limited to the following features:

> - It can only tell you the date and time of the calls.
> - It can be used to hangup the call only when used in conjunction with a
    [Gateway](#gateways_top).

> See the modem [Configuration](#modems_mconf) section for information on
  configuring modems.

### <a name="devices_ata"></a>ATA (Analog Terminal Adapter)

> The ATA hardware is for VoIP (Voice over Internet Protocol).

> VoIP telephone services use an Analog Terminal Adapter, sometimes
  called a VoIP gateway.

> See also [VoIP Info](http://www.voip-info.org/wiki/view/ATA).

> In order to receive Caller ID from VoIP, the local network must be
  configured. Three configurations are considered here:

> - [One device: Cable/DSL Modem with integrated ATA device](#devices_d)
> - [Two devices: Cable/DSL Modem + Router Switch with integrated ATA device](#devices_mr)
> - [Three devices: Cable/DSL Modem + Router Switch + ATA device](#devices_mrd)

> #### <a name="devices_d"></a>One device: Cable/DSL Modem with integrated ATA device
> Many cable companies such as Comcast and Time Warner now offer bundled
   services, referred to in the industry as "triple play service." This
   delivers television, Internet service, and digital phone service via
   a single device.

> The protocol used for the digital phone service is usually proprietary.

> *NCID is not supported in this configuration.*

> #### <a name="devices_mr"></a>Two devices: Cable/DSL Modem + Router Switch    with integrated ATA device
> These router and ATA combo devices may be configured to put the Caller ID 
   on the built-in switch. If you have other routers working, please 
   contribute to this list:

> <pre>
      <b>ROUTER    MODEL      SETTINGS     CONFIGURATION</b>
      ------    -----      --------     -------------
      Linksys  WRTP54G        -         (has "P" in model name)
                                        use Vonage Talk
      Linksys  RT31P2        DMZ        put computer IP address in the DMZ
</pre>

> #### <a name="devices_mrd"></a>Three devices: Cable/DSL Modem + Router Switch + ATA device
> A stand-alone ATA device connected to your network will make its Caller ID
   info (Session Initiation Protocol, or SIP) available to all the other
   network devices that are listening for it. A typical setup has the ATA
   connected to one physical port on the router/switch, and the computer
   running NCID is connected to a different physical port. Most modern
   routers/switches isolate the network traffic on any one physical port
   from all the other physical ports. This is done on purpose to optimize
   network traffic throughput and provide better performance.

> The problem is that having the network traffic isolated in this way does
   not allow the NCID computer to ever receive the Caller ID info from the
   ATA.

> To circumvent this problem, you have several options:

> 1. Use an [Ethernet Tap](http://en.wikipedia.org/wiki/Network_tap).

>     This is the preferred method to obtain Caller ID. The 
      [USB Powered 5-Port 10/100 Ethernet Switch TAP](http://www.dual-comm.com/port-mirroring-LAN_switch.htm)
      by DualComm is a good choice and has been successfully used with NCID.
      The Dualcomm USB powered 5-port Ethernet Switch TAP provides mirrors all
      ethernet traffic on port 1 to port 5.   Simply plug your ATA into port 1
      and your NCID server into port 5. 

>      + The NCID server and ATA need to be (relatively) close together 
      in order to connect directly to the ethernet TAP.
>      + Requires no software configuration beyond the sip2ncid setup.
>      + Requires additional hardware.

> 2. Use [port mirroring](https://en.wikipedia.org/wiki/Port_mirroring).

>     Port mirroring is not port *forwarding*.
      This method requires that your home router be running a 
      Linux-based operating system such as [OpenWRT](https://openwrt.org) or
      [DD-WRT](http://www.dd-wrt.com).

>      + Requires DD-WRT, OpenWRT, or similar OS to be running on your
       home router.
>      + Requires manual configuration of the port mirror on your home router.
>      + Any modification to the firewall rules or QoS settings in DD-WRT 
         will result in the port mirroring commands being discarded; you will
         either have to reboot DD-WRT or manually enter the commands via SSH 
         to restart the port mirror.
>      + The NCID server and ATA can be located anywhere on your home network.
>      + No additional hardware needed.

>             STEPS TO CONFIGURE DD-WRT
>             =========================
>
>             Use ssh to connect to your router and enter the following commands:
> 
>>                iptables -t mangle -A POSTROUTING -d IP-OF-SIP_ATA -j ROUTE --tee --gw IP-OF-NCID-SERVER
>>                iptables -t mangle -A PREROUTING -s IP-OF-SIP_ATA -j ROUTE --tee --gw IP-OF-NCID-SERVER 

>             To verify the port mirror is setup properly, use:

>>                iptables -t mangle -L -v -n

>             Which will provide output that should show something similar to:

>>                Chain PREROUTING (policy ACCEPT 4510K packets, 2555M bytes)
>>                pkts bytes target prot opt in out source destination
>>                ....
>>                219 152K ROUTE 0 -- * * IP-OF-SIP_ATA 0.0.0.0/0 ROUTE gw:IP-OF-NCID-SERVER tee
>>                ....
>>
>>                Chain POSTROUTING (policy ACCEPT 17M packets, 7764M bytes)
>>                pkts bytes target prot opt in out source destination
>>                ....
>>                206 82184 ROUTE 0 -- * * 0.0.0.0/0 IP-OF-SIP_ATA ROUTE gw:IP-OF-NCID-SERVER tee
>>                ....

>             Follow the sip2ncid setup instructions to make sure that SIP packets are being received.
>
>             When everything is working properly, add the port mirroring commands to the DD-WRT 
>             startup commands in the Management tab so that they will be run whenever DD-WRT is rebooted.


> 3. Use [Ettercap](https://en.wikipedia.org/wiki/Ettercap_\(computing\)).

>     Convince your router to send all SIP packets to your NCID server
      and have your NCID server pass the packets on to your ATA.  This is most
      easily and robustly accomplished through the use of [ettercap](http://www.ettercap-project.org).

>     +  If the NCID server or ettercap fails, your router and SIP ATA will
      automatically start communicating directly within a few minutes as the 
      SIP ATA and router are not physically isolated.
>     + The NCID server and ATA can be located anywhere on your home network.
>     + No manual configuration of router is required.
>     + No additional hardware needed.

>             STEPS TO CONFIGURE ETTERCAP
>             ===========================
>
>             Perform these steps from a command prompt on your NCID server.
>
>             To determine the proper INTERFACE for ettercap to use, `ifconfig` will show all available 
>             interfaces. For example, wired ethernet is eth0 and wireless ethernet is wlan0 on Raspbian.

>             For Ubuntu, Raspbian and other Debian-based systems:

>>                sudo apt-get install ettercap-text-only
>>                sudo ettercap -T -D -i <INTERFACE> -M arp:remote <IP-OF-SIP_ATA> <IP-OF-HOME-ROUTER>

>             For Fedora and other Redhat-based systems:

>>                sudo yum install ettercap
>>                sudo ettercap -T -D -i <INTERFACE> -M arp:remote <IP-OF-SIP_ATA> <IP-OF-HOME-ROUTER>

>             Follow the sip2ncid setup instructions to make sure that SIP packets are being received.

>             You will want to add ettercap to your operating system startup sequence. Steps to do this
>             vary depending on distribution and even depending on the version of a specific distribution.
>             Consult your operating system documentation on how to do this.




> 4.  Use an [Ethernet *hub*](http://en.wikipedia.org/wiki/Ethernet_hubs).
      (Historical, not recommended)

>     Ethernet hubs pre-date
      [Ethernet switches](https://en.wikipedia.org/wiki/Network_switch)
      and do not isolate network traffic between physical ports.  Ethernet
      switches have largely rendered Ethernet hubs obsolete. Some Ethernet
      hubs manufactured today are actually Ethernet switches in disguise.
      See the 
      [hub reference](http://wiki.wireshark.org/HubReference)
      to determine if a hub is really a hub.

> 5. Use a router that supports SIP ALG
      ([Application-level gateway](http://www.voip-info.org/wiki/view/Routers+SIP+ALG)).
      (Historical, not recommended)

>     Unfortunately, not all routers implement ALG correctly. The following
      routers are known to use ALG properly with NCID. If you have other
      routers working, please contribute to this list:

> <pre>
          <b>ROUTER    MODEL      SETTINGS     CONFIGURATION</b>
          ------    -----      --------     -------------
          Linksys   WRT54G        -         (no "P" in model name) 
                                            SIP packets on port 5060 may need a firmware update
                                            if the firmware version is below 1.00.6. 
                                            See http://www.voip-info.org/wiki-Linksys+WRT54G 
                                            for firmware info.
          Linksys   RVS4000    L2 Switch    mirror port #1 to port #2 
                                            assumes gateway is port #1 and NCID SIP gateway is 
                                            monitoring port #2
</pre>

### <a name="devices_wc"></a>Whozz Calling

> A Whozz Calling (WC) Caller ID and Call monitoring unit is used in place
  of one or more modems.  There are various models that all monitor incoming
  calls, and some can monitor outbound as well.

> Only the Whozz Calling Ethernet Link devices are currently supported.
  The serial Whozz Calling units are not.

> See [CallerID.com](http://CallerID.com).

> Refer to the [wc2ncid setup](#gateways_wc) in the 
   [Gateways](#gateways_top) section configure 
   NCID to work with the WC device.

### <a name="devices_id"></a>NetCallerID

> The [NetCallerID](http://bedford.nyws.com/BI.asp?Page=CBG/BI/Feb2002/eye.htm#2)
  device is used in place of a modem. It is no longer manufactured by Ugotcall
  but you can sometimes find it on eBay.

> The ncidd server must be configured to use it.  The server normally
  assumes a modem is going to be used so it must be configured to use
  a serial NetCallerID device that does not use AT commands.

> Uncomment these lines in **ncidd.conf** (this assumes the device is connected
  to serial port 0):

>>      # set ttyport = /dev/ttyS0               # Linux Serial Port 0**
>>      # set ttyspeed = 4800 # NetCallerID port speed**
>>      # set nomodem = 1


> Here are the specifications of the NetCallerID device:

>> ttyport:

>>>      4800 8N1

>> Output Format:

>>>      ###DATE08082225...NMBR14075551212...NAMEJOHN+++\r
>>>      ###DATE...NMBR...NAME   -MSG OFF-+++\r

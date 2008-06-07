Summary:    Network Caller ID server, client, and gateways
Name:       ncid
Version:    0.71
Release:    1%{dist}
Group:      System Environment/Daemons
License:    GPL
Url:        http://ncid.sourceforge.net
Source:     %{name}-%{version}-src.tar.gz
BuildRoot:  %{_tmppath}/%{name}-root
Prereq:     /sbin/chkconfig
Requires:   tcl tk libpcap perl kdebase
Buildrequires: libpcap-devel %{_includedir}/pcap.h

# Don't build an extra package of debuginfo: we are not going to use it.
%define debug_package %{nil}

%description
NCID is Caller ID (CID) distributed over a network to a variety of
devices and computers.

NCID supports messages.  Clients can send a one line message to all
connected clients.

The server, ncidd, monitors either a modem, device or gateway for the CID
data.  The data is collected and sent, via TCP, to one or more clients.
The server supports multiple gateways which can be used with or without
a modem or device.

The client, ncid, receives the Caller ID (CID) message and displays it
in a GUI or terminal window. The client also comes with output modules.
One module can speak the CID, another can send the CID to a pager or cell
phone.  There are other output modules including ones that display the
CID on a TiVo or MythTV.

The client, ncid, normally displays the Caller ID data and the Server
Caller-ID log in a GUI window. The client output can be changed with
output modules. One module can speak the CID, another can send the CID
to a pager or cell phone.  There are other output modules, including
ones that display the CID on a TiVo or MythTV.

The SIP gateways obtain the Caller ID information from a VOIP system,
using SIP Invite.

The YAC gateway obtains the Caller ID information from a YAC server.

%prep

%setup -n %{name}

%build
make fedora mandir

%install
rm -rf ${RPM_BUILD_ROOT}
make install install-fedora prefix=${RPM_BUILD_ROOT}/usr prefix2=${RPM_BUILD_ROOT} prefix3=${RPM_BUILD_ROOT}
rm -f ${RPM_BUILD_ROOT}/var/log/*.log

%clean
rm -rf $RPM_BUILD_ROOT
rm -fr $RPM_BUILD_DIR/%{name}

%files
%defattr(-,root,root)
/usr/bin/ncid
/usr/bin/cidcall
/usr/bin/cidalias
/usr/bin/cidupdate
/usr/bin/yac2ncid
/usr/sbin/ncidd
/usr/sbin/ncidsip
/usr/sbin/sip2ncid
/usr/share/ncid/ncidrotate
/usr/share/ncid/ncid-mythtv
/usr/share/ncid/ncid-page
/usr/share/ncid/ncid-popup
/usr/share/ncid/ncid-samba
/usr/share/ncid/ncid-speak
/usr/share/ncid/ncid-skel
/usr/share/ncid/ncid-tivo
/usr/share/ncid/ncid-yac
%config /etc/ncid/ncid.conf
%config /etc/ncid/ncidd.conf
%config /etc/ncid/ncidd.alias
%config /etc/ncid/ncidrotate.conf
%config /etc/ncid/ncidmodules.conf
%config /etc/ncid/ncidsip.conf
%config /etc/ncid/sip2ncid.conf
%config /etc/ncid/yac2ncid.conf
/etc/rc.d/init.d/ncidd
/etc/rc.d/init.d/ncidsip
/etc/rc.d/init.d/sip2ncid
/etc/rc.d/init.d/yac2ncid
/etc/rc.d/init.d/ncid-mythtv
/etc/rc.d/init.d/ncid-page
/etc/rc.d/init.d/ncid-popup
/etc/rc.d/init.d/ncid-samba
/etc/rc.d/init.d/ncid-speak
/etc/rc.d/init.d/ncid-yac
/etc/logrotate.d/ncidd
%{_mandir}/man1/ncid.1*
%{_mandir}/man1/ncidmodules.1*
%{_mandir}/man1/ncidrotate.1*
%{_mandir}/man1/ncidtools.1*
%{_mandir}/man1/yac2ncid.1*
%{_mandir}/man5/ncidd.conf.5*
%{_mandir}/man5/sip2ncid.conf.5*
%{_mandir}/man5/yac2ncid.conf.5*
%{_mandir}/man5/ncidd.alias.5*
%{_mandir}/man5/ncid.conf.5*
%{_mandir}/man5/ncidmodules.conf.5*
%{_mandir}/man8/ncidd.8*
%{_mandir}/man8/ncidsip.8*
%{_mandir}/man8/sip2ncid.8*
%doc README VERSION doc
%doc cidgate/README.Gateways Fedora/README.Fedora  modules/README.modules
%doc scripts/README.logfile tools/README.tools
%doc man/*.html

%post
touch /var/log/cidcall.log
chmod 644 /var/log/cidcall.log
if [ $1 = 1 ]; then
    /sbin/chkconfig --add ncidd
fi

%preun
if [ $1 = 0 ] ; then
  ### remove package ###
  # stop services
  /sbin/service ncid stop >/dev/null 2>&1 || true
  /sbin/service ncid-mythtv stop >/dev/null 2>&1 || true
  /sbin/service ncid-page stop >/dev/null 2>&1 || true
  /sbin/service ncid-popup stop >/dev/null 2>&1 || true
  /sbin/service ncid-samba stop >/dev/null 2>&1 || true
  /sbin/service ncid-speak stop >/dev/null 2>&1 || true
  /sbin/service ncid-yac stop >/dev/null 2>&1 || true
  /sbin/service ncidsip stop >/dev/null 2>&1 || true
  /sbin/service sip2ncid stop >/dev/null 2>&1 || true
  /sbin/service yac2ncid stop >/dev/null 2>&1 || true
  /sbin/service ncidd stop >/dev/null 2>&1 || true
  # remove autostart
  /sbin/chkconfig ncid && /sbin/chkconfig --del ncid || true
  /sbin/chkconfig ncid-mythtv && /sbin/chkconfig --del ncid-mythtv || true
  /sbin/chkconfig ncid-page && /sbin/chkconfig --del ncid-page || true
  /sbin/chkconfig ncid-popup && /sbin/chkconfig --del ncid-popup || true
  /sbin/chkconfig ncid-samba && /sbin/chkconfig --del ncid-samba || true
  /sbin/chkconfig ncid-speak && /sbin/chkconfig --del ncid-speak || true
  /sbin/chkconfig ncid-yac && /sbin/chkconfig --del ncid-yac || true
  /sbin/chkconfig ncidsip && /sbin/chkconfig --del ncidsip || true
  /sbin/chkconfig sip2ncid && /sbin/chkconfig --del sip2ncid || true
  /sbin/chkconfig yac2ncid && /sbin/chkconfig --del yac2ncid || true
  /sbin/chkconfig  ncidd && /sbin/chkconfig --del ncidd || true
fi
if [ "$1" -ge "1" ]; then
  ### upgrade package ###
  /sbin/service ncid stop >/dev/null 2>&1 || true
  /sbin/chkconfig ncid && /sbin/chkconfig --del ncid || true
fi

%postun
if [ "$1" -ge "1" ]; then
  ### upgrade package ###
  # restart services that are running
  /sbin/service ncidd condrestart >/dev/null 2>&1 || true
  /sbin/service ncidsip condrestart >/dev/null 2>&1 || true
  /sbin/service sip2ncid condrestart >/dev/null 2>&1 || true
  /sbin/service yac2ncid condrestart >/dev/null 2>&1 || true
  /sbin/service ncid-mythtv condrestart >/dev/null 2>&1 || true
  /sbin/service ncid-page condrestart >/dev/null 2>&1 || true
  /sbin/service ncid-popup condrestart >/dev/null 2>&1 || true
  /sbin/service ncid-samba condrestart >/dev/null 2>&1 || true
  /sbin/service ncid-speak condrestart >/dev/null 2>&1 || true
  /sbin/service ncid-yac condrestart >/dev/null 2>&1 || true
fi

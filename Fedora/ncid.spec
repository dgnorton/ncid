Summary:    Network Caller ID server, client, and gateways
Name:       ncid
Version:    0.69
Release:    2
Group:      System Environment/Daemons
License:    GPL
Url:        http://ncid.sourceforge.net
Source:     %{name}-%{version}.tar.gz
BuildRoot:  %{_tmppath}/%{name}-root
Prereq:     /sbin/chkconfig
Requires:   tcl tk libpcap libpcap-devel
Buildrequires: %{_includedir}/pcap.h

# Don't build an extra package of debuginfo: we are not going to use it.
%define debug_package %{nil}

%description
NCID is a TCP client/server program for distributing Caller ID information.

The server, ncidd, either listens to a modem, device, or gateway, for
the Caller-ID data.  The data is formatted and sent, via a TCP socket,
to mutiple clients.

The client, ncid, displays the Caller ID data and the Server Caller-ID
log.  It supports plugin output modules that process the CID received.

The NCID gateways get Caller ID information from from the network, either
from SIP Invite, or YAC.

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
/usr/share/ncid/README
/usr/share/ncid/ncidrotate
/usr/share/ncid/ncid-mythtv
/usr/share/ncid/ncid-page
/usr/share/ncid/ncid-samba
/usr/share/ncid/ncid-speak
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
/etc/rc.d/init.d/ncid
/etc/rc.d/init.d/ncidsip
/etc/rc.d/init.d/sip2ncid
/etc/rc.d/init.d/yac2ncid
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
%doc README VERSION
%doc doc man/*.html scripts/README

%post
touch /var/log/cidcall.log
chmod 644 /var/log/cidcall.log
if [ $1 = 1 ]; then
    /sbin/chkconfig --add ncidd
fi

%preun
if [ $1 = 0 ] ; then
    /sbin/service ncid stop >/dev/null 2>&1 || true
    /sbin/service ncidsip stop >/dev/null 2>&1 || true
    /sbin/service sip2ncid stop >/dev/null 2>&1 || true
    /sbin/service yac2ncid stop >/dev/null 2>&1 || true
    /sbin/service ncidd stop >/dev/null 2>&1 || true
    /sbin/chkconfig --del ncid
    /sbin/chkconfig --del ncidsip
    /sbin/chkconfig --del sip2ncid
    /sbin/chkconfig --del yac2ncid
    /sbin/chkconfig --del ncidd
fi
if [ "$1" -ge "1" ]; then
  [ /sbin/chkconfig ncidd ] && /sbin/chkconfig --del ncidd; touch /tmp/r1
  [ /sbin/chkconfig ncid ] && /sbin/chkconfig --del ncid; touch /tmp/r2
  [ /sbin/chkconfig ncidsip ] && /sbin/chkconfig --del ncidsip; touch /tmp/r3
  [ /sbin/chkconfig sip2ncid ] && /sbin/chkconfig --del sip2ncid; touch /tmp/r4
  [ /sbin/chkconfig yac2ncid ] && /sbin/chkconfig --del yac2ncid; touch /tmp/r5
fi

%postun
if [ "$1" -ge "1" ]; then
    /etc/rc.d/init.d/ncidd condrestart >/dev/null 2>&1 || true
    /etc/rc.d/init.d/ncidsip condrestart >/dev/null 2>&1 || true
    /etc/rc.d/init.d/ncid condrestart >/dev/null 2>&1 || true
    /etc/rc.d/init.d/sip2ncid condrestart >/dev/null 2>&1 || true
    /etc/rc.d/init.d/yac2ncid condrestart >/dev/null 2>&1 || true
    [ -f /tmp/r1 ] && /sbin/chkconfig --add ncidd; rm -f /tmp/r1
    [ -f /tmp/r2 ] && /sbin/chkconfig --add ncid; rm -f /tmp/r2
    [ -f /tmp/r3 ] && /sbin/chkconfig --add ncidsip; rm -f /tmp/r3
    [ -f /tmp/r4 ] && /sbin/chkconfig --add sip2ncid; rm -f /tmp/r4
    [ -f /tmp/r5 ] && /sbin/chkconfig --add yac2ncid; rm -f /tmp/r5
fi

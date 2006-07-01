Summary:    Network Caller ID server and clients
Name:       ncid
Version:    0.65
Release:    1
Group:      System Environment/Daemons
License:    GPL
Url:        http://ncid.sourceforge.net
Source:     %{name}-%{version}.tar.gz
BuildRoot:  %{_tmppath}/%{name}-root
Prereq:     /sbin/chkconfig
Requires:   tcl tk

# Don't build an extra package of debuginfo: we are not going to use it.
%define debug_package %{nil}

%description
NCID is a TCP client/server program for distributing Caller ID
information.

The server, ncidd, listens on a modem line for the Caller-ID data,
formats it, and sends it via a TCP socket to mutiple clients.

The ncid client, displays the Caller ID data and the Server Caller-ID
log.  It can also output the CID data to an external program.

The ncidsip client gets the Caller ID information from SIP Invite,
and send a formatted CID message to the server.

%prep

%setup -n %{name}

%build
make package mandir

%install
rm -rf ${RPM_BUILD_ROOT}
make install prefix=${RPM_BUILD_ROOT}/usr prefix2=${RPM_BUILD_ROOT} LOG=${RPM_BUILD_ROOT}/var/log MAN=${RPM_BUILD_ROOT}/usr/share/man
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
/usr/sbin/ncidd
/usr/sbin/ncidsip
/usr/share/ncid/README
/usr/share/ncid/ncidrotate
/usr/share/ncid/ncid-mythtv
/usr/share/ncid/ncid-page
/usr/share/ncid/ncid-samba
/usr/share/ncid/ncid-speak
%config /etc/ncid/ncid.conf
%config /etc/ncid/ncidd.conf
%config /etc/ncid/ncidd.alias
%config /etc/ncid/ncidrotate.conf
%config /etc/ncid/ncidscript.conf
%config /etc/ncid/ncidsip.conf
/etc/rc.d/init.d/ncidd
/etc/rc.d/init.d/ncid
/etc/rc.d/init.d/ncidsip
/etc/logrotate.d/ncidd
%{_mandir}/man1/ncid.1*
%{_mandir}/man1/ncidscripts.1*
%{_mandir}/man1/ncidtools.1*
%{_mandir}/man5/ncidd.conf.5*
%{_mandir}/man5/ncidd.alias.5*
%{_mandir}/man5/ncid.conf.5*
%{_mandir}/man5/ncidscript.conf.5*
%{_mandir}/man8/ncidd.8*
%{_mandir}/man8/ncidsip.8*
%doc README VERSION
%doc doc man/*.html scripts/README screenshots test

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
    /sbin/service ncidd stop >/dev/null 2>&1 || true
    /sbin/chkconfig --del ncid
    /sbin/chkconfig --del ncidsip
    /sbin/chkconfig --del ncidd
fi

%postun
if [ "$1" -ge "1" ]; then
    /etc/rc.d/init.d/ncidd condrestart >/dev/null 2>&1 || true
    /etc/rc.d/init.d/ncidsip condrestart >/dev/null 2>&1 || true
    /etc/rc.d/init.d/ncid condrestart >/dev/null 2>&1 || true
fi

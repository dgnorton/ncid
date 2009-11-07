Name:       ncid
Version:    0.75
Release:    1%{?dist}
Summary:    Network Caller ID server, client, and gateways

Group:      Applications/Communications
License:    GPLv2+
Url:        http://ncid.sourceforge.net
Source0:    http://downloads.sourceforge.net/%{name}/%{name}-%{version}-src.tar.gz
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires: libpcap-devel

%description
NCID is Caller ID (CID) distributed over a network to a variety of
devices and computers.  NCID includes a server, gateways, a client,
and client output modules.

The NCID server obtains the Caller ID information from a serial device,
like a modem, and from VOIP and YAC gateways.

This package contains the server and gateways.  The client is in the
ncid-client package.

%package client
Summary:    NCID (Network Caller ID) client
Group:      Applications/Communications
BuildArch:  noarch
Requires:   tcl, tk, mailx, minicom

%description client
The ncid-client obtains the Caller ID from the ncid-server and normally
displays it in a GUI window.  It can also display the Called ID in a
terminal window or, using a output module, format the output and send it
to another program.

This package contains the NCID client with the hangup, page, yac, and
skel output modules.

%package mythtv
Summary:    NCID mythtv module sends caller ID information MythTV
Group:      Applications/Communications
BuildArch:  noarch
Requires:   %{name}-client = %{version}-%{release}, mythtv-frontend

%description mythtv
The NCID MythTV module displays caller ID information using mythtvosd

%package kpopup
Summary:    NCID kpopup module displays caller ID info in a KDE window
Group:      Applications/Communications
BuildArch:  noarch
Requires:   %{name}-client = %{version}-%{release}
Requires:   %{name}-speak = %{version}-%{release}
Requires:   kdelibs, kdebase, kdemultimedia, festival
Requires:   kdebase, kdemultimedia, festival, /usr/bin/dcop

%description kpopup
The NCID kpopup module displays caller ID information in a KDE popup window
and optionally speaks the number via voice synthesis.

%package samba
Summary:    NCID samba module sends caller ID information to windows machines
Group:      Applications/Communications
BuildArch:  noarch
Requires:   %{name}-client = %{version}-%{release}, samba-client

%description samba
The NCID samba module sends caller ID information to a windows machine
as a popup.  This will not work if the messenger service is disabled.

%package speak
Summary:    NCID speak module speaks caller ID information via voice synthesis
Group:      Applications/Communications
BuildArch:  noarch
Requires:   %{name}-client = %{version}-%{release}, festival

%description speak
The NCID speak module announces Caller Id information verbally, using
the Festival text-to-speech voice synthesis system.

%prep

%setup -q -n %{name}

%build
make %{?_smp_mflags} EXTRA_CFLAGS="$RPM_OPT_FLAGS" \
     STRIP= prefix=/usr prefix2= local fedoradir

%install
rm -rf ${RPM_BUILD_ROOT}
make install install-fedora prefix=${RPM_BUILD_ROOT}/%{_prefix} \
                            prefix2=${RPM_BUILD_ROOT} \
                            prefix3=${RPM_BUILD_ROOT}

%clean
rm -rf $RPM_BUILD_ROOT
rm -fr $RPM_BUILD_DIR/%{name}

%files
%defattr(-,root,root)
%doc README VERSION doc
%doc cidgate/README.Gateways Fedora/README.Fedora
%doc scripts/README.logfile tools/README.tools
/usr/bin/cidcall
/usr/bin/cidalias
/usr/bin/cidupdate
/usr/bin/yac2ncid
/usr/sbin/ncidd
/usr/sbin/ncidsip
/usr/sbin/sip2ncid
%dir /usr/share/ncid
/usr/share/ncid/ncidrotate
%dir /etc/ncid
%config(noreplace) /etc/ncid/ncidd.conf
%config(noreplace) /etc/ncid/ncidd.alias
%config(noreplace) /etc/ncid/ncidrotate.conf
%config(noreplace) /etc/ncid/ncidsip.conf
%config(noreplace) /etc/ncid/sip2ncid.conf
%config(noreplace) /etc/ncid/yac2ncid.conf
%config(noreplace) /etc/logrotate.d/ncid
%_initrddir/ncidd
%_initrddir/ncidsip
%_initrddir/sip2ncid
%_initrddir/yac2ncid
%{_mandir}/man1/ncidrotate.1*
%{_mandir}/man1/ncidtools.1*
%{_mandir}/man1/yac2ncid.1*
%{_mandir}/man5/ncidd.conf.5*
%{_mandir}/man5/sip2ncid.conf.5*
%{_mandir}/man5/yac2ncid.conf.5*
%{_mandir}/man5/ncidd.alias.5*
%{_mandir}/man5/ncidrotate.conf.5*
%{_mandir}/man5/ncidsip.conf.5*
%{_mandir}/man8/ncidd.8*
%{_mandir}/man8/ncidsip.8*
%{_mandir}/man8/sip2ncid.8*

%files client
%defattr(-,root,root)
%doc modules/README.modules
/usr/bin/ncid
%dir /usr/share/ncid
/usr/share/ncid/ncid-hangup
/usr/share/ncid/ncid-page
/usr/share/ncid/ncid-skel
/usr/share/ncid/ncid-tivo
/usr/share/ncid/ncid-yac
/usr/share/pixmaps/ncid.gif
%dir /etc/ncid
%config(noreplace) /etc/ncid/ncid.conf
%config(noreplace) /etc/ncid/ncidmodules.conf
%_initrddir/ncid-hangup
%_initrddir/ncid-page
%_initrddir/ncid-yac
%{_mandir}/man1/ncid.1*
%{_mandir}/man1/ncidmodules.1*
%{_mandir}/man5/ncid.conf.5*
%{_mandir}/man5/ncidmodules.conf.5*

%files mythtv
%defattr(-,root,root)
%doc modules/README.modules
/usr/share/ncid/ncid-mythtv
%_initrddir/ncid-mythtv

%files kpopup
%defattr(-,root,root)
%doc modules/README.modules
/usr/share/ncid/ncid-kpopup
%_initrddir/ncid-kpopup

%files samba
%defattr(-,root,root)
%doc modules/README.modules
/usr/share/ncid/ncid-samba
%_initrddir/ncid-samba

%files speak
%defattr(-,root,root)
%doc modules/README.modules
/usr/share/ncid/ncid-speak
%_initrddir/ncid-speak

%post
# make services known
for SCRIPT in ncidd ncidsip ncidsip
do
    /sbin/chkconfig --add $SCRIPT
done

%post client
# make services known
for SCRIPT in ncid-page ncid-yac
do
    /sbin/chkconfig --add $SCRIPT
done

%post mythtv
/sbin/chkconfig --add ncid-mythtv

%post kpopup
/sbin/chkconfig --add ncid-kpopup

%post samba
/sbin/chkconfig --add ncid-samba

%post speak
/sbin/chkconfig --add ncid-speak

%preun
if [ $1 = 0 ] ; then ### Uninstall package ###
    # stop services and remove autostart
    for SCRIPT in ncidd ncidsip ncidsip
    do
        /sbin/service $SCRIPT stop > /dev/null 2>&1 || :
        /sbin/chkconfig --del $SCRIPT
    done
fi

%preun client
if [ $1 = 0 ] ; then ### Uninstall package ###
    # stop services and remove autostart
    for SCRIPT in ncid-page ncid-yac
    do
        /sbin/service $SCRIPT stop > /dev/null 2>&1 || :
        /sbin/chkconfig --del $SCRIPT
    done
fi

# just in case an old package that had the obsolute ncid service is upgraded
if [ "$1" -ge "1" ]; then ### upgrade package ###
    /sbin/service ncid stop >/dev/null 2>&1 || true
    /sbin/chkconfig ncid && /sbin/chkconfig --del ncid || true
fi

%preun mythtv
if [ $1 = 0 ] ; then ### Uninstall package ###
    # stop services and remove autostart
    /sbin/service ncid-mythtv stop > /dev/null 2>&1 || :
    /sbin/chkconfig --del ncid-mythtv
fi

%preun kpopup
if [ $1 = 0 ] ; then ### Uninstall package ###
    # stop services and remove autostart
    /sbin/service ncid-kpopup stop > /dev/null 2>&1 || :
    /sbin/chkconfig --del ncid-kpopup
fi

%preun samba
if [ $1 = 0 ] ; then ### Uninstall package ###
    # stop services and remove autostart
    /sbin/service ncid-samba stop > /dev/null 2>&1 || :
    /sbin/chkconfig --del ncid-samba
fi

%preun speak
if [ $1 = 0 ] ; then ### Uninstall package ###
    # stop services and remove autostart
    /sbin/service ncid-speak stop > /dev/null 2>&1 || :
    /sbin/chkconfig --del ncid-speak
fi

%postun
if [ "$1" -ge "1" ]; then ### upgrade package ###
    # restart services that are running
    for SCRIPT in ncidd ncidsip ncidsip
    do
        /sbin/service $SCRIPT condrestart >/dev/null 2>&1 || :
    done
fi

%postun client
if [ "$1" -ge "1" ]; then ### upgrade package ###
    # restart services that are running
    for SCRIPT in /usr/share/ncid/ncid-*
    do
        /sbin/service `basename $SCRIPT` condrestart >/dev/null 2>&1 || :
    done
fi

%postun mythtv
if [ "$1" -ge "1" ]; then ### upgrade package ###
    # restart services if running
    /sbin/service ncid-mythtv condrestart >/dev/null 2>&1 || :
fi

%postun kpopup
if [ "$1" -ge "1" ]; then ### upgrade package ###
    # restart services if running
    /sbin/service ncid-kpopup condrestart >/dev/null 2>&1 || :
fi

%postun samba
if [ "$1" -ge "1" ]; then ### upgrade package ###
    # restart services if running
    /sbin/service ncid-samba condrestart >/dev/null 2>&1 || :
fi

%postun speak
if [ "$1" -ge "1" ]; then ### upgrade package ###
    # restart service if running
    /sbin/service ncid-speak condrestart >/dev/null 2>&1 || :
fi

%changelog
* Mon Oct 19 2009 John Chmielewski <jlc@users.sourceforge.net> 0.75-1
- New release
- client package changed from i386 to noarch

* Fri Jun 19 2009 John Chmielewski <jlc@users.sourceforge.net> 0.74-1
- New release

* Sun Mar 29 2009 Eric Sandeen <sandeen@redhat.com> 0.73-2
- First Fedora build.

* Thu Mar 12 2009 John Chmielewski <jlc@users.sourceforge.net> 0.73-1
- Initial build.
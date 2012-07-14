Name:       ncid
Version:    0.84
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
Requires:   tcl, tk, mailx, nc

%description client
The NCID client obtains the Caller ID from the NCID server and normally
displays it in a GUI window.  It can also display the Called ID in a
terminal window or, using a output module, format the output and send it
to another program.

This package contains the NCID client with initmodem, hangup, page,
skel, and yac output modules.

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
and optionally speaks the number via voice synthesis.  The KDE or Gnome
desktop must be running.

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
%doc scripts/README.scripts tools/README.tools
%{_bindir}/cidcall
%{_bindir}/cidalias
%{_bindir}/cidupdate
%{_bindir}/ncid2ncid
%{_bindir}/yac2ncid
%{_sbindir}/ncidd
%{_sbindir}/ncidsip
%{_sbindir}/sip2ncid
%dir %{_datadir}/ncid
%{_datadir}/ncid/ncidrotate
%dir /etc/ncid
%config(noreplace) /etc/ncid/ncidd.blacklist
%config(noreplace) /etc/ncid/ncidd.conf
%config(noreplace) /etc/ncid/ncidd.alias
%config(noreplace) /etc/ncid/ncidrotate.conf
%config(noreplace) /etc/ncid/ncidsip.conf
%config(noreplace) /etc/ncid/ncid2ncid.conf
%config(noreplace) /etc/ncid/sip2ncid.conf
%config(noreplace) /etc/ncid/yac2ncid.conf
%config(noreplace) /etc/logrotate.d/ncid
/usr/lib/systemd/system/ncidd.service
/usr/lib/systemd/system/ncidsip.service
/usr/lib/systemd/system/ncid2ncid.service
/usr/lib/systemd/system/sip2ncid.service
/usr/lib/systemd/system/yac2ncid.service
%{_mandir}/man1/ncidrotate.1*
%{_mandir}/man1/ncidtools.1*
%{_mandir}/man1/cidalias.1*
%{_mandir}/man1/cidcall.1*
%{_mandir}/man1/cidupdate.1*
%{_mandir}/man1/ncid2ncid.1*
%{_mandir}/man1/yac2ncid.1*
%{_mandir}/man5/ncidd.blacklist.5*
%{_mandir}/man5/ncidd.conf.5*
%{_mandir}/man5/ncid2ncid.conf.5*
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
%doc README VERSION modules/README.modules
%{_bindir}/ncid
%dir %{_datadir}/ncid
%{_datadir}/ncid/ncid-initmodem
%{_datadir}/ncid/ncid-page
%{_datadir}/ncid/ncid-skel
%{_datadir}/ncid/ncid-yac
%{_datadir}/pixmaps/ncid/ncid.gif
%dir /etc/ncid
%config(noreplace) /etc/ncid/ncid.conf
%config(noreplace) /etc/ncid/ncidmodules.conf
/usr/lib/systemd/system/ncid-initmodem.service
/usr/lib/systemd/system/ncid-page.service
/usr/lib/systemd/system/ncid-yac.service
%{_mandir}/man1/ncid.1*
%{_mandir}/man1/ncidmodules.1*
%{_mandir}/man1/ncid-initmodem.1*
%{_mandir}/man1/ncid-page.1*
%{_mandir}/man1/ncid-skel.1*
%{_mandir}/man1/ncid-yac.1*
%{_mandir}/man5/ncid.conf.5*
%{_mandir}/man5/ncidmodules.conf.5*

%files mythtv
%defattr(-,root,root)
%doc VERSION modules/README.modules
%{_datadir}/ncid/ncid-mythtv
/usr/lib/systemd/system/ncid-mythtv.service
%{_mandir}/man1/ncid-mythtv.1*

%files kpopup
%defattr(-,root,root)
%doc VERSION modules/README.modules
%{_datadir}/ncid/ncid-kpopup
%{_mandir}/man1/ncid-kpopup.1*

%files samba
%defattr(-,root,root)
%doc VERSION modules/README.modules
%{_datadir}/ncid/ncid-samba
/usr/lib/systemd/system/ncid-samba.service
%{_mandir}/man1/ncid-samba.1*

%files speak
%defattr(-,root,root)
%doc VERSION modules/README.modules
%{_datadir}/ncid/ncid-speak
/usr/lib/systemd/system/ncid-speak.service
%{_mandir}/man1/ncid-speak.1*

%post
# reload systemd manager configuration
/bin/systemctl --system daemon-reload

%post client
# reload systemd manager configuration
/bin/systemctl --system daemon-reload

%post mythtv
# reload systemd manager configuration
/bin/systemctl --system daemon-reload

%post samba
# reload systemd manager configuration
/bin/systemctl --system daemon-reload

%post speak
# reload systemd manager configuration
/bin/systemctl --system daemon-reload


%preun
if [ $1 = 0 ] ; then ### Uninstall package ###
    # stop server and gateway services and remove autostart
    for SCRIPT in ncidd ncidsip sip2ncid yac2ncid ncid2ncid
    do
        /bin/systemctl stop $SCRIPT.service
        /bin/systemctl --quiet disable $SCRIPT.service
    done
fi

%preun client
if [ $1 = 0 ] ; then ### Uninstall package ###
    # stop services and remove autostart
    for SCRIPT in ncid-initmodem ncid-page ncid-yac
    do
        /bin/systemctl stop $SCRIPT.service
        /bin/systemctl --quiet disable $SCRIPT.service
    done
fi

%preun mythtv
if [ $1 = 0 ] ; then ### Uninstall package ###
    # stop service and remove autostart
    /bin/systemctl stop ncid-mythtv.service
    /bin/systemctl --quiet disable ncid-mythtv.service
fi

%preun samba
if [ $1 = 0 ] ; then ### Uninstall package ###
    # stop service and remove autostart
    /bin/systemctl stop ncid-samba.service
    /bin/systemctl --quiet disable ncid-samba.service
fi

%preun speak
if [ $1 = 0 ] ; then ### Uninstall package ###
    # stop service and remove autostart
    /bin/systemctl stop ncid-speak.service
    /bin/systemctl --quiet disable ncid-speak.service
fi

%postun
if [ "$1" -ge "1" ]; then ### upgrade package ###
    # restart server and gateway services that are running
    for SCRIPT in ncidd ncidsip sip2ncid yac2ncid ncid2ncid
    do
        /bin/systemctl try-restart $SCRIPT.service
    done
fi

%postun client
if [ "$1" -ge "1" ]; then ### upgrade package ###
    # restart services that are running
    # a service could have been installed by another package
    for SCRIPT in /usr/share/ncid/ncid-*
    do
        /bin/systemctl try-restart `basename $SCRIPT`.service
    done
fi

%postun mythtv
if [ "$1" -ge "1" ]; then ### upgrade package ###
    # restart service if running
    /bin/systemctl try-restart ncid-mythtv.service
fi

%postun samba
if [ "$1" -ge "1" ]; then ### upgrade package ###
    # restart service if running
    /bin/systemctl try-restart ncid-samba.service
fi

%postun speak
if [ "$1" -ge "1" ]; then ### upgrade package ###
    # restart service if running
    /bin/systemctl try-restart ncid-speak.service
fi

%changelog

* Mon Jul 2 2012 John Chmielewski <jlc@users.sourceforge.net> 0.84
- Changed from using service & init scripts to systemctl & service scripts

* Fri Sep 2 2011 John Chmielewski <jlc@users.sourceforge.net> 0.83
- removed /usr/share/ncid/ncid-tivo
- removed ncid-tivo.1

* Tue Mar 17 2011 John Chmielewski <jlc@users.sourceforge.net> 0.82-1
- New release

* Sat Feb 26 2011 John Chmielewski <jlc@users.sourceforge.net> 0.81-1
- removed: /usr/share/ncid/ncid-hangup
- removed: %_initrddir/ncid-hangup
- removed: /etc/ncid/ncid.minicom
- added:   %{_mandir}/man5/ncidd.blacklist.5*
- removed line: %config(noreplace) /etc/ncid/ncid.blacklist
- added line: %config(noreplace) /etc/ncid/ncidd.blacklist
- added man pages: cidalias.1 cidcall.1 cidupdate.1 ncid-initmodem.1
- added man pages ncid-kpopup.1 ncid-page.1 ncid-samba.1 ncid-speak.1
- added man pages: ncid-mythtv.1 ncid-skel.1 ncid-tivo.1 ncid-yac.1

* Sun Oct 10 2010 John Chmielewski <jlc@users.sourceforge.net> 0.80-1
- New release

* Thu Aug 26 2010 John Chmielewski <jlc@users.sourceforge.net> 0.79-1
- added line: /usr/bin/ncid2ncid
- added line: %config(noreplace) /etc/ncid/ncid2ncid.conf
- added line: %_initrddir/ncid2ncid
- added line: %{_mandir}/man1/ncid2ncid.1*
- added line: %{_mandir}/man5/ncid2ncid.conf.5*

* Fri May 14 2010 John Chmielewski <jlc@users.sourceforge.net> 0.78-1
- New release

* Fri Apr 9 2010 John Chmielewski <jlc@users.sourceforge.net> 0.77-1
- removed line: %_initrddir/ncid-kpopup
- removed section: %post kpopup
- removed section: %preun kpopup
- removed section: %postun kpopup
- added line: %_initrddir/ncid-initmodem
- added line: /usr/share/ncid/ncid-initmodem
- added line: /etc/ncid/ncid.minicom
- added line: %config(noreplace) /etc/ncid/ncid.blacklist in client section
- added ncid-initmodem and ncid-hangup to SCRIPT lines in client sections
- added more comments

* Mon Dec 28 2009 John Chmielewski <jlc@users.sourceforge.net> 0.76-1
- changed /usr/share/pixmaps/ncid.gif to /usr/share/pixmaps/ncid/ncid.gif

* Mon Oct 19 2009 John Chmielewski <jlc@users.sourceforge.net> 0.75-1
- client package changed from i386 to noarch
- added line: %_initrddir/ncid-hangup
- added line: /usr/share/ncid/ncid-hangup

* Fri Jun 19 2009 John Chmielewski <jlc@users.sourceforge.net> 0.74-1
- New release

* Sun Mar 29 2009 Eric Sandeen <sandeen@redhat.com> 0.73-2
- First Fedora build.

* Thu Mar 12 2009 John Chmielewski <jlc@users.sourceforge.net> 0.73-1
- Initial build.

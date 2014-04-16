Name:       ncid
Version:    0.89
Release:    1%{?dist}
Summary:    Network Caller ID server, client, and gateways

Group:      Applications/Communications
License:    GPLv2+
Url:        http://ncid.sourceforge.net
Source0:    http://sourceforge.net/projects/ncid/files/ncid/%{version}/%{name}-%{version}-src.tar.gz
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires: libpcap-devel man2html

%global _hardened_build 1

%description
NCID is Caller ID (CID) distributed over a network to a variety of
devices and computers.  NCID includes a server, gateways, a client,
client output modules, and command line tools.

The NCID server obtains the Caller ID information from a modem,
a serial device, and from gateways for NCID, SIP, WC, & YAC.

This package contains the server, gateways and command line tools.
The client is in the ncid-client package.

%package client
Summary:    NCID (Network Caller ID) client
Group:      Applications/Communications
BuildArch:  noarch
Requires:   tcl, tk, mailx, nc

%description client
The NCID client obtains the Caller ID from the NCID server and normally
displays it in a GUI window.  It can also display the Called ID in a
terminal window or, using an output module, format the output and send it
to another program.

This package contains the NCID client and output modules that are not
separate packages.

%package mythtv
Summary:    NCID mythtv module sends Caller ID information MythTV
Group:      Applications/Communications
BuildArch:  noarch
Requires:   %{name}-client = %{version}-%{release}, mythtv-frontend

%description mythtv
The NCID MythTV module displays Caller ID information using mythtvosd

%package kpopup
Summary:    NCID kpopup module displays Caller ID info in a KDE window
Group:      Applications/Communications
BuildArch:  noarch
Requires:   %{name}-client = %{version}-%{release}
Requires:   %{name}-speak = %{version}-%{release}
Requires:   kde-baseapps, kmix

%description kpopup
The NCID kpopup module displays Caller ID information in a KDE pop-up window
and optionally speaks the number via voice synthesis.  The KDE or Gnome
desktop must be running.

%package samba
Summary:    NCID samba module sends Caller ID information to windows machines
Group:      Applications/Communications
BuildArch:  noarch
Requires:   %{name}-client = %{version}-%{release}, samba-client

%description samba
The NCID samba module sends Caller ID information to a windows machine
as a pop-up.  This will not work if the messenger service is disabled.

%package speak
Summary:    NCID speak module speaks Caller ID information via voice synthesis
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
%doc README VERSION doc/LICENSE doc/Makefile doc/NCID-SDK.odt
%doc doc/NCID_Documentation.md doc/ncid-1.jpg doc/README.docdir
%doc doc/ReleaseNotes.md man/README.mandir Fedora/README.Fedora
%doc server/README.server gateway/README.gateways attic/README.attic
%doc logrotate/README.logrotate tools/README.tools
%{_bindir}/cidcall
%{_bindir}/cidalias
%{_bindir}/cidupdate
%{_bindir}/ncidutil
%{_bindir}/ncid2ncid
%{_bindir}/rn2ncid
%{_bindir}/wc2ncid
%{_bindir}/wct
%{_bindir}/yac2ncid
%{_sbindir}/ncidd
%{_sbindir}/sip2ncid
%dir %{_datadir}/ncid
%{_datadir}/ncid/ncidrotate
%dir /etc/ncid
%config(noreplace) /etc/ncid/ncidd.blacklist
%config(noreplace) /etc/ncid/ncidd.whitelist
%config(noreplace) /etc/ncid/ncidd.conf
%config(noreplace) /etc/ncid/ncidd.alias
%config(noreplace) /etc/ncid/ncidrotate.conf
%config(noreplace) /etc/ncid/ncid2ncid.conf
%config(noreplace) /etc/ncid/rn2ncid.conf
%config(noreplace) /etc/ncid/sip2ncid.conf
%config(noreplace) /etc/ncid/wc2ncid.conf
%config(noreplace) /etc/ncid/yac2ncid.conf
%config(noreplace) /etc/logrotate.d/ncid
%{_usr}/lib/systemd/system/ncidd.service
%{_usr}/lib/systemd/system/ncid2ncid.service
%{_usr}/lib/systemd/system/rn2ncid.service
%{_usr}/lib/systemd/system/sip2ncid.service
%{_usr}/lib/systemd/system/wc2ncid.service
%{_usr}/lib/systemd/system/yac2ncid.service
%{_mandir}/man1/ncidrotate.1*
%{_mandir}/man1/cidalias.1*
%{_mandir}/man1/cidcall.1*
%{_mandir}/man1/cidupdate.1*
%{_mandir}/man1/ncidutil.1*
%{_mandir}/man1/ncid2ncid.1*
%{_mandir}/man1/rn2ncid.1*
%{_mandir}/man1/wc2ncid.1*
%{_mandir}/man1/wct.1*
%{_mandir}/man1/yac2ncid.1*
%{_mandir}/man5/ncidd.blacklist.5*
%{_mandir}/man5/ncidd.whitelist.5*
%{_mandir}/man5/ncidd.conf.5*
%{_mandir}/man5/ncid2ncid.conf.5*
%{_mandir}/man5/rn2ncid.conf.5*
%{_mandir}/man5/sip2ncid.conf.5*
%{_mandir}/man5/wc2ncid.conf.5*
%{_mandir}/man5/yac2ncid.conf.5*
%{_mandir}/man5/ncidd.alias.5*
%{_mandir}/man5/ncidrotate.conf.5*
%{_mandir}/man7/ncidtools.7*
%{_mandir}/man7/ncidgateways.7*
%{_mandir}/man8/ncidd.8*
%{_mandir}/man8/sip2ncid.8*

%files client
%defattr(-,root,root)
%doc README VERSION client/README.client modules/README.modules
%doc doc/README.docdir doc/Makefile doc/Verbose.md
%{_bindir}/ncid
%dir %{_datadir}/ncid
%dir /etc/ncid/conf.d
%{_datadir}/ncid/ncid-alert
%{_datadir}/ncid/ncid-initmodem
%{_datadir}/ncid/ncid-notify
%{_datadir}/ncid/ncid-page
%{_datadir}/ncid/ncid-skel
%{_datadir}/ncid/ncid-wakeup
%{_datadir}/ncid/ncid-yac
%{_datadir}/pixmaps/ncid/ncid.gif
%dir /etc/ncid
%config(noreplace) /etc/ncid/ncid.conf
%config(noreplace) /etc/ncid/conf.d/ncid-alert.conf
%config(noreplace) /etc/ncid/conf.d/ncid-notify.conf
%config(noreplace) /etc/ncid/conf.d/ncid-page.conf
%config(noreplace) /etc/ncid/conf.d/ncid-skel.conf
%config(noreplace) /etc/ncid/conf.d/ncid-yac.conf
%{_usr}/lib/systemd/system/ncid-initmodem.service
%{_usr}/lib/systemd/system/ncid-notify.service
%{_usr}/lib/systemd/system/ncid-page.service
%{_usr}/lib/systemd/system/ncid-yac.service
%{_mandir}/man1/ncid.1*
%{_mandir}/man1/ncid-alert.1*
%{_mandir}/man1/ncid-initmodem.1*
%{_mandir}/man1/ncid-notify.1*
%{_mandir}/man1/ncid-page.1*
%{_mandir}/man1/ncid-skel.1*
%{_mandir}/man1/ncid-wakeup.1*
%{_mandir}/man1/ncid-yac.1*
%{_mandir}/man5/ncid.conf.5*
%{_mandir}/man7/ncid-modules.7*

%files mythtv
%defattr(-,root,root)
%doc VERSION modules/README.modules
%{_datadir}/ncid/ncid-mythtv
%config(noreplace) /etc/ncid/conf.d/ncid-mythtv.conf
%{_usr}/lib/systemd/system/ncid-mythtv.service
%{_mandir}/man1/ncid-mythtv.1*

%files kpopup
%defattr(-,root,root)
%doc VERSION modules/README.modules
%{_datadir}/ncid/ncid-kpopup
%config(noreplace) /etc/ncid/conf.d/ncid-kpopup.conf
%{_mandir}/man1/ncid-kpopup.1*

%files samba
%defattr(-,root,root)
%doc VERSION modules/README.modules
%{_datadir}/ncid/ncid-samba
%config(noreplace) /etc/ncid/conf.d/ncid-samba.conf
%{_usr}/lib/systemd/system/ncid-samba.service
%{_mandir}/man1/ncid-samba.1*

%files speak
%defattr(-,root,root)
%doc VERSION modules/README.modules
%{_datadir}/ncid/ncid-speak
%config(noreplace) /etc/ncid/conf.d/ncid-speak.conf
%{_usr}/lib/systemd/system/ncid-speak.service
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
    for SCRIPT in ncidd sip2ncid yac2ncid ncid2ncid wc2ncid
    do
        /bin/systemctl stop $SCRIPT.service
        /bin/systemctl --quiet disable $SCRIPT.service
    done
fi

%preun client
if [ $1 = 0 ] ; then ### Uninstall package ###
    # stop services and remove autostart
    # a service could have been installed by another package
    for SCRIPT in /usr/share/ncid/ncid-*
    do
        NAME=`basename $SCRIPT`
        if [ -f %{_usr}/lib/systemd/system/$NAME ]; then
            /bin/systemctl stop $NAME.service
            /bin/systemctl --quiet disable $NAME.service
        fi
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
    for SCRIPT in ncidd sip2ncid yac2ncid ncid2ncid wc2ncid
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
        NAME=`basename $SCRIPT`
        if [ -f %{_usr}/lib/systemd/system/$NAME ]; then
            /bin/systemctl try-restart $NAME.service
        fi
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

* Tue Apr 8 2014 John Chmielewski <jlc@users.sourceforge.net> 0.89-1
- new release

* Wed Nov 20 2013 John Chmielewski <jlc@users.sourceforge.net> 0.88-1
- changed documentation files in doc/

* Thu May 23 2013 John Chmielewski <jlc@users.sourceforge.net> 0.87-1
- Updated lincese file and GNU license headers in files
- fixed ncidd to output a CID line if cidcall.log file not present
- modified cidnoname logic to add "NONMAE" when number was optained
- added rn2ncid, rn2ncid.conf, rn2ncid.service
- enabled _hardened_build

* Mon Feb 11 2013 John Chmielewski <jlc@users.sourceforge.net> 0.86-1
- Updated man pages: ncid*
- Updated and fixed client description
- Fixed typo in mythtv package summary
- New gateway: wc2ncid wc2ncid.conf wc2ncid.1 wc2ncid.conf.5 wc2ncid.service
- New output module: ncid-wakeup ncid-wakeup.1
- New output module: ncid-alert ncid-alert.conf ncid-alert.1
- new tool (wct), new man pages: ncidtools.7 ncidgateways.7
- Removed ncidsip and related ncidsip files

* Thu Oct 18 2012 John Chmielewski <jlc@users.sourceforge.net> 0.85-1
- Added ncidd.whitelist ncid-notify ncid-notify.service
- Added ncidd.whitelist.5 ncid-notify.1 ncid-modules.7
- Added Verbose-ncid to client
- Removed ncidmodules.1 and ncidmodules.conf.5 ncidtools.1
- Renamed scripts/ to logname/ and README.scripts to README.logrotate
- Fixed postun client
- Updated doc files

* Mon Jul 2 2012 John Chmielewski <jlc@users.sourceforge.net> 0.84-1
- Changed from using service & init scripts to systemctl & service scripts

* Fri Sep 2 2011 John Chmielewski <jlc@users.sourceforge.net> 0.83-1
- Removed /usr/share/ncid/ncid-tivo
- Removed ncid-tivo.1

* Thu Mar 17 2011 John Chmielewski <jlc@users.sourceforge.net> 0.82-1
- New release

* Sat Feb 26 2011 John Chmielewski <jlc@users.sourceforge.net> 0.81-1
- Removed: /usr/share/ncid/ncid-hangup
- Removed: _initrddir/ncid-hangup
- Removed: /etc/ncid/ncid.minicom
- Added:   _mandir/man5/ncidd.blacklist.5*
- Removed line: config(noreplace) /etc/ncid/ncid.blacklist
- Added line: config(noreplace) /etc/ncid/ncidd.blacklist
- Added man pages: cidalias.1 cidcall.1 cidupdate.1 ncid-initmodem.1
- Added man pages ncid-kpopup.1 ncid-page.1 ncid-samba.1 ncid-speak.1
- Added man pages: ncid-mythtv.1 ncid-skel.1 ncid-tivo.1 ncid-yac.1

* Sun Oct 10 2010 John Chmielewski <jlc@users.sourceforge.net> 0.80-1
- New release

* Thu Aug 26 2010 John Chmielewski <jlc@users.sourceforge.net> 0.79-1
- Added line: /usr/bin/ncid2ncid
- Added line: config(noreplace) /etc/ncid/ncid2ncid.conf
- Added line: _initrddir/ncid2ncid
- Added line: _mandir/man1/ncid2ncid.1*
- Added line: _mandir/man5/ncid2ncid.conf.5*

* Fri May 14 2010 John Chmielewski <jlc@users.sourceforge.net> 0.78-1
- New release

* Fri Apr 9 2010 John Chmielewski <jlc@users.sourceforge.net> 0.77-1
- Removed line: _initrddir/ncid-kpopup
- Removed section: post kpopup
- Removed section: preun kpopup
- Removed section: postun kpopup
- Added line: _initrddir/ncid-initmodem
- Added line: /usr/share/ncid/ncid-initmodem
- Added line: /etc/ncid/ncid.minicom
- Added line: config(noreplace) /etc/ncid/ncid.blacklist in client section
- Added ncid-initmodem and ncid-hangup to SCRIPT lines in client sections
- Added more comments

* Mon Dec 28 2009 John Chmielewski <jlc@users.sourceforge.net> 0.76-1
- Changed /usr/share/pixmaps/ncid.gif to /usr/share/pixmaps/ncid/ncid.gif

* Mon Oct 19 2009 John Chmielewski <jlc@users.sourceforge.net> 0.75-1
- Client package changed from i386 to noarch
- Added line: _initrddir/ncid-hangup
- Added line: /usr/share/ncid/ncid-hangup

* Fri Jun 19 2009 John Chmielewski <jlc@users.sourceforge.net> 0.74-1
- New release

* Sun Mar 29 2009 Eric Sandeen <sandeen@redhat.com> 0.73-2
- First Fedora build.

* Thu Mar 12 2009 John Chmielewski <jlc@users.sourceforge.net> 0.73-1
- Initial build.

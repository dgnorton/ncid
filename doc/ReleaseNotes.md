# Release Notes for NCID 0.89

## Index

* [NCID Distributions](#relnot_dist)
* [Distribution Changes](#relnot_spec)
* [Server Changes](#relnot_server)
* [Gateway Changes](#relnot_gate)
* [Client Changes](#relnot_client)
* [Client Module Changes](#relnot_mod)
* [Tool Changes](#relnot_tool)
* [Documentation Changes](#relnot_doc)

## <a name="relnot_dist">NCID Distributions</a>

> * [sourceforge](#relnot_sf)
> * [Fedora packages](#relnot_fedora)
> * [RPM based OS packages](#relnot_rpm)
> * [Macintosh OS X package](#relnot_osx)
> * [FreeBSD package](#relnot_freebsd)
> * [Ubuntu packages](#relnot_ubuntu)
> * [Debian based OS packages](#relnot_debian)

> ### <a name="relnot_sf">sourceforge</a>

<pre>
    NCID source package:           ncid-0.89-src.tar.gz

    Cygwin 32 bit Windows package: ncid-0.89-cygwin.tgz

    TiVo Series1 package:          ncid-0.89-ppc-tivo.tgz
    TiVo Series 2-3 package:       ncid-0.89-mips-tivo.tgz

    Ubuntu 64 bit package:         ncid_0.89-1_amd64.deb
    Ubuntu no-arch packages:       ncid-client_0.89-1_all.deb
                                   ncid-kpopup_0.89-1_all.deb
                                   ncid-mythtv_0.89-1_all.deb
                                   ncid-samba_0.89-1_all.deb
                                   ncid-speak_0.89-1_all.deb

    Windows client installer:      ncid-0.89-client_setup.exe
</pre

> These may also be distributed:

<pre>
    Fedora 64 bit package:         ncid-0.89-1.fc20.x86_64.rpm
    Fedora no-arch packages:       ncid-client-0.89-1.fc20.noarch.rpm
                                   ncid-kpopup-0.89-1.fc20.noarch.rpm
                                   ncid-mythtv-0.89-1.fc20.noarch.rpm
                                   ncid-samba-0.89-1.fc20.noarch.rpm
                                   ncid-speak-0.89-1.fc20.noarch.rpm

    Macintosh 64 bit OS X package: ncid-0.89-mac-osx.tgz

    FreeBSD 32 bit package:        ncid-0.89-freebsd.tgz

    Debian packages:               Ubuntu packages should install as-is

    Raspberry Pi packages:         ncid_0.89-1_armhf.deb
                                   other packages are the same as Ubuntu
</pre>

> ### <a name="relnot_fedora">Fedora packages</a>

<pre>
    Available at the Fedora repository (sometimes sourceforge).
    New release first appears in the rawhide repository.
    There are server, client, and optional output module packages.
    Normally you only need to install the ncid & ncid-client rpm packages.
    The yum list command will show you the packages available:
        yum list ncid\*
    If the above does not show version 0.89:
        yum --enablerepo=rawhide list ncid\*
    If the rawhide repo is not installed:
        yum install fedora-release-rawhide
    If you need to build packages for your specific OS release:
        rpmbuild -tb ncid-0.89-src.tar.gz
</pre>

> ### <a name="relnot_rpm">RPM based OS packages</a>

> includes Fedora, Redhat, CentOS, etc.

> If a dependency can not be resolved, you should try rebuilding packages:

<pre>
    - Download the latest NCID deb packages from sourceforge:
      ncid RPM Package
      ncid-client RPM Package - client and default output modules
    - Download any optional output modules wanted:
      ncid-MODULE RPM Package  - optional client output modules
    - Install or Upgrade the packages using yum
        * Install the NCID server and gateways:
          sudo yum install ncid-<version>.fc20.x87_64.rpm
        * Install the client package and default modules:
          sudo yum install ncid-client-<version>.fc20.x87_64.rpm
        * Install any optional modules wanted:
          sudo gdebi ncid-<module-<version>.fc20.x87_64.rpm

    Notes:
      <version> would be something like: 0.89-1
      <module> would be a module name like: kpopup, mythtv, samba
</pre>

> ### <a name="relnot_osx">Macintosh OS X package</a>

        Available at MacPorts (sometimes sourceforge).
            http://trac.macports.org/browser/trunk/dports/net/ncid/Portfile

> ### <a name="relnot_freebsd">FreeBSD package</a>

        Available at FreshPorts (sometimes sourceforge).
            http://www.freshports.org/comms/ncid/

> ### <a name="relnot_ubuntu">Ubuntu packages</a>

> Available at the 3rd Party Repository: GetDeb Apps (sometimes sourceforge).

> Add the repository if needed:

          wget -q -O - http://archive.getdeb.net/getdeb-archive.key \
            | sudo apt-key add -
          sudo sh -c \
            "echo 'deb http://archive.getdeb.net/ubuntu precise-getdeb apps' \
            >> /etc/apt/sources.list"
        Update the apt cache:
          sudo apt-get update
        List the available packages:
          sudo apt-cache search ncid
        Install the server and client:
          sudo apt-get install ncid ncid-client
        Install any optional output modules wanted:
          sudo apt-get install ncid-<module>

> ### <a name="relnot_debian">Debian based OS packages</a>

> includes Debian, Ubuntu, Raspbian, etc

> If the latest package is not available at the repository:

        - Download the latest NCID deb packages from sourceforge:
          ncid DEB Package
          ncid-client DEB Package - client and default output modules

        - Download any optional output modules wanted:
          ncid-MODULE DEB Package  - optional client output modules

        - Install or Upgrade the packages using the gdebi-gtk (GUI):
            * If needed use the the menu item "Add/Remove.." to install the
              GDebi Package Installer.
            * Using the file viewer:
                - Open the file viewer to view the NCID DEB packages
                - Select the DEB packages
                - double click selections or right click selections and select
                  "Open with GDebi Package installer"

        - Install or Upgrade the packages using gdebi (command line):
            * Install gdebi if needed:
              sudo apt-get install gdebi    
            * Install the NCID server and gateways:
              sudo gdebi ncid-<version>_<processor>.deb
            * Install the client package and default modules:
              sudo gdebi ncid-client-<version>_all.deb
            * Install any optional modules wanted:
              sudo gdebi ncid-<module-<version>_all.deb

        Notes:
            <version> would be something like: 0.89-1
            <processor> would be something like: i386, armhf
            <module> would be a module name like: kpopup, mythtv, samba

> If you need to build a package for your specific OS or release, the
  build-essential, fakeroot, & libpcap packages must be installed:

            sudo apt-get build-essential fakeroot libpcap0.8-dev
            tar -xzf ncid-0.89-src.tar.gz
            mv ncid ncid-0.89
            cd ncid-0.89
            fakeroot debian/rules build
            fakeroot debian/rules binary
            fakeroot debian/rules clean

## <a name="relnot_spec">Distribution Changes</a>

> Cygwin:

> Fedora, Redhat, and RPM based systems:

> FreeBSD:

> Mac OS X:

> Ubuntu, Raspbian, Debian based systems:

> TiVo:

> Windows:

## <a name="relnot_server">Server Changes</a>

> ncidd:

> - added code to enable supported option by a client
> - option to send back the original line the client sent
    useful for smart phone gateways to determine if information
    reached the server and was not corrupt
> - hangup option mode 2 to answer as a FAX then hangup
> - MSG and PID text lines now include support information like
    date and time message sent, see NCID-SDK for more information
> - code improvements and fixes

## <a name="relnot_gate">Gateway Changes</a>

> ncid2ncid:

> sip2ncid:

> yac2ncid:

> wc2ncid:

> rn2ncid:

## <a name="relnot_client">Client Changes</a>

> ncid:

> - default changed from not wrapping lines to wrapping lines by words
> - modified handle all aliases
> - includes support for the mew message format used by NOT: and MSG:
> - code improvements and fixes

## <a name="relnot_mod">Client Module Changes</a>

## <a name="relnot_tool">Tool Changes</a>

> cidalias:

> - removed changes in comments
> - added copyright

> cidcall:

> - updated
> - removed changes in comments
> - added copyright

> cidupdate:

> - modified handle all aliases
> - code improvements and fixes
> - removed changes in comments
> - added version that tracks the NCID version
> - added copyright

> ncidutil:

> - modified to handle all aliases
> - code improvements and fixes
> - added version that tracks the NCID version
> - added copyright

## <a name="relnot_doc">Documentation Changes</a>

> - cidcall.1: updated
> - cidupdate.1: updated
> - ncidutil.1: updated
> - NCID.SDK: updated for feature changes

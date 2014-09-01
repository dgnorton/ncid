# Release Notes for NCID 1.0

## Index

* NCID Distributions
* Distribution Changes
* Server Changes
* Gateway Changes
* Client Changes
* Client Module Changes
* Tool Changes
* Documentation Changes

## NCID Distributions

> * sourceforge
> * Fedora packages
> * RPM based OS packages
> * Macintosh OS X package
> * FreeBSD package
> * Ubuntu packages
> * Debian based OS packages]

> ### sourceforge

          NCID source package:           ncid-1.0-src.tar.gz

          Cygwin 32 bit Windows package: ncid-1.0-cygwin.tgz

          TiVo Series1 package:          ncid-1.0-ppc-tivo.tgz
          TiVo Series 2-3 package:       ncid-1.0-mips-tivo.tgz

          Ubuntu 64 bit package:         ncid_1.0-1_amd64.deb
          Ubuntu no-arch packages:       ncid-client_1.0-1_all.deb
                                   ncid-kpopup_1.0-1_all.deb
                                   ncid-mythtv_1.0-1_all.deb
                                   ncid-samba_1.0-1_all.deb
                                   ncid-speak_1.0-1_all.deb

          Windows client installer:      ncid-1.0-client_setup.exe

> These may also be distributed:

          Fedora 64 bit package:         ncid-1.0-1.fc20.x86_64.rpm
          Fedora no-arch packages:       ncid-client-1.0-1.fc20.noarch.rpm
                                   ncid-kpopup-1.0-1.fc20.noarch.rpm
                                   ncid-mythtv-1.0-1.fc20.noarch.rpm
                                   ncid-samba-1.0-1.fc20.noarch.rpm
                                   ncid-speak-1.0-1.fc20.noarch.rpm

          Macintosh 64 bit OS X package: ncid-1.0-mac-osx.tgz

          FreeBSD 32 bit package:        ncid-1.0-freebsd.tgz

          Debian packages:               Ubuntu packages should install as-is

          Raspberry Pi packages:         ncid_1.0-1_armhf.deb
                                   other packages are the same as Ubuntu

> ### Fedora packages

> Available at the Fedora repository (sometimes sourceforge).
  New release first appears in the rawhide repository.
  There are server, client, and optional output module packages.
  Normally you only need to install the ncid & ncid-client rpm packages.

> The yum list command will show you the packages available:

          yum list ncid\*

> If the above does not show version 1.0:

          yum --enablerepo=rawhide list ncid\*

> If the rawhide repo is not installed:

          yum install fedora-release-rawhide

> If you need to build packages for your specific OS release:

          rpmbuild -tb ncid-1.0-src.tar.gz

> ### RPM based OS packages

> includes Fedora, Redhat, CentOS, etc.

> If a dependency can not be resolved, you should try rebuilding packages:

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
              <version> would be something like: 1.0-1
              <module> would be a module name like: kpopup, mythtv, samba

> ### Macintosh OS X package

          Available at MacPorts (sometimes sourceforge).
              http://trac.macports.org/browser/trunk/dports/net/ncid/Portfile

> ### FreeBSD package

          Available at FreshPorts (sometimes sourceforge).
              http://www.freshports.org/comms/ncid/

> ### Ubuntu packages

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

> ### Debian based OS packages

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
            <version> would be something like: 1.0-1
            <processor> would be something like: i386, armhf
            <module> would be a module name like: kpopup, mythtv, samba

> If you need to build a package for your specific OS or release, the
  build-essential, fakeroot, & libpcap packages must be installed:

            sudo apt-get build-essential fakeroot libpcap0.8-dev
            tar -xzf ncid-1.0-src.tar.gz
            mv ncid ncid-1.0
            cd ncid-1.0
            fakeroot debian/rules build
            fakeroot debian/rules binary
            fakeroot debian/rules clean

## Distribution Changes

> Cygwin:

> Fedora, Redhat, and RPM based systems:

> FreeBSD:

> Mac OS X:

> Ubuntu, Raspbian, Debian based systems:

> TiVo:

> Windows:

## Server Changes

> ncidd:

> - The server alias, blacklist, and whitelist tables are no longer a fixed size.
    The size is now determined by the number of entries in the alias, blacklist,
    and whitelist files.
> - FAX hangup now works with more FAX modems.  If FAX mode does not generate
    FAX tones before hangup, try setting pickup = 0 in the hangup section of
    ncidd.conf.
> - If hangup is configured for FAX hangup but the modem is not a FAX modem,
    ncidd will change hangup from FAX hangup to normal hangup with a warning
    in the ncidd.log file.
> - The server will respond to a client or gateway request to make sure
    the connection is still valid.
> - The server now handles NetTalk Caller ID when using a modem.
> - The server now sends a API version and feature set supported to clients
    and gateways on connection

## Gateway Changes

> ncid2ncid:

> sip2ncid:

> yac2ncid:

> wc2ncid:

> rn2ncid:

## Client Changes

> ncid:

> - fixed crash when reading a PID call from the call file
> - changed module output so MESG line is always last
> - added configure option for module output to previous clients

## Client Module Changes

> - changed input so MESG line is the same to simplify scripts

> ncid-skel:

> - added a second display format and option to select it

## Tool Changes

> cidalias:

> cidcall:

> cidupdate:

> - modified to handle a single '\*' for a name or number in a line alias
> - fixed the NMBRNAME alias to update a number instead of just a name

> ncidutil:

## Documentation Changes

> - GettingStarted.md: improved
> - Modems.md: updated
> - SDK converted into a API
> - new SDK provided that contains the API and test scripts

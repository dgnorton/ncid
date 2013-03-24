#!/bin/sh

# Wakeup Output Module

# Last modified: Tue Jan 22, 2013

# This output module is called to wakeup X-Windows for ncid
# in GUI mode or using a output module.  If another module
# is called, it is executed before that module.  Since no
# information regarding the call is required, none is sent.
#
# IMPORTANT: This module only works with X-windows and Gnome.
#            It is called when the WakeUp option is set.
#            Do not set the ncid "--program | -P" option.
#
# ncid usage:
#   ncid --wakeup
#   ncid (when WakeUP in ncid.conf is set to 1)

#ConfigDir=/usr/local/etc/ncid
#ConfigFile=$ConfigDir/ncidmodules.conf
#
#[ -f $ConfigFile ] && . $ConfigFile

VERSION=$(gnome-screensaver-command  -V | sed 's/[^0-9]*\([0-9]*\).*/\1/')

if [ $VERSION -ge 3 ]
then
    # Reset the display's timeout values
    /usr/bin/xset -display $DISPLAY s reset

    # Deactivate the gnome screensaver.
    /usr/bin/gnome-screensaver-command --deactivate

else
    # Deactivate the screensaver
    /usr/bin/xset -display $DISPLAY dpms force on

    # Simulate a keystroke to reset the display's timeout values
    /usr/bin/gnome-screensaver-command --poke
fi

exit 0

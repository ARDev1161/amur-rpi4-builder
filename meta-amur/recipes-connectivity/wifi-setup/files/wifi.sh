#!/bin/sh
### BEGIN INIT INFO
# Provides:          wifi-unblock
# Required-Start:    $network $remote_fs $syslog
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Unblock Wi-Fi
### END INIT INFO

rfkill unblock wifi
# iw dev wlan0 set power_save off
udhcpc -i wlan0 &

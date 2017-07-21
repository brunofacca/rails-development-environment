#!/bin/sh
# Init script source: https://gist.github.com/dloman/8303932

### BEGIN INIT INFO
# Provides: Xvfb
# Required-Start: $local_fs $remote_fs
# Required-Stop:
# X-Start-Before:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Loads X Virtual Frame Buffer
### END INIT INFO

XVFB=/usr/bin/Xvfb
# We might take screenshots of our headless browser. As of 2017 most users use
# a screen resolutions of 1366x768. See
# https://www.w3schools.com/browsers/browsers_display.asp
XVFBARGS=":1 -screen 0 1366x768x24 -ac -noreset"
PIDFILE=/var/run/xvfb.pid

case "$1" in
    start)
        start-stop-daemon --start --quiet --pidfile $PIDFILE --make-pidfile --background --exec $XVFB -- $XVFBARGS
        ;;
    stop)
        start-stop-daemon --stop --quiet --pidfile $PIDFILE
        ;;
    restart)
        $0 stop
        $0 start
        ;;
    *)
        echo "Usage: /etc/init.d/xvfb {start|stop|restart}"
        exit 1
esac

exit 0

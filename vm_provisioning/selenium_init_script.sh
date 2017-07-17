#!/bin/sh
# Init script source: https://gist.github.com/dloman/8303932

### BEGIN INIT INFO
# Provides:      	selenium-standalone
# Required-Start:	$local_fs $remote_fs $network $syslog
# Required-Stop: 	$local_fs $remote_fs $network $syslog
# Default-Start: 	2 3 4 5
# Default-Stop:  	0 1 6
# Short-Description: Selenium standalone server
### END INIT INFO

DESC="Selenium standalone server"
USER=ubuntu
JAVA=/usr/bin/java
# /var/run/selenium should be owned by $USER
PID_FILE=/var/run/selenium/selenium.pid
JAR_FILE=/usr/local/bin/selenium-server-standalone-3.4.0.jar
# Keep the log in the user home dir to avoid permission issues
LOG_FILE=/home/$USER/selenium.log

DAEMON_OPTS="-jar $JAR_FILE -log $LOG_FILE"
# See this Stack Overflow item for a delightful bug in Java that requires the
# strange-looking java.security.egd workaround below:
# http://stackoverflow.com/questions/14058111/selenium-server-doesnt-bind-to-socket-after-being-killed-with-sigterm
DAEMON_OPTS="-Djava.security.egd=file:/dev/./urandom $DAEMON_OPTS"

case "$1" in
    start)
        start-stop-daemon -c $USER --start --background --pidfile $PID_FILE --make-pidfile --exec $JAVA -- $DAEMON_OPTS
        ;;
    stop)
        start-stop-daemon --stop --pidfile $PID_FILE
        ;;
    restart)
        $0 stop
        $0 start
        ;;
    *)
        echo "Usage: /etc/init.d/selenium-standalone {start|stop|restart}"
        exit 1
    ;;
esac

exit 0

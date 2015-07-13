#!/usr/bin/env bash
MIDO_HOME=/usr/share/midonet-clio
MIDO_ETC=/etc/midonet-clio
MIDO_CFG=/etc/midonet-clio
MIDO_LOG_DIR=/var/log/midonet-clio/
MIDO_DEBUG_PORT=8003
MIDO_LOG_BACK=logback.xml



set -e

exec >> /var/log/midonet-clio/upstart-stderr.log

if [ -f /usr/share/midonet-clio/midonet-clio-env.sh ]; then
    . /usr/share/midonet-clio/midonet-clio-env.sh
else
    echo "/usr/share/clio/clio-env.sh: file not found"
    exit 1
fi


MIDO_JAR=`ls $MIDO_HOME/clio-*.jar`
MIDO_DEP_CLASS_PATH=$MIDO_HOME/dep/*
MIDO_MAIN=org.midonet.mem.flowhistory.clio.ClioApp

test -r $MIDO_JAR || exit 1

# OpenJDK uses the system jnidispatcher as default, since /usr/lib/jni is in
# the java library path.  If we specify our jna.jar in the classpath, this
# leads to incompatibility.  We should use either (1) the system jnidispatcher
# and the system jna.jar or (2) the packaged jnidispatcher and the packaged
# jna.jar.  Here we remove the /usr/lib/jni from the library path to use the
# packaged jnidispatcher
JAVA_LIBRARY_PATH=-Djava.library.path=/lib:/usr/lib

test -r $MIDO_ETC/midonet-clio-env.sh && . /etc/midonet-clio/midonet-clio-env.sh

set -x

JAVA_OPTS="$JVM_OPTS -Dclio.log.dir=$MIDO_LOG_DIR -Dlogback.configurationFile=$MIDO_CFG/$MIDO_LOG_BACK"
if [ "xyes" = "x$DEBUG" ] ; then
    JAVA_OPTS="$JAVA_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,address=$MIDO_DEBUG_PORT,server=y,suspend=y"
fi

exec $JAVA $JAVA_LIBRARY_PATH  \
 -cp $MIDO_ETC:$MIDO_JAR:$MIDO_DEP_CLASS_PATH $JAVA_OPTS $MIDO_MAIN

#!/bin/bash

PKGSERVER_USER="${PKGSERVER_USER-pkgserver}"
PKGSERVER_GROUP="${PKGSERVER_GROUP-$PKGSERVER_USER}"

set -e
set -x

[ `whoami` = 'root' ]

. /home/$PKGSERVER_USER/setup-env

deluser --remove-home $PKGSERVER_USER || true
delgroup --only-if-empty $PKGSERVER_GROUP || true

set +x
cat <<EOF

Cleanup complete.
Don't forget to check and MAYBE remove $PKGSERVER_DATADIR
                                   and $PKGSERVER_LOGDIR

EOF

#!/bin/bash
#
# Script to do something like what the Dockerfile does, only without docker.
#
# Written for debianish/ubuntuish systems.

PKGSERVER_USER="${PKGSERVER_USER-pkgserver}"
PKGSERVER_GROUP="${PKGSERVER_GROUP-$PKGSERVER_USER}"

PKGSERVER_DATADIR="${PKGSERVER_DATADIR-/var/lib/pkgserver}"
PKGSERVER_LOGDIR="${PKGSERVER_LOGDIR-/var/log/pkgserver}"

set -e
set -x

[ `whoami` = 'root' ]

addgroup --system $PKGSERVER_GROUP
adduser --system --ingroup $PKGSERVER_GROUP $PKGSERVER_USER

[ -d "$PKGSERVER_DATADIR" ] || mkdir -p "$PKGSERVER_DATADIR"
chown $PKGSERVER_USER:$PKGSERVER_GROUP "$PKGSERVER_DATADIR"

[ -d "$PKGSERVER_LOGDIR" ] || mkdir -p "$PKGSERVER_LOGDIR"
chown $PKGSERVER_USER:$PKGSERVER_GROUP "$PKGSERVER_LOGDIR"

rsync -a --delete ./service /home/$PKGSERVER_USER/.
chown -R $PKGSERVER_USER:$PKGSERVER_GROUP /home/$PKGSERVER_USER/service

rm -rf /home/$PKGSERVER_USER/pkgserver-supervisor

su -s /bin/bash - $PKGSERVER_USER <<EOF
echo ===========================================================================
set -e
set -x

mkdir -p pkgserver-supervisor
cat <<INNEREOF > pkgserver-supervisor/run
#!/bin/sh
set -e
set -x
cd \$HOME
export HOME="\$HOME"
exec setuidgid \$USER svscan "\$HOME/service"
INNEREOF
chmod a+x pkgserver-supervisor/run

cat <<INNEREOF > setup-env
export PATH="\$HOME/racket/bin:\\\$PATH"
export PKGSERVER_DATADIR="$PKGSERVER_DATADIR"
export PKGSERVER_LOGDIR="$PKGSERVER_LOGDIR"
INNEREOF

. setup-env

racket_version=6.6
if [ ! -d racket ]
then
  if [ ! -f ./racket-installer.sh ]
  then
    curl -f https://mirror.racket-lang.org/installers/\${racket_version}/racket-\${racket_version}-x86_64-linux.sh > ./racket-installer.sh
  fi
  printf 'no\n./racket\n\n' | sh ./racket-installer.sh
  rm ./racket-installer.sh
fi

if [ ! -f package-dependencies-installed ]
then
  raco pkg install --auto -i base web-server-lib dynext-lib
  raco pkg install -n bcrypt -i git://github.com/samth/bcrypt.rkt#94c0018da46d64700bfa549c1146801a8a6db87d
  raco pkg install --auto -i plt-service-monitor

  raco pkg install -i git://github.com/tonyg/racket-reloadable#cae2a141955bc2e0d068153f2cd07f88e6a6e9ef
  touch package-dependencies-installed
fi

[ -d pkg-index ] || git clone -b master git://github.com/racket/pkg-index pkg-index
[ -d racket-pkg-website ] || git clone git://github.com/tonyg/racket-pkg-website racket-pkg-website

set +x
echo ===========================================================================
EOF

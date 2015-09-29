#!/bin/sh
exec docker run \
     -p 8443:443 \
     -v `pwd`/../pkg-index:/usr/local/pkg-index \
     -v `pwd`/../racket-pkg-website:/usr/local/racket-pkg-website \
     -v `pwd`/data:/var/lib/pkgserver \
     pkg

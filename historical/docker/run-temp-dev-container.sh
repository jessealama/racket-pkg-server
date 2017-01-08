#!/bin/sh
exec docker run \
     -p 7443:443 \
     -v `pwd`/../pkg-index:/usr/local/pkg-index \
     -v `pwd`/../racket-pkg-website:/usr/local/racket-pkg-website \
     -v `pwd`/config-pkg-index.rkt:/usr/local/pkg-index/official/configs/docker.rkt \
     -v `pwd`/config-racket-pkg-website.rkt:/usr/local/racket-pkg-website/configs/docker.rkt \
     -v `pwd`/config-apache-proxy.conf:/etc/apache2/sites-available/apache-proxy.conf \
     -v `pwd`/data:/var/lib/pkgserver \
     pkg

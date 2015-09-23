# -*- shell-script -*-
FROM phusion/baseimage:0.9.17

# Curl seems to be part of the baseimage, but it doesn't hurt to check
RUN apt-get -y update && apt-get -y install curl

# Install a specific snapshot of racket
ENV racket_snapshot 20150923-aaf098f
ENV racket_version 6.2.900.17
RUN curl http://www.cs.utah.edu/plt/snapshots/${racket_snapshot}/installers/min-racket-${racket_version}-x86_64-linux-precise.sh > /root/racket-installer.sh
RUN printf 'no\n/usr/local/racket\n' | sh /root/racket-installer.sh
RUN ln -s /usr/local/racket/bin/* /usr/local/bin

###########################################################################
## Install daemons etc. here.

# Packages not part of baseimage
RUN apt-get -y install git make

# Configure website user and service startup script
RUN groupadd -f pkgserver
RUN useradd -r -s /bin/false -g pkgserver pkgserver

# Install website code
RUN raco pkg install --auto -i base web-server-lib
RUN raco pkg install -i git://github.com/tonyg/racket-reloadable#cae2a141955bc2e0d068153f2cd07f88e6a6e9ef
RUN git clone git://github.com/tonyg/racket-pkg-website /usr/local/racket-pkg-website

RUN mkdir -p /var/lib/pkgserver && chown -R pkgserver:pkgserver /var/lib/pkgserver
COPY service/ /etc/service/
COPY docker.rkt /usr/local/racket-pkg-website/configs/

EXPOSE 8443

###########################################################################

# Set runit to be the main init process, and clean up after apt
CMD ["/sbin/my_init"]
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

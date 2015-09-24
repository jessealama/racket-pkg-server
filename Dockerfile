# -*- shell-script -*-
FROM phusion/baseimage:0.9.17

# Turn off recommended packages
RUN printf 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";\n' > /etc/apt/apt.conf.d/99norecommends

# Curl seems to be part of the baseimage, but it doesn't hurt to check
RUN apt-get -y update && apt-get -y install curl

# Packages not part of baseimage
RUN apt-get -y install git make ssmtp rsync

# Configure website user and service startup script
RUN groupadd -f pkgserver
RUN useradd -r -s /bin/false -g pkgserver pkgserver

# Install a specific snapshot of racket
ENV racket_snapshot 20150923-aaf098f
ENV racket_version 6.2.900.17
RUN curl http://www.cs.utah.edu/plt/snapshots/${racket_snapshot}/installers/min-racket-${racket_version}-x86_64-linux-precise.sh > /root/racket-installer.sh
RUN printf 'no\n/usr/local/racket\n/usr/local/\n' | sh /root/racket-installer.sh
RUN rm /root/racket-installer.sh

# For some of the Racket packages we want to install, we will need a compiler.
# We remove the compiler again later.
RUN apt-get -y install gcc libc6-dev

# Install base racket dependencies needed for our services
RUN raco pkg install --auto -i base web-server-lib dynext-lib

# Install package catalog server code
RUN raco pkg install -n bcrypt -i git://github.com/samth/bcrypt.rkt#2c85f7e87e4460e892bba8e31271c44bb480c46f
RUN git clone -b configurable git://github.com/tonyg/pkg-index /usr/local/pkg-index

# Remove the compiler we installed above.
RUN apt-get -y autoremove --purge gcc libc6-dev

# Install website code
RUN raco pkg install -i git://github.com/tonyg/racket-reloadable#cae2a141955bc2e0d068153f2cd07f88e6a6e9ef
RUN git clone git://github.com/tonyg/racket-pkg-website /usr/local/racket-pkg-website

# Configure services
RUN mkdir -p /var/lib/pkgserver && chown -R pkgserver:pkgserver /var/lib/pkgserver
COPY service/ /etc/service/
COPY config-racket-pkg-website.rkt /usr/local/racket-pkg-website/configs/docker.rkt
COPY config-pkg-index.rkt /usr/local/pkg-index/official/configs/docker.rkt

# racket-pkg-website, pkg-index respectively. Both HTTPS.
EXPOSE 8443 9004

# Set runit to be the main init process, and clean up after apt
CMD ["/sbin/my_init"]
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

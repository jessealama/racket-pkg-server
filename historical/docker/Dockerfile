# -*- shell-script -*-
FROM phusion/baseimage:0.9.19

# Turn off recommended packages
RUN printf 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";\n' > /etc/apt/apt.conf.d/99norecommends

# Curl seems to be part of the baseimage, but it doesn't hurt to check.
# Packages not part of baseimage:
#  - Apache reverse-proxies to pkg-index and racket-pkg-website.
#  - For some of the Racket packages we want to install, we will need a compiler.
#    We remove the compiler again later.
RUN apt-get -y update && apt-get -y install curl git make exim4 rsync apache2 gcc libc6-dev

###########################################################################
# # Install a specific snapshot of racket
# ENV racket_snapshot 20150928-dfef5b4
# ENV racket_version 6.2.900.17
# RUN curl -f http://www.cs.utah.edu/plt/snapshots/${racket_snapshot}/installers/min-racket-${racket_version}-x86_64-linux-precise.sh > /root/racket-installer.sh
###########################################################################
ENV racket_version 6.6
RUN curl -f https://mirror.racket-lang.org/installers/${racket_version}/racket-${racket_version}-x86_64-linux.sh > /root/racket-installer.sh
###########################################################################

RUN printf 'no\n/usr/local/racket\n/usr/local/\n' | sh /root/racket-installer.sh
RUN rm /root/racket-installer.sh

# Install base racket dependencies needed for our services
RUN raco pkg install --auto -i base web-server-lib dynext-lib

# Install package catalog server dependencies
RUN raco pkg install -n bcrypt -i git://github.com/samth/bcrypt.rkt#94c0018da46d64700bfa549c1146801a8a6db87d
# This package transitively depends on a LOT of other stuff. TODO: simplify
RUN raco pkg install --auto -i plt-service-monitor

# Install website dependencies
RUN raco pkg install -i git://github.com/tonyg/racket-reloadable#cae2a141955bc2e0d068153f2cd07f88e6a6e9ef

# Remove the compiler we installed above.
RUN apt-get -y autoremove --purge gcc libc6-dev

# Install code for package catalog server and website
RUN git clone -b configurable git://github.com/tonyg/pkg-index /usr/local/pkg-index
RUN git clone git://github.com/tonyg/racket-pkg-website /usr/local/racket-pkg-website

# Configure services
RUN groupadd -f pkgserver
RUN useradd -r -s /bin/false -d /var/lib/pkgserver -g pkgserver pkgserver
RUN mkdir -p /var/lib/pkgserver && chown -R pkgserver:pkgserver /var/lib/pkgserver
COPY service/ /etc/service/
COPY config-racket-pkg-website.rkt /usr/local/racket-pkg-website/configs/docker.rkt
COPY config-pkg-index.rkt /usr/local/pkg-index/official/configs/docker.rkt
COPY config-apache-proxy.conf /etc/apache2/sites-available/apache-proxy.conf
RUN a2dissite 000-default && a2enmod ssl proxy proxy_http && a2ensite apache-proxy
EXPOSE 443

# Email-sending
COPY update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf
RUN echo 'pkgd.racket-lang.org' > /etc/mailname; update-exim4.conf

# Set runit to be the main init process, and clean up after apt
CMD ["/sbin/my_init"]
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#!/bin/sh
exec docker run -p 8443:443 -v `pwd`/data:/var/lib/pkgserver pkg

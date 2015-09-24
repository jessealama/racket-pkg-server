#!/bin/sh
exec docker create -p 8443:443 -v `pwd`/data:/var/lib/pkgserver pkg

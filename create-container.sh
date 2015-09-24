#!/bin/sh
exec docker create -p 8443:8443 -p 9004:9004 -v `pwd`/data:/var/lib/pkgserver pkg

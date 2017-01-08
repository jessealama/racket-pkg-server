# The Racket Package Catalog Server

The Racket Package Catalog comprises two pieces of software that work
in tandem:

 - [`pkg-index`](https://github.com/tonyg/pkg-index/tree/configurable)
   a.k.a. "the backend"

 - [`racket-pkg-website`](https://github.com/tonyg/racket-pkg-website)
   a.k.a. "the frontend"

The backend maintains the core package and user databases, and has a
JSON-based API. The frontend uses the backend to build and display
both statically- and dynamically-rendered pretty pages for users to
look at.

Roughly speaking, the backend produces artifacts that Racket's package
management subsystem interacts with, and the frontend produces
artifacts that humans interact with.

In future, the functionality of the backend will likely be
piece-by-piece moved over to the frontend, at which point we'll have a
single package catalog server again.

Finally, the documentation you are reading exists in a
[`racket-pkg-server`](https://github.com/tonyg/racket-pkg-server)
repository, along with scripts for configuring and deploying catalog
server instances.

## Git branches required

The backend is currently deployed from the `configurable` branch
rather than `master`, which is the original catalog server from before
the separate frontend was integrated with it.

You will want:

 - `configurable` from `pkg-index`
 - `master` from `racket-pkg-website`
 - `master` from `racket-pkg-server`

## Base operating system requirements

A fresh Debian- or Redhat-like Linux instance should work just fine.

## The `standalone-create.sh` script

The script [standalone-create.sh][] performs many of the tasks needed
to set up a server instance.

**READ IT CAREFULLY BEFORE RUNNING IT.**

In principle, checking out `racket-pkg-server` on a fresh server and
running `standalone-create.sh` should be enough to get the `pkgserver`
user created and in good shape. Currently, setup of Apache, the
firewall, and backups is still a manual task.

(See [the dockerized server](historical/docker/) for one possible
approach to fully automating deployment.)

## Users and groups

For the live configuration, a special `pkgserver` user owns all the
relevant files. The service needs no special privileges to run.

The `pkgserver` user is the (only, initially) member of the group
`pkgserver`.

Generally, when editing config files or restarting service processes,
do so as the `pkgserver` user:

    sudo su -s /bin/bash - pkgserver

The `-s` argument to `su` is needed because `pkgserver` doesn't have a
shell.

## Firewall

The only needed ports are 80 and 443, so that users can connect to the
Apache reverse proxy. Make sure other ports are closed: in particular,
do not allow external access to the server processes themselves.

## Apache reverse proxy

Apache is used to reverse proxy incoming HTTP(S) requests to the
actual server processes themselves.
[Letsencrypt](https://letsencrypt.org/) is used to get the necessary
SSL certificates.

The [apache-pkgd-site.conf][] configuration
file is installed in Apache's `sites-enabled` directory. It contains
the mappings from external URLs to internal service URLs.

## Server processes and process supervision

The backend and frontend services are automatically started (and
restarted, if it terminates or crashes) by
[DJB's daemontools](https://cr.yp.to/daemontools.html).

A symbolic link in `/etc/service` to `~pkgserver/pkgserver-supervisor`
causes the system-wide daemontools to start up an svscan instance
specific to the `pkgserver` user. See [standalone-create.sh][] to find
out how the `pkgserver-supervisor` directory is created and populated.

The [service][] directory contains the daemontools startup and logging
scripts that start the backend and frontend processes.

In summary:

 - The system daemontools supervises
    - A `pkgserver` user-specific svscan instance, which supervises
       - `pkg-index`, the backend, and
       - `racket-pkg-website`, the frontend.

The backend and frontend both run as the `pkgserver` user by virtue of
the way the user-specific svscan instance is set up.

## Starting and stopping the service

To do a clean restart of one or the other of the servers,

    sudo -u pkgserver svc -du /home/pkgserver/service/pkg-index
    sudo -u pkgserver svc -du /home/pkgserver/service/racket-pkg-website

(More info on daemontools's svc program here:
<https://cr.yp.to/daemontools/svc.html>)

Restarting either of the Racket processes by simply killing it will
also work OK. The daemontools supervision ensures that they will be
restarted.

It is more or less safe to reboot the machine, if that becomes
necessary.

To bring down a service, use `-d` instead of `-du` as the first
argument to `svc`. To bring it back up again afterwards, use `-u`.

## Viewing server logs

There are two active logs, plus a bunch of rolled-over log files. The
active logs are

    /home/pkgserver/service/pkg-index/log/main/current
    /home/pkgserver/service/racket-pkg-website/log/main/current

Earlier files are adjacent in those directories.

Use [`tai64nlocal`](https://cr.yp.to/daemontools/tai64nlocal.html) as
a filter to get human-readable timestamps; you can track the files
with

    tail -F /home/pkgserver/service/*/log/main/current | tai64nlocal

## URL structure

The configuration of the live deployment of the package catalog
involves many moving pieces:

 - Amazon S3 hosts static backend and frontend resources, served both
   to Racket instances and to human users.

 - Once a user logs in, they interact with the live frontend server
   process.

Currently,

 - `https://pkgs.racket-lang.org/` points to the single-page app that
   was the original user interface to the backend. It is served from
   S3.

 - `https://pkgn.racket-lang.org/` points to S3-hosted static files
   from the frontend.

 - `https://pkgd.racket-lang.org/` points to the live server's Apache
   instance, which reverse-proxies various URLs onto the backend and
   frontend as per [apache-pkgd-site.conf][].
     - `/jsonp` and `/api` prefixes go to the backend
     - `/pkgn` goes to the frontend

So, for example, for a package named `foo`,

 - `https://pkgs.racket-lang.org/pkg/foo` and
   `https://pkgn.racket-lang.org/pkg/foo` both refer to the
   Racket-readable information about `foo`

 - `https://pkgn.racket-lang.org/package/foo` is the static user
   interface to `foo`

 - If the user is logged in,
   `https://pkgd.racket-lang.org/pkgn/package/foo` is the
   dynamically-rendered user interface to `foo`, including options to
   edit or delete the package definition (according to the user's
   permissions).

 - If the user is *not* logged in,
   `https://pkgd.racket-lang.org/pkgn/package/foo` will redirect to
   `https://pkgn.racket-lang.org/package/foo`.

When we switch to using the new frontend by default, we will aim to
have the following URLs for the static and dynamically-rendered user
interfaces for a package:

 - `https://pkgs.racket-lang.org/package/foo` for a static-rendered,
   S3-hosted page

 - `https://pkgd.racket-lang.org/package/foo` for a
   dynamically-rendered, live-hosted page

Note that at that point, the only difference will be in `pkgs` vs
`pkgd`.

## Filesystem layout on the live server

 - `/home/pkgserver`
     - `racket` - the version of Racket used by both the backend and frontend; installed by [standalone-create.sh][]
     - `pkgserver-supervisor` - daemontools definition of the supervisor for the services in `service`; created by [standalone-create.sh][]
     - `service` - daemontools startup and logging scripts for the backend and frontend; a copy of [service][]
         - `pkg-index/log/main` - contains log files for the backend; see below
         - `racket-pkg-website/log/main` - contains log files for the frontend; see below
     - `pkg-index` - live checkout of the backend
     - `racket-pkg-website` - live checkout of the frontend
 - `/var/lib/pkgserver`
     - `pkg-index` - databases **AND CRYPTOGRAPHIC SECRETS** used by the backend
         - `pkgs` - master copy of the package catalog
         - `users.new` - master copy of the user database
         - other files documented in the `pkg-index` codebase
     - `public_html/pkg-index-static` - staging area for resources to be hosted by S3

Note that the important databases are in
`/var/lib/pkgserver/pkg-index`.

## Backups

`rsnapshot` and `rrsync` (see
[here](https://www.guyrutenberg.com/2014/01/14/restricting-ssh-access-to-rsync/))
are used to take periodic backups of the `/var/lib/pkgserver`
directory.

The file `~/.ssh/authorized_keys` of the `ubuntu` user on the server
contains (among more conventional entries)

    command="/usr/local/bin/rrsync -ro /var/lib/pkgserver/",no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding ssh-rsa AAAAB3Nz[...]fvGcW1 tonyg automated remote backup of pkgd 

... which allows me, on my own machine, to run `rsnapshot` from
`crontab` using the following `/etc/rsnapshot.conf` entry:

    backup  ubuntu@[THE_LIVE_HOSTNAME]:/      pkgd/   ssh_args=-i [FULL_PATH_TO_THE_SSH_PRIVATE_KEY]

Beware that `rsnapshot.conf` is ultra picky about using literal tab
characters to separate fields.

## Updating the service as you push new code to Github

Become `pkgserver` using

    sudo su -s /bin/bash - pkgserver

Then, either or both of

    (cd pkg-index; git pull)
    (cd racket-pkg-website; git pull)

Note that because the frontend uses
[`racket-reloadable`](https://github.com/tonyg/racket-reloadable),
some changes to the frontend will automatically and immediately go
live. For larger changes, or for changes to the backend, you will need
to restart the processes using `svc` as described above.

## tmux convention

I frequently have, under the `ubuntu` user on the server, a `tmux`
instance running, but it is not essential for operation of the service
and may be terminated or restarted ad libitum.



  [apache-pkgd-site.conf]: apache-pkgd-site.conf
  [standalone-create.sh]: standalone-create.sh
  [service]: service/

# Dockerized Racket Package Catalog plus UI

The catalog can run either entirely standalone, using HTTPS uniformly,
or in a split configuration using S3 via HTTP for static content and
generating dynamic content solely via HTTPS.

By default, it runs in the standalone configuration.

Important settings to change:

 - in `config-pkg-index.rkt`, only `email-sender-address`.

 - in `config-racket-pkg-website.rkt` and `config-apache-proxy.conf`,
   nothing, unless you want to use the split S3-based configuration.

 - in `Dockerfile`:
    - you may need to change the `/etc/mailname` setting (by default
      `pkgd.racket-lang.org`) to get user registration emails to work.
    - you may also need to change `racket_snapshot` and
      `racket_version`, as snapshots expire quite quickly and the one
      listed may no longer be available.

If you have an existing package catalog database you want to use, copy
its files into the `pkg-index/pkgs` directory as described below in
the "The Data Directory" section.

In the standalone configuration, dynamic resource URLS will all have
`.../catalog/` prefixing them, and static resources are all other
URLs; in the S3 configuration, two hostnames are used, one for each
class of resource.

## Setting up S3

The software can be configured to use an S3 bucket as a static copy of
the catalog, backed and managed by the Docker container.

### Know the domain names you'll be using

In my case,
 - `pkgs.leastfixedpoint.com` is for the S3 bucket, containing static
   resources only.
 - `pkgd.leastfixedpoint.com` is for the Docker container's dynamic
   resources.

### Create some IAM keys for the container to use

In IAM console, under "Users", create a new user. I called mine
"pkgserver". Save the keys away. You will need to put them in the
`.aws-keys` file in the data directory later.

In my case, with "pkgserver" as the user name, the ARN corresponding
to the user is `arn:aws:iam::861438980900:user/pkgserver`. You can
find this string on the user's own page.

### Create and configure the bucket

I created a bucket called `pkgs.leastfixedpoint.com`.

Configuring it:

 - Static Website Hosting → Enable website hosting. Set "Index
   Document" to `index.html`. Set "Error Document" to `not-found`.

 - Permissions → Edit bucket policy, and paste in something analogous
   to the following:

		{
			"Version": "2012-10-17",
			"Id": "Policy1443561236276",
			"Statement": [
				{
					"Sid": "Stmt1443561886247",
					"Effect": "Allow",
					"Principal": "*",
					"Action": "s3:GetObject",
					"Resource": "arn:aws:s3:::pkgs.leastfixedpoint.com/*"
				},
				{
					"Sid": "Stmt1443561886247b",
					"Effect": "Allow",
					"Principal": "*",
					"Action": "s3:ListBucket",
					"Resource": "arn:aws:s3:::pkgs.leastfixedpoint.com"
				},
				{
					"Sid": "Stmt1443561199132",
					"Effect": "Allow",
					"Principal": {
						"AWS": "arn:aws:iam::861438980900:user/pkgserver"
					},
					"Action": [
						"s3:GetObjectTorrent",
						"s3:GetObjectVersion",
						"s3:DeleteObject",
						"s3:DeleteObjectVersion",
						"s3:GetObject",
						"s3:PutObject"
					],
					"Resource": "arn:aws:s3:::pkgs.leastfixedpoint.com/*"
				},
				{
					"Sid": "Stmt1443561234476",
					"Effect": "Allow",
					"Principal": {
						"AWS": "arn:aws:iam::861438980900:user/pkgserver"
					},
					"Action": "s3:ListBucket",
					"Resource": "arn:aws:s3:::pkgs.leastfixedpoint.com"
				}
			]
		}

Deconstructing that, the first two stanzas (`Stmt1443561886247` and
`Stmt1443561886247b`) allow anonymous users to read objects in the
bucket and to list the contents of the bucket. The second two stanzas
(`Stmt1443561199132` and `Stmt1443561234476`) grant read, write,
delete and list permissions to our `pkgserver` IAM user. Note the ARN
in the `Principal` clauses.

### Alter the container's configuration

Follow the instructions in
`/etc/apache2/sites-available/apache-proxy.conf` (a.k.a
`config-apache-proxy.conf`) and in
`/usr/local/racket-pkg-website/configs/docker.rkt` (a.k.a
`config-racket-pkg-website.rkt`).

## The Data Directory

The container stores most of its important information, including
keys, databases, and generated HTML, in its `/var/lib/pkgserver`
directory by default.

The scripts `create-dev-container.sh` and `create-live-container.sh`
use Docker's `-v` option to bind `./data` to the container's
`/var/lib/pkgserver`.

The structure of `./data`, i.e. `/var/lib/pkgserver`, is as follows:

### Configuration files and credentials (i.e. inputs)

 - `.aws-keys`
     - used primarily for the S3 static site replication, but also
       currently needed to do server heartbeating via the
       `plt-service-monitor` package
     - see `pkg-index/official/beat-update.sh` and `racket-pkg-website/src/static.rkt`
     - must contain `AWSAccessKeyId` and `AWSSecretKey` definitions,
       per the `aws` package's requirements

 - `pkg-index/client_id`
 - `pkg-index/client_secret`
     - Github application authentication token ID and Secret, respectively

 - `pkg-index/private-key.pem`
 - `pkg-index/server-cert.pem`
     - HTTPS certificate to use for all services: not just the apache
       frontend, but also `pkg-index` and `racket-pkg-website`
       themselves.

### Database files (i.e. mutable, long-lived, valuable data)

 - `pkg-index/pkgs`
     - The master package database directory.

 - `pkg-index/users.new`
     - The master user database directory.

### Generated files (i.e. outputs)

 - `generated-htdocs`
     - Staging area containing files produced by `racket-pkg-website`
	 - rsync'd to `pkg-catalog-static` -- see below

 - `pkg-index/cache`
     - Information retrieved from the `pkg-build` server

 - `public_html/pkg-index-static`
     - Static HTML/CSS/JS files from `pkg-index`.
     - rsync'd to `pkg-catalog-static` -- see below

 - `public_html/pkg-catalog-static`
     - All static files.
     - Copied from all of:
        - `pkg-index`'s static files directory
		- `racket-pkg-website`'s static files directory
        - `racket-pkg-website`'s dynamically-generated static file staging directory
     - Files are served by the apache frontend directly from here.


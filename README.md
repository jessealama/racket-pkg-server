Configuration files (i.e. inputs) in `./data`:

 - `.aws-keys`
     - currently needed to do server heartbeating via the `plt-service-monitor` package
     - see `pkg-index/official/beat-update.sh`
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

Database files (i.e. mutable, long-lived, valuable data) in `./data`:

 - `pkg-index/pkgs`
     - The master package database directory.

 - `pkg-index/users.new`
     - The master user database directory.

Generated files (i.e. outputs) in `./data`:

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

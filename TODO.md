Install the plt-service-monitor package.

Make heartbeat script (pkg-index/official/beat-update.sh) use the right racket installation.

Set up email for new user accounts

BUG?: pkg-index accepts email addresses with no domain, i.e. addresses for machine users.

BUG: using apache as a reverse-proxy causes logging of requests
including credentials. Need to alter the API to require a basic-auth
header instead.

BUG: racket-pkg-website shows deps such as `(aws #hasheq((kw .
version)) 1.6)`, seen on plt-service-monitor, as their literal string
representation. It should just use `aws`.

Document the lot

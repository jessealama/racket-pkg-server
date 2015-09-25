Install the plt-service-monitor package.
 - it's on the package catalog
 - it has deps on a few things
 - but they transitively have deps on a shitload of stuff, including most of the documentation.
 - it MIGHT be possible to ignore some of the deps during installation.
    - raco pkg install -i --deps force plt-service-monitor ...
    - would have to manually track the deps I need to get beat-update.sh to run right

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

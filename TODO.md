Install the plt-service-monitor package.
 - it's on the package catalog
 - it has deps on a few things
 - but they transitively have deps on a shitload of stuff, including most of the documentation.
 - it MIGHT be possible to ignore some of the deps during installation.
    - raco pkg install -i --deps force plt-service-monitor ...
    - would have to manually track the deps I need to get beat-update.sh to run right

Make heartbeat script (pkg-index/official/beat-update.sh) use the right racket installation.

BUG?: pkg-index accepts email addresses with no domain, i.e. addresses for machine users.

Document the lot

Make the URLs nice.

convert modify-all API from jsonp to plain json

Figure out a way to nicely support the various racket-pkg-website signals.

Remove now-unused portions of the catalog API

Put search-completions, tag-search-completions, formal-tags into the
static part of the site.

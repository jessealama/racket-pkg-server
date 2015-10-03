Reduce dependencies needed to heartbeat; currently done with the plt-service-monitor package.
  - aws depends on http and sha; this seems reasonable
  - perhaps directly reimplement the heartbeating facility from
    plt-service-monitor, since that depends only on aws?

BUG?: pkg-index accepts email addresses with no domain, i.e. addresses for machine users.

Document the lot

Make the URLs nice.

convert modify-all API from jsonp to plain json

Figure out a way to nicely support the various racket-pkg-website signals.

Logging: take all warnings and errors, and forward them somewhere.
Email? XMPP? IRC? A special log file?

Move github readme check out of render and into elaboration.

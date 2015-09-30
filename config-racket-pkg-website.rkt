#lang racket/base
;; Configuration suitable for running the pkgserver website in this Docker container.
(require "../src/main.rkt")
(define var "/var/lib/pkgserver")
(main (hash 'reloadable? #t
            'var-path var
            'package-index-url "file:///var/lib/pkgserver/public_html/pkg-index-static/pkgs-all.json.gz"
            'backend-baseurl "https://localhost:9004"
            'pkg-index-generated-directory (build-path var "public_html/pkg-index-static")
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ;; Either:
            'static-output-type 'file
            'static-content-target-directory (build-path var "public_html/pkg-catalog-static")
            'static-urlprefix ""
            'dynamic-urlprefix "/catalog"
            ;; Or:
            ;; 'static-output-type 'aws-s3
            ;; 'aws-s3-bucket+path "pkgs.leastfixedpoint.com/"
            ;; 'static-urlprefix "http://pkgs.leastfixedpoint.com"
            ;; 'dynamic-urlprefix "https://pkgd.leastfixedpoint.com"
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ))

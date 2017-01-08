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
            ;; To configure a split, S3-based setup, comment out the following lines:
            ;;
            'static-output-type 'file
            'static-content-target-directory (build-path var "public_html/pkg-catalog-static")
            'static-urlprefix ""
            'dynamic-urlprefix "/catalog"
            ;;
            ;; ... and uncomment and adjust these instead:
            ;;
            ;; 'static-output-type 'aws-s3
            ;; 'aws-s3-bucket+path "pkgs.leastfixedpoint.com/"
            ;; 'static-urlprefix "http://pkgs.leastfixedpoint.com"
            ;; 'dynamic-urlprefix "https://pkgd.leastfixedpoint.com"
            ;;
            ;; Make sure to *include* a slash at the end of
            ;; aws-s3-bucket+path, and to *exclude* a slash from the
            ;; end of both static-urlprefix and dynamic-urlprefix.
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ))

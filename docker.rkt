#lang racket/base
;; Configuration suitable for running the pkgserver website in this Docker container.
(require "../src/main.rkt")
(define var "/var/lib/pkgserver")
(main (hash 'reloadable? #t
            'var-path var
            ;; 'package-index-url "https://localhost:8444/pkgs-all.json.gz"
            'static-content-target-directory (build-path var "public_html/pkg-catalog-static")
            ;; 'static-urlprefix "https://localhost/~tonyg/pkg-catalog-static"
            ;; 'dynamic-urlprefix "https://localhost:8444"
            ;; 'backend-baseurl "https://localhost:8445"
            ;; 'extra-static-content-directories (list (build-path var "public_html/pkg-index-static"))
            ))

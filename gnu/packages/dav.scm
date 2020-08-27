;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015, 2016, 2017 Leo Famulari <leo@famulari.name>
;;; Copyright © 2018, 2019 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2020 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2020 Vinicius Monego <monego@posteo.net>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages dav)
  #:use-module (guix build-system python)
  #:use-module (guix download)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (gnu packages)
  #:use-module (gnu packages check)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages sphinx)
  #:use-module (gnu packages xml))

(define-public radicale
  (package
    (name "radicale")
    (version "1.1.6")
    (source (origin
             (method url-fetch)
             (uri (pypi-uri "Radicale" version))
             (sha256
              (base32
               "0ay90nj6fmr2aq8imi0mbjl4m2rzq7a83ikj8qs9gxsylj71j1y0"))))
    (build-system python-build-system)
    (arguments
     '(#:tests? #f)) ; The tests are not distributed in the PyPi release.
    (propagated-inputs
      ;; TODO: Add python-pam
     `(("python-requests" ,python-requests)))
    (synopsis "Basic CalDAV and CardDAV server")
    (description "Radicale is a CalDAV and CardDAV server for UNIX-like
platforms.  Calendars and address books are available for both local and remote
access, possibly limited through authentication policies.  They can be viewed
and edited by calendar and contact clients on mobile phones or computers.

Radicale intentionally does not fully comply with the CalDAV and CardDAV RFCs.
Instead, it supports the CalDAV and CardDAV implementations of popular
clients.")
    (home-page "https://radicale.org/")
    (license gpl3+)))

(define-public xandikos
  (package
    (name "xandikos")
    (version "0.2.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "xandikos" version))
       (sha256
        (base32 "13ikmcja9p42azb5ccqj2bw98zybna6zlflj10hqy0kvbib70l94"))))
    (build-system python-build-system)
    (propagated-inputs
     `(("python-aiohttp" ,python-aiohttp)
       ("python-defusedxml" ,python-defusedxml)
       ("python-dulwich" ,python-dulwich)
       ("python-icalendar" ,python-icalendar)
       ("python-jinja2" ,python-jinja2)
       ("python-multidict" ,python-multidict)))
    (home-page "https://www.xandikos.org/")
    (synopsis "Lightweight CalDAV/CardDAV server")
    (description
     "Xandikos is a lightweight yet complete CardDAV/CalDAV server that backs
onto a Git repository.

Features:

@itemize
@item Easy to set up
@item Share calendars (events, todo items, journal entries) via CalDAV and
contacts (vCard) via CardDAV
@item Automatically keep history and back up changes in Git
@item Supports synchronization extensions for CalDAV/CardDAV for quick and
efficient syncing
@item Automatically keep history and back up
@item Works with all tested CalDAV and CardDAV clients
@end itemize")
    (license gpl3+)))

(define-public vdirsyncer
  (package
    (name "vdirsyncer")
    ;; When updating, check whether python-click-5 can be removed entirely.
    (version "0.16.8")
    (source (origin
             (method url-fetch)
             (uri (pypi-uri name version))
             (sha256
              (base32
               "1i8kp9j99rs8xdhrc1vx749zd9wznlzj0pb3s05xdm71a8pl5nxz"))))
    (build-system python-build-system)
    (arguments
     `(#:tests? #f ; The test suite is very flakey.
       #:phases (modify-phases %standard-phases
        (replace 'check
          (lambda* (#:key inputs outputs tests? #:allow-other-keys)
            (add-installed-pythonpath inputs outputs)
            (setenv "DETERMINISTIC_TESTS" "true")
            (setenv "DAV_SERVER" "radicale")
            (setenv "REMOTESTORAGE_SERVER" "skip")
            (if tests?
                (invoke "make" "test")
                #t)))
        (add-after 'unpack 'patch-version-call
          (lambda _
            (substitute* "docs/conf.py"
              (("^release.*") (string-append "release = '" ,version "'\n")))
            #t))
        (add-after 'install 'manpage
          (lambda* (#:key inputs outputs #:allow-other-keys)
            (invoke "make" "--directory=docs/" "man")
            (install-file
              "docs/_build/man/vdirsyncer.1"
              (string-append
                (assoc-ref outputs "out")
                "/share/man/man1"))
            #t)))))
    (native-inputs
     `(("python-setuptools-scm" ,python-setuptools-scm)
       ("python-sphinx" ,python-sphinx)
       ;; Required for testing
       ("python-hypothesis" ,python-hypothesis)
       ("python-pytest" ,python-pytest)
       ("python-pytest-localserver" ,python-pytest-localserver)
       ("python-pytest-subtesthack" ,python-pytest-subtesthack)
       ("python-urllib3" ,python-urllib3)
       ("python-wsgi-intercept" ,python-wsgi-intercept)
       ("radicale" ,radicale)))
    (inputs
     `(;; XXX https://github.com/mitsuhiko/click/issues/200
       ("python-click" ,python-click-5)))
    (propagated-inputs
     `(("python-atomicwrites" ,python-atomicwrites)
       ("python-click-log" ,python-click-log)
       ("python-click-threading" ,python-click-threading)
       ("python-requests-toolbelt" ,python-requests-toolbelt)))
    (synopsis "Synchronize calendars and contacts")
    (description "Vdirsyncer synchronizes your calendars and addressbooks
between two storage locations.  The most popular purpose is to
synchronize a CalDAV or CardDAV server with a local folder or file.  The
local data can then be accessed via a variety of programs, none of which
have to know or worry about syncing to a server.")
    (home-page "https://github.com/pimutils/vdirsyncer")
    (license bsd-3)))

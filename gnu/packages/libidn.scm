;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012 Andreas Enge <andreas@enge.fr>
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

(define-module (gnu packages libidn)
  #:use-module (gnu packages)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu))

(define-public libidn
  (package
   (name "libidn")
   (version "1.28")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnu/libidn/libidn-" version
                                ".tar.gz"))
            (sha256 (base32
                     "1yxbfdiwr3l91m79sksn6v5mgpl4lfj8i82zgryckas9hjb7ldfx"))))
   (build-system gnu-build-system)
;; FIXME: No Java and C# libraries are currently built.
   (synopsis "Internationalized string processing library")
   (description
    "The GNU IDN Libary is an implementation of the Stringprep, Punycode
and IDNA specifications.  These are used to encode and decode
internationalized domain names.  It includes native C, C# and Java libraries.")
   (license lgpl2.1+)
   (home-page "http://www.gnu.org/software/libidn/")))

;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Ludovic Courtès <ludo@gnu.org>
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

(define-module (gnu packages freeipmi)
  #:use-module (guix packages)
  #:use-module (guix licenses)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages gnupg))

(define-public freeipmi
  (package
    (name "freeipmi")
    (version "1.3.2")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnu/freeipmi/freeipmi-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "1gz2r3zp8ag4cd5cflh4fy8mpvwcx1wdr37mkqkph3m5lx2w48qb"))))
    (build-system gnu-build-system)
    (inputs
     `(("readline" ,readline) ("libgcrypt" ,libgcrypt)))
    (home-page "http://www.gnu.org/software/freeipmi/")
    (synopsis "Platform management, including sensor and power monitoring")
    (description
     "FreeIPMI is a collection of in-band and out-of-band IPMI software in
accordance with the IPMI v1.5/2.0 specification.  These programs provide a
set of interfaces for platform management.  Common functionality includes
sensor monitoring, system event monitoring, power control and
serial-over-LAN.")
    (license gpl3+)))

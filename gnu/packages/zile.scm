;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013 Ludovic Courtès <ludo@gnu.org>
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

(define-module (gnu packages zile)
  #:use-module (guix licenses)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages bdw-gc)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages help2man)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages bash))

(define-public zile
  (package
    (name "zile")
    (version "2.4.9")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnu/zile/zile-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "0j801c28ypm924rw3lqyb6khxyslg6ycrv16wmmwcam0mk3mj6f7"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-cons-before
                 'configure 'patch-/bin/sh
                 (lambda* (#:key inputs #:allow-other-keys)
                   (let ((bash (assoc-ref inputs "bash")))
                     ;; Refer to the actual shell.
                     (substitute* '("lib/spawni.c" "src/funcs.c")
                       (("/bin/sh")
                        (string-append bash "/bin/sh")))))
                 %standard-phases)))
    (inputs
     `(("boehm-gc" ,libgc)
       ("ncurses" ,ncurses)
       ("bash" ,bash)))
    (native-inputs
     `(("perl" ,perl)
       ("help2man" ,help2man)))
    (home-page "http://www.gnu.org/software/zile/")
    (synopsis "Zile is lossy Emacs, a lightweight Emacs clone")
    (description
     "Zile is a lightweight Emacs clone.  It usage is extremely similar to
that of Emacs but it carries a much lighter feature set.")
    (license gpl3+)))

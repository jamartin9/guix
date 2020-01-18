;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017, 2019, 2020 Hartmut Goebel <h.goebel@crazy-compilers.com>
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

(define-module (gnu packages kde-pim)
  #:use-module (guix build-system qt)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages cyrus-sasl)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages openldap)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages search)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages xml))

(define-public akonadi
  (package
    (name "akonadi")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/akonadi-" version ".tar.xz"))
       (sha256
        (base32 "0v7f1049wjnqxhwxr1443wc2cfbdqmf15xcwjz3j1m0vgdva9pyg"))
       (patches (search-patches
                 "akonadi-paths.patch"
                 "akonadi-timestamps.patch"
                 "akonadi-Revert-Make-installation-properly-relocatabl.patch"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)
       ("qttools" ,qttools)
       ("shared-mime-info" ,shared-mime-info)))
    (inputs
     `(("boost" ,boost)
       ("kconfig" ,kconfig)
       ("kconfigwidgets" ,kconfigwidgets)
       ("kcoreaddons" ,kcoreaddons)
       ("kcrash" ,kcrash)
       ("kdbusaddons" ,kdbusaddons)
       ("kdesignerplugin" ,kdesignerplugin)
       ("ki18n" ,ki18n)
       ("kiconthemes" ,kiconthemes)
       ("kio" ,kio)
       ("kitemmodels" ,kitemmodels)
       ("kitemviews" ,kitemviews)
       ("kwidgetsaddons" ,kwidgetsaddons)
       ("kwindowsystem" ,kwindowsystem)
       ("kxmlgui" ,kxmlgui)
       ("libxml2" ,libxml2)
       ("libxslt" ,libxslt)
       ;; Do NOT add mysql or postgresql to the inputs. Otherwise the binaries
       ;; and wrapped files will refer to them, even if the user choices none
       ;; of these.  Executables are searched on $PATH then.
       ("qtbase" ,qtbase)
       ("sqlite" ,sqlite)))
    (arguments
     `(#:tests? #f ;; TODO 135/167 tests fail
       #:configure-flags '("-DDATABASE_BACKEND=SQLITE") ; lightweight
       #:modules ((ice-9 textual-ports)
                  ,@%qt-build-system-modules)
       #:phases
       (modify-phases (@ (guix build qt-build-system) %standard-phases)
         (add-before 'configure 'add-definitions
           (lambda _
             (let ((out (assoc-ref %outputs "out"))
                   (mysql (assoc-ref %build-inputs "mysql"))
                   (pgsql (assoc-ref %build-inputs "postgresql")))
               (with-output-to-file "CMakeLists.txt.new"
                 (lambda _
                   (display
                    (string-append
                     "add_compile_definitions(\n"
                     "NIX_OUT=\"" out "\"\n"
                     ;; pin binaries for mysql backend
                     ")\n\n"))
                   (display
                    (call-with-input-file "CMakeLists.txt"
                      get-string-all))))
               (rename-file "CMakeLists.txt.new" "CMakeLists.txt"))
             #t)))))
    (home-page "https://kontact.kde.org/components/akonadi.html")
    (synopsis "Extensible cross-desktop storage service for PIM")
    (description "Akonadi is an extensible cross-desktop Personal Information
Management (PIM) storage service.  It provides a common framework for
applications to store and access mail, calendars, addressbooks, and other PIM
data.

This package contains the Akonadi PIM storage server and associated
programs.")
    (license license:fdl1.2+)))

(define-public akonadi-calendar
  (package
    (name "akonadi-calendar")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/akonadi-calendar-" version ".tar.xz"))
       (sha256
        (base32 "1550h08i8rjnbd9yrnhd9v3v68ingrag2bdxrbid62qvam0n5ihy"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("akonadi" ,akonadi)
       ("akonadi-contacts" ,akonadi-contacts)
       ("akonadi-mime" ,akonadi-mime)
       ("boost" ,boost)
       ("kcalendarcore" ,kcalendarcore)
       ("kcalutils" ,kcalutils)
       ("kcodecs" ,kcodecs)
       ("kcontacts" ,kcontacts)
       ("kdbusaddons" ,kdbusaddons)
       ("ki18n" ,ki18n)
       ("kiconthemes" ,kiconthemes)
       ("kidentitymanagement" ,kidentitymanagement)
       ("kio" ,kio)
       ("kitemmodels" ,kitemmodels)
       ("kmailtransport" ,kmailtransport)
       ("kmime" ,kmime)
       ("kpimtextedit" ,kpimtextedit)
       ("ksmtp" ,ksmtp)
       ("ktextwidgets" ,ktextwidgets)
       ("kwallet" ,kwallet)
       ("qtbase" ,qtbase)))
    (arguments
     `(#:tests? #f))  ;; TODO: 1/1 test fails
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/akonadi/html/")
    (synopsis "Library providing calendar helpers for Akonadi items")
    (description "This library manages calendar specific actions for
collection and item views.")
    (license license:lgpl2.0+)))

(define-public akonadi-contacts
  (package
    (name "akonadi-contacts")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/akonadi-contacts-" version ".tar.xz"))
       (sha256
        (base32 "1pw1s8c6dlcb103cw46p1ikvas3y8cwiwnfdny2jd3hr3rig4px9"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("akonadi" ,akonadi)
       ("boost" ,boost)
       ("kauth" ,kauth)
       ("kcodecs" ,kcodecs)
       ("kcompletion" ,kcompletion)
       ("kconfigwidgets" ,kconfigwidgets)
       ("kcontacts" ,kcontacts)
       ("kcoreaddons" ,kcoreaddons)
       ("kdbusaddons" ,kdbusaddons)
       ("ki18n" ,ki18n)
       ("kiconthemes" ,kiconthemes)
       ("kitemmodels" ,kitemmodels)
       ("kitemviews" ,kitemviews)
       ("kjobwidgets" ,kjobwidgets)
       ("kmime" ,kmime)
       ("kservice" ,kservice)
       ("ktextwidgets" ,ktextwidgets)
       ("kwidgetsaddons" ,kwidgetsaddons)
       ("kxmlgui" ,kxmlgui)
       ("prison" ,prison)
       ("kio" ,kio)
       ("qtbase" ,qtbase)
       ("solid" ,solid)
       ("sonnet" ,sonnet)))
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/akonadi/html/")
    (synopsis "Akonadi contacts access library")
    (description "Akonadi Contacts is a library that effectively bridges the
type-agnostic API of the Akonadi client libraries and the domain-specific
KContacts library.  It provides jobs, models and other helpers to make working
with contacts and addressbooks through Akonadi easier.

The library provides a complex dialog for editing contacts and several models
to list and filter contacts.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public akonadi-mime
  (package
    (name "akonadi-mime")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/akonadi-mime-" version ".tar.xz"))
       (sha256
        (base32 "03q3dnhzcgmgcqvijnwi4ikg0m1zad2l679bqnp051v27fvs4yg7"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)
       ("libxslt" ,libxslt) ;; xslt for generating interface descriptions
       ("shared-mime-info" ,shared-mime-info)))
    (inputs
     `(("akonadi" ,akonadi)
       ("boost", boost)
       ("kcodecs" ,kcodecs)
       ("kconfig" ,kconfig)
       ("kconfigwidgets" ,kconfigwidgets)
       ("kdbusaddons" ,kdbusaddons)
       ("ki18n" ,ki18n)
       ("kio" ,kio)
       ("kitemmodels" ,kitemmodels)
       ("kmime" ,kmime)
       ("kwidgetsaddons" ,kwidgetsaddons)
       ("kxmlgui" ,kxmlgui)
       ("qtbase" ,qtbase)))
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/akonadi/html/")
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'copy-desktop-file-early
           (lambda _
             (let ((plugins-dir "/tmp/.local/share/akonadi/plugins/serializer"))
               (mkdir-p plugins-dir)
               (copy-file "serializers/akonadi_serializer_mail.desktop"
                          (string-append plugins-dir "/akonadi_serializer_mail.desktop")))
             #t))
         (add-before 'check 'check-setup
           (lambda _
             (setenv "HOME" "/tmp")
             #t)))))
    (synopsis "Akonadi MIME handling library")
    (description "Akonadi Mime is a library that effectively bridges the
type-agnostic API of the Akonadi client libraries and the domain-specific
KMime library.  It provides jobs, models and other helpers to make working
with emails through Akonadi easier.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public akonadi-notes
  (package
    (name "akonadi-notes")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/akonadi-notes-" version ".tar.xz"))
       (sha256
        (base32 "0r8vh11bfjzhspb5kp2d0kcgwqd2m5qpxpamiajzjq910f51sw3w"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("akonadi" ,akonadi)
       ("kcodecs" ,kcodecs)
       ("ki18n" ,ki18n)
       ("kmime" ,kmime)
       ("qtbase" ,qtbase)))
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/akonadi/html/")
    (synopsis "Akonadi notes access library")
    (description "Akonadi Notes is a library that effectively bridges the
type-agnostic API of the Akonadi client libraries and the domain-specific
KMime library.  It provides a helper class for note attachments and for
wrapping notes into KMime::Message objects.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public akonadi-search
  (package
    (name "akonadi-search")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/akonadi-search-" version ".tar.xz"))
       (sha256
        (base32 "16qzs2cs4nxwrpwcdgwry95qn6wmg8s1p4w3qajx1ahkgwmsh11s"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("akonadi" ,akonadi)
       ("akonadi-mime" ,akonadi-mime)
       ("boost" ,boost)
       ("kcalendarcore" ,kcalendarcore)
       ("kcmutils" ,kcmutils)
       ("kcontacts" ,kcontacts)
       ("kcrash" ,kcrash)
       ("kdbusaddons" ,kdbusaddons)
       ("ki18n" ,ki18n)
       ("kio" ,kio)
       ("kitemmodels" ,kitemmodels)
       ("kmime" ,kmime)
       ("krunner" ,krunner)
       ("kwindowsystem" ,kwindowsystem)
       ("qtbase" ,qtbase)
       ("xapian" ,xapian)))
    (arguments
     `(#:tests? #f)) ;; TODO: needs dbus
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/akonadi/html/")
    (synopsis "Akonadi search library")
    (description "Xapian-based indexing and query infrastructure for
Akonadi.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public kalarmcal
  (package
    (name "kalarmcal")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/kalarmcal-" version ".tar.xz"))
       (sha256
        (base32 "0w9qsx2gqwny2v4fsj4awn814s9b7yrxvqrawlick3r2kp4x1sgn"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("akonadi", akonadi)
       ("boost" ,boost)
       ("kcalendarcore" ,kcalendarcore)
       ("kcalutils" ,kcalutils)
       ("kcompletion" ,kcompletion)
       ("kconfig" ,kconfig)
       ("kconfigwidgets" ,kconfigwidgets)
       ("kcoreaddons" ,kcoreaddons)
       ("kdbusaddons" ,kdbusaddons)
       ("kholidays" ,kholidays)
       ("ki18n" ,ki18n)
       ("kidentitymanagement" ,kidentitymanagement)
       ("kio" ,kio)
       ("kitemmodels" ,kitemmodels)
       ("kpimtextedit" ,kpimtextedit)
       ("ktextwidgets" ,ktextwidgets)
       ("kxmlgui" ,kxmlgui)
       ("qtbase" ,qtbase)))
    (arguments
     `(#:tests? #f)) ;; TODO: TZ setup
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/")
    (synopsis "Library for handling kalarm calendar data")
    (description "This library provides an API for KAlarm alarms.")
    (license  license:lgpl2.0+)))

(define-public kcalutils
  (package
    (name "kcalutils")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/kcalutils-" version ".tar.xz"))
       (sha256
        (base32 "1nlkik4qiciyh1slgpis3n5h9pks2ygdba9yq4s16nnmip4l45w2"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)
       ("libxml2" ,libxml2))) ;; xmllint required for tests
    (inputs
     `(("grantlee" ,grantlee)
       ("kcalendarcore" ,kcalendarcore)
       ("kcodecs" ,kcodecs)
       ("kconfig" ,kconfig)
       ("kconfigwidgets" ,kconfigwidgets)
       ("kcoreaddons" ,kcoreaddons)
       ("ki18n" ,ki18n)
       ("kiconthemes" ,kiconthemes)
       ("kidentitymanagement" ,kidentitymanagement)
       ("kpimtextedit" ,kpimtextedit)
       ("ktextwidgets" ,ktextwidgets)
       ("kwidgetsaddons" ,kwidgetsaddons)
       ("oxygen-icons" ,oxygen-icons) ; default icon set, required for tests
       ("qtbase" ,qtbase)))
    (arguments
     `(#:tests? #f)) ;; TODO: seem to pull in some wrong theme
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/")
    (synopsis "Library with utility functions for the handling of calendar
data")
    (description "This library provides a utility and user interface
functions for accessing calendar data using the kcalcore API.")
    (license  license:lgpl2.0+)))

(define-public kidentitymanagement
  (package
    (name "kidentitymanagement")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/kidentitymanagement-" version ".tar.xz"))
       (sha256
        (base32 "0dqz49sp5hq44590rrxav8688aqlzsww4q4n55ksfy13nk9i5mbf"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("kcodecs" ,kcodecs)
       ("kcompletion" ,kcompletion)
       ("kconfig" ,kconfig)
       ("kcoreaddons" ,kcoreaddons)
       ("kemoticons" ,kemoticons)
       ("kiconthemes" ,kiconthemes)
       ("kio" ,kio)
       ("kpimtextedit" ,kpimtextedit)
       ("ktextwidgets" ,ktextwidgets)
       ("kxmlgui" ,kxmlgui)
       ("qtbase" ,qtbase)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-before 'check 'set-home
           (lambda _
             (setenv "HOME" "/tmp/dummy-home") ;; FIXME: what is this?
             #t)))))
    (home-page "https://kontact.kde.org/")
    (synopsis "Library for shared identities between mail applications")
    (description "Library for shared identities between mail applications.")
    (license ;; GPL for programs, LGPL for libraries, FDL for documentation
     (list license:gpl2+ license:lgpl2.0+ license:fdl1.2+))))

(define-public kimap
  (package
    (name "kimap")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/kimap-" version ".tar.xz"))
       (sha256
        (base32 "0l8hb2z82jzbwr12lw5fismwk1a3ca4dk966p1fxg4bibck8vjj6"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("cyrus-sasl" ,cyrus-sasl)
       ("kcoreaddons" ,kcoreaddons)
       ("ki18n" ,ki18n)
       ("kio" ,kio)
       ("kmime" ,kmime)
       ("qtbase" ,qtbase)))
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/")
    (synopsis "Library for handling IMAP")
    (description "This library provides a job-based API for interacting with
an IMAP4rev1 server.  It manages connections, encryption and parameter quoting
and encoding, but otherwise provides quite a low-level interface to the
protocol.  This library does not implement an IMAP client; it merely makes it
easier to do so.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

(define-public kldap
  (package
    (name "kldap")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/kldap-" version ".tar.xz"))
       (sha256
        (base32 "1blbnj8av6h168g14gyphyd9sz87af773b1qglmbkv5pzbzaanxn"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)
       ("kdoctools" ,kdoctools)))
    (inputs
     `(("ki18n" ,ki18n)
       ("kio" ,kio)
       ("kwidgetsaddons" ,kwidgetsaddons)
       ("qtbase" ,qtbase)))
    (propagated-inputs
     `(("cyrus-sasl" ,cyrus-sasl)
       ("openldap" ,openldap)))
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/")
    (synopsis "Library for accessing LDAP")
    (description "This library provides an API for LDAP.")
    (license license:lgpl2.0+)))

(define-public kleopatra
  (package
    (name "kleopatra")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/kleopatra-" version ".tar.xz"))
       (sha256
        (base32 "1bqwxdl91s2nai871vvhkmcc3simbnvr2i5m6dnl327bplzqgfa4"))))
    (build-system qt-build-system)
    (native-inputs
     `(("dbus" ,dbus)
       ("extra-cmake-modules" ,extra-cmake-modules)
       ("gnupg" ,gnupg)  ;; TODO: Remove after gpgme uses fixed path
       ("kdoctools" ,kdoctools)))
    (inputs
     `(("boost" ,boost)
       ("gpgme" ,gpgme)
       ("kcmutils" ,kcmutils)
       ("kcodecs" ,kcodecs)
       ("kconfig" ,kconfig)
       ("kconfigwidgets" ,kconfigwidgets)
       ("kcoreaddons" ,kcoreaddons)
       ("kcrash" ,kcrash)
       ("kdbusaddons" ,kdbusaddons)
       ("ki18n" ,ki18n)
       ("kiconthemes" ,kiconthemes)
       ("kitemmodels" ,kitemmodels)
       ("kmime" ,kmime)
       ("knotifications" ,knotifications)
       ("ktextwidgets" ,ktextwidgets)
       ("kwidgetsaddons" ,kwidgetsaddons)
       ("kwindowsystem" ,kwindowsystem)
       ("kxmlgui" ,kxmlgui)
       ("libassuan" ,libassuan)
       ("libkleo" ,libkleo)
       ("oxygen-icons" ,oxygen-icons) ;; default icon set
       ("qgpgme" ,qgpgme)
       ("qtbase" ,qtbase)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (replace 'check
           (lambda _
             (invoke "dbus-launch" "ctest" ".")
             #t)))))
    (home-page "https://kde.org/applications/utilities/org.kde.kleopatra")
    (synopsis "Certificate Manager and Unified Crypto GUI")
    (description "Kleopatra is a certificate manager and a universal crypto
GUI.  It supports managing X.509 and OpenPGP certificates in the GpgSM keybox
and retrieving certificates from LDAP servers.")
    (license ;; GPL for programs, FDL for documentation
     (list license:gpl2+ license:fdl1.2+))))

(define-public kmailtransport
  (package
    (name "kmailtransport")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/kmailtransport-" version ".tar.xz"))
       (sha256
        (base32 "04jdnqxbp4382vjxh06rrvsigbrygqfkw0fvbbjnjymp585mgkr4"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)
       ("kdoctools" ,kdoctools)))
    (inputs
     `(("akonadi" ,akonadi)
       ("akonadi-mime" ,akonadi-mime)
       ("boost" ,boost)
       ("cyrus-sasl" ,cyrus-sasl)
       ("kcalendarcore" ,kcalendarcore)
       ("kcmutils" ,kcmutils)
       ("kcontacts" ,kcontacts)
       ("kdbusaddons" ,kdbusaddons)
       ("kconfigwidgets" ,kconfigwidgets)
       ("ki18n" ,ki18n)
       ("kitemmodels", kitemmodels)
       ("kio" ,kio)
       ("kmime" ,kmime)
       ("ksmtp" ,ksmtp)
       ("ktextwidgets" ,ktextwidgets)
       ("kwallet" ,kwallet)
       ("libkgapi" ,libkgapi)
       ("qtbase" ,qtbase)))
    (arguments
     `(#:tests? #f)) ;; TODO - 3/3 tests fail, require drkonqi
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/")
    (synopsis "Mail transport service library")
    (description " This library provides an API and support code for managing
mail transport.")
    (license license:lgpl2.0+)))

(define-public kmbox
  (package
    (name "kmbox")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/kmbox-" version ".tar.xz"))
       (sha256
        (base32 "13b5v1nx46k5ais3cms7yxrfi8p6xbljpkpg3f7v1asb6kshv7g2"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("kcodecs" ,kcodecs)
       ("kmime" ,kmime)
       ("qtbase" ,qtbase)))
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/")
    (synopsis "Library for handling mbox mailboxes")
    (description "A library for accessing mail storages in MBox format.")
    (license license:lgpl2.0+ )))

(define-public kmime
  (package
    (name "kmime")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/kmime-" version ".tar.xz"))
       (sha256
        (base32 "1pc00pwwrngsyr7ppvqwfgvcgy2wiqdbqxhv9xidn4dw9way2ng6"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("kcodecs" ,kcodecs)
       ("ki18n" ,ki18n)
       ("qtbase" ,qtbase)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-test-case
           (lambda _
             ;; This is curious: autotests/CMakeLists.txt sets LC_TIME=C, but
             ;; the Qt locale returns different. See kmime commit 3a9651d26a.
             (substitute* "autotests/dateformattertest.cpp"
               (("(Today|Yesterday) 12:34:56" line day)
                (string-append day " 12:34 PM")))
             #t)))))
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/")
    (synopsis "Library for handling MIME data")
    (description "A library for MIME handling.")
    (license license:lgpl2.0+)))

(define-public kontactinterface
  (package
    (name "kontactinterface")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/kontactinterface-" version ".tar.xz"))
       (sha256
        (base32 "1p0iw9i8cxh3jn7094wvxhlpc2sw52q8csfdgch1lf3dwhkpp0k7"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("kcoreaddons" ,kcoreaddons)
       ("ki18n" ,ki18n)
       ("kiconthemes" ,kiconthemes)
       ("kparts" ,kparts)
       ("kwindowsystem" ,kwindowsystem)
       ("kxmlgui" ,kxmlgui)
       ("qtbase" ,qtbase)))
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/")
    (synopsis "Kontact interface library")
    (description "Kontact Interface library.")
    (license license:lgpl2.0+)))

(define-public kpimtextedit
  (package
    (name "kpimtextedit")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/kpimtextedit-" version ".tar.xz"))
       (sha256
        (base32 "1as48j5qfpj9pqjck1615nlpk4a850m7xxcyl41gx8biww027zvm"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)
       ("qttools" ,qttools)))
    (inputs
     `(("grantlee" ,grantlee)
       ("kcodecs" ,kcodecs)
       ("kconfigwidgets" ,kconfigwidgets)
       ("kcoreaddons" ,kcoreaddons)
       ("kdesignerplugin" ,kdesignerplugin)
       ("kemoticons" ,kemoticons)
       ("ki18n" ,ki18n)
       ("kiconthemes" ,kiconthemes)
       ("kio" ,kio)
       ("ksyntaxhighlighting" ,ksyntaxhighlighting)
       ("ktextwidgets" ,ktextwidgets)
       ("kwidgetsaddons" ,kwidgetsaddons)
       ("kxmlgui" ,kxmlgui)
       ("qtbase" ,qtbase)
       ("qtspeech", qtspeech)
       ("sonnet" ,sonnet)))
    (arguments
     `(#:tests? #f)) ;; TODO - test suite hangs
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/")
    (synopsis "Library providing a textedit with PIM-specific features")
    (description "A library for PIM-specific text editing utilities.")
    (license ;; GPL for programs, LGPL for libraries, FDL for documentation
     (list license:gpl2+ license:lgpl2.0+ license:fdl1.2+))))

(define-public ksmtp
  (package
    (name "ksmtp")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/ksmtp-" version ".tar.xz"))
       (sha256
        (base32 "1pd8mma3xbq83jkn76gqinn6xh9imaji0jrg3qzysf5rvjl8kcqn"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("cyrus-sasl" ,cyrus-sasl)
       ("kcodecs" ,kcodecs)
       ("kconfig" ,kconfig)
       ("kcoreaddons" ,kcoreaddons)
       ("ki18n" ,ki18n)
       ("kio" ,kio)
       ("qtbase" ,qtbase)))
    (arguments
     `(#:tests? #f ;; TODO: does not find sasl mechs
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'Use-KDE_INSTALL_TARGETS_DEFAULT_ARGS-when-installing
           (lambda _
             (substitute* "src/CMakeLists.txt"
               (("^(install\\(.* )\\$\\{KF5_INSTALL_TARGETS_DEFAULT_ARGS\\}\\)"
                 _ prefix)
                (string-append prefix "${KDE_INSTALL_TARGETS_DEFAULT_ARGS})")))
             #t)))))
    (home-page "https://cgit.kde.org/ksmtp.git")
    (synopsis "Library for sending email through an SMTP server")
    (description "This library provides an API for handling SMTP
services.  SMTP (Simple Mail Transfer Protocol) is the most prevalent Internet
standard protocols for e-mail transmission.")
    (license license:lgpl2.0+)))

(define-public ktnef
  (package
    (name "ktnef")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/ktnef-" version ".tar.xz"))
       (sha256
        (base32 "0kgfhh46130hg1xq8km5gjzxa3b620j1zdrg54qivxa782smgbl6"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)))
    (inputs
     `(("kcalendarcore" ,kcalendarcore)
       ("kcalutils" ,kcalutils)
       ("kcodecs" ,kcodecs)
       ("kconfig" ,kconfig)
       ("kcontacts" ,kcontacts)
       ("kcoreaddons" ,kcoreaddons)
       ("ki18n" ,ki18n)
       ("qtbase" ,qtbase)))
    (home-page "https://api.kde.org/stable/kdepimlibs-apidocs/ktnef/html/")
    (synopsis "Viewer for mail attachments using TNEF format")
    (description "Viewer for mail attachments using TNEF format")
    (license license:lgpl2.0+)))

(define-public libkgapi
  (package
    (name "libkgapi")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/libkgapi-" version ".tar.xz"))
       (sha256
        (base32 "0z76b745n4hhjndrhv1w5acibia8x1frh78jx7bvxa72d8wphn08"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)
       ("qttools" ,qttools)))
    (inputs
     `(("cyrus-sasl" ,cyrus-sasl)
       ("ki18n" ,ki18n)
       ("kcontacts" ,kcontacts)
       ("kcalendarcore" ,kcalendarcore)
       ("kio" ,kio)
       ("kwallet" ,kwallet)
       ("kwindowsystem" ,kwindowsystem)
       ("qtbase" ,qtbase)
       ("qtdeclarative" ,qtdeclarative)
       ("qtwebchannel" ,qtwebchannel)
       ("qtwebengine" ,qtwebengine)))
    (arguments
     `(#:tests? #f)) ;; TODO 6/48 tests fail
    (home-page "https://cgit.kde.org/libkgapi.git")
    (synopsis "Library for accessing various Google services via their public
API")
    (description "@code{LibKGAPI} is a C++ library that implements APIs for
various Google services.")
    (license license:lgpl2.0+)))

(define-public libkleo
  (package
    (name "libkleo")
    (version "19.08.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://kde/stable/applications/" version
                           "/src/libkleo-" version ".tar.xz"))
       (sha256
        (base32 "0vjp07j102mi20c4q2fdvkjc0skb9q7msxp64n76wy3cciv346jz"))))
    (build-system qt-build-system)
    (native-inputs
     `(("extra-cmake-modules" ,extra-cmake-modules)
       ("kdoctools" ,kdoctools)
       ("qttools" ,qttools)))
    (inputs
     `(("boost" ,boost)
       ("gpgme" ,gpgme)
       ("kcodecs" ,kcodecs)
       ("kcompletion" ,kcompletion)
       ("kconfig" ,kconfig)
       ("kcoreaddons" ,kcoreaddons)
       ("kcrash" ,kcrash)
       ("ki18n" ,ki18n)
       ("kitemmodels" ,kitemmodels)
       ("kwidgetsaddons" ,kwidgetsaddons)
       ("kwindowsystem" ,kwindowsystem)
       ("kpimtextedit" ,kpimtextedit)
       ("qgpgme" ,qgpgme)
       ("qtbase" ,qtbase)))
    (home-page "https://cgit.kde.org/libkleo.git/")
    (synopsis "KDE PIM cryptographic library")
    (description "@code{libkleo} is a library for Kleopatra and other parts of
KDE using certificate-based crypto.")
    (license ;; GPL for programs, LGPL for libraries
     (list license:gpl2+ license:lgpl2.0+))))

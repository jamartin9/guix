;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2021 Ludovic Courtès <ludo@gnu.org>
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

(define-module (guix scripts shell)
  #:use-module (guix ui)
  #:use-module ((guix diagnostics) #:select (location))
  #:use-module (guix scripts environment)
  #:autoload   (guix scripts build) (show-build-options-help)
  #:autoload   (guix transformations) (show-transformation-options-help)
  #:use-module (guix scripts)
  #:use-module (guix packages)
  #:use-module (guix profiles)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-37)
  #:use-module (srfi srfi-71)
  #:use-module (ice-9 match)
  #:autoload   (ice-9 rdelim) (read-line)
  #:autoload   (guix base32) (bytevector->base32-string)
  #:autoload   (rnrs bytevectors) (string->utf8)
  #:autoload   (guix utils) (config-directory cache-directory)
  #:autoload   (guix describe) (current-channels)
  #:autoload   (guix channels) (channel-commit)
  #:autoload   (gcrypt hash) (sha256)
  #:use-module ((guix build utils) #:select (mkdir-p))
  #:use-module (guix cache)
  #:use-module ((ice-9 ftw) #:select (scandir))
  #:export (guix-shell))

(define (show-help)
  (display (G_ "Usage: guix shell [OPTION] PACKAGES... [-- COMMAND...]
Build an environment that includes PACKAGES and execute COMMAND or an
interactive shell in that environment.\n"))
  (newline)

  ;; These two options differ from 'guix environment'.
  (display (G_ "
  -D, --development      include the development inputs of the next package"))
  (display (G_ "
  -f, --file=FILE        create environment for the package that the code within
                         FILE evaluates to"))
  (display (G_ "
  -q                     inhibit loading of 'guix.scm' and 'manifest.scm'"))
  (display (G_ "
      --rebuild-cache    rebuild cached environment, if any"))

  (show-environment-options-help)
  (newline)
  (show-build-options-help)
  (newline)
  (show-transformation-options-help)
  (newline)
  (display (G_ "
  -h, --help             display this help and exit"))
  (display (G_ "
  -V, --version          display version information and exit"))
  (newline)
  (show-bug-report-information))

(define (tag-package-arg opts arg)
  "Return a two-element list with the form (TAG ARG) that tags ARG with either
'ad-hoc' in OPTS has the 'ad-hoc?' key set to #t, or 'inputs' otherwise."
  (if (assoc-ref opts 'ad-hoc?)
      `(ad-hoc-package ,arg)
      `(package ,arg)))

(define (ensure-ad-hoc alist)
  (if (assq-ref alist 'ad-hoc?)
      alist
      `((ad-hoc? . #t) ,@alist)))

(define (wrapped-option opt)
  "Wrap OPT, a SRFI-37 option, such that its processor always adds the
'ad-hoc?' flag to the resulting alist."
  (option (option-names opt)
          (option-required-arg? opt)
          (option-optional-arg? opt)
          (compose ensure-ad-hoc (option-processor opt))))

(define %options
  ;; Specification of the command-line options.
  (let ((to-remove '("ad-hoc" "inherit" "load" "help" "version")))
    (append
        (list (option '(#\h "help") #f #f
                      (lambda args
                        (show-help)
                        (exit 0)))
              (option '(#\V "version") #f #f
                      (lambda args
                        (show-version-and-exit "guix shell")))

              (option '(#\D "development") #f #f
                      (lambda (opt name arg result)
                        ;; Temporarily remove the 'ad-hoc?' flag from result.
                        ;; The next option will put it back thanks to
                        ;; 'wrapped-option'.
                        (alist-delete 'ad-hoc? result)))

              ;; For consistency with 'guix package', support '-f' rather than
              ;; '-l' like 'guix environment' does.
              (option '(#\f "file") #t #f
                      (lambda (opt name arg result)
                        (alist-cons 'load (tag-package-arg result arg)
                                    result)))
              (option '(#\q) #f #f
                      (lambda (opt name arg result)
                        (alist-cons 'explicit-loading? #t result)))
              (option '("rebuild-cache") #f #f
                      (lambda (opt name arg result)
                        (alist-cons 'rebuild-cache? #t result))))
        (filter-map (lambda (opt)
                      (and (not (any (lambda (name)
                                       (member name to-remove))
                                     (option-names opt)))
                           (wrapped-option opt)))
                    %environment-options))))

(define %default-options
  `((ad-hoc? . #t)                                ;always true
    ,@%environment-default-options))

(define (parse-args args)
  "Parse the list of command line arguments ARGS."
  (define (handle-argument arg result)
    (alist-cons 'package (tag-package-arg result arg)
                (ensure-ad-hoc result)))

  ;; The '--' token is used to separate the command to run from the rest of
  ;; the operands.
  (let ((args command (break (cut string=? "--" <>) args)))
    (let ((opts (parse-command-line args %options (list %default-options)
                                    #:argument-handler handle-argument)))
      (options-with-caching
       (auto-detect-manifest
        (match command
          (() opts)
          (("--") opts)
          (("--" command ...) (alist-cons 'exec command opts))))))))

(define (find-file-in-parent-directories candidates)
  "Find one of CANDIDATES in the current directory or one of its ancestors."
  (define start (getcwd))
  (define device (stat:dev (stat start)))

  (let loop ((directory start))
    (let ((stat (stat directory)))
      (and (= (stat:uid stat) (getuid))
           (= (stat:dev stat) device)
           (or (any (lambda (candidate)
                      (let ((candidate (string-append directory "/" candidate)))
                        (and (file-exists? candidate) candidate)))
                    candidates)
               (and (not (string=? directory "/"))
                    (loop (dirname directory)))))))) ;lexical ".." resolution

(define (authorized-directory-file)
  "Return the name of the file listing directories for which 'guix shell' may
automatically load 'guix.scm' or 'manifest.scm' files."
  (string-append (config-directory) "/shell-authorized-directories"))

(define (authorized-shell-directory? directory)
  "Return true if DIRECTORY is among the authorized directories for automatic
loading.  The list of authorized directories is read from
'authorized-directory-file'; each line must be either: an absolute file name,
a hash-prefixed comment, or a blank line."
  (catch 'system-error
    (lambda ()
      (call-with-input-file (authorized-directory-file)
        (lambda (port)
          (let loop ()
            (match (read-line port)
              ((? eof-object?) #f)
              ((= string-trim line)
               (cond ((string-prefix? "#" line)   ;comment
                      (loop))
                     ((string-prefix? "/" line)   ;absolute file name
                      (or (string=? line directory)
                          (loop)))
                     ((string-null? (string-trim-right line)) ;blank line
                      (loop))
                     (else                        ;bogus line
                      (let ((loc (location (port-filename port)
                                           (port-line port)
                                           (port-column port))))
                        (warning loc (G_ "ignoring invalid file name: '~a'~%")
                                 line))))))))))
    (const #f)))

(define (options-with-caching opts)
  "If OPTS contains exactly one 'load' or one 'manifest' key, automatically
add a 'profile' key (when a profile for that file is already in cache) or a
'gc-root' key (to add the profile to cache)."
  (define (single-file-for-caching opts)
    (let loop ((opts opts)
               (file #f))
      (match opts
        (() file)
        ((('package . _) . _) #f)
        ((('load . ('package candidate)) . rest)
         (and (not file) (loop rest candidate)))
        ((('manifest . candidate) . rest)
         (and (not file) (loop rest candidate)))
        ((('expression . _) . _) #f)
        ((_ . rest) (loop rest file)))))

  ;; Check whether there's a single 'load' or 'manifest' option.  When that is
  ;; the case, arrange to automatically cache the resulting profile.
  (match (single-file-for-caching opts)
    (#f opts)
    (file
     (let* ((root (profile-cached-gc-root file))
            (stat (and root (false-if-exception (lstat root)))))
       (if (and (not (assoc-ref opts 'rebuild-cache?))
                stat
                (<= (stat:mtime ((@ (guile) stat) file))
                    (stat:mtime stat)))
           (let ((now (current-time)))
             ;; Update the atime on ROOT to reflect usage.
             (utime root
                    now (stat:mtime stat) 0 (stat:mtimensec stat)
                    AT_SYMLINK_NOFOLLOW)
             (alist-cons 'profile root
                         (remove (match-lambda
                                   (('load . _) #t)
                                   (('manifest . _) #t)
                                   (_ #f))
                                 opts)))          ;load right away
           (if (and root (not (assq-ref opts 'gc-root)))
               (begin
                 (if stat
                     (delete-file root)
                     (mkdir-p (dirname root)))
                 (alist-cons 'gc-root root opts))
               opts))))))

(define (auto-detect-manifest opts)
  "If OPTS do not specify packages or a manifest, load a \"guix.scm\" or
\"manifest.scm\" file from the current directory or one of its ancestors.
Return the modified OPTS."
  (define (options-contain-payload? opts)
    (match opts
      (() #f)
      ((('package . _) . _) #t)
      ((('load . _) . _) #t)
      ((('manifest . _) . _) #t)
      ((('expression . _) . _) #t)
      ((_ . rest) (options-contain-payload? rest))))

  (define interactive?
    (not (assoc-ref opts 'exec)))

  (define disallow-implicit-load?
    (assoc-ref opts 'explicit-loading?))

  (if (or (not interactive?)
          disallow-implicit-load?
          (options-contain-payload? opts))
      opts
      (match (find-file-in-parent-directories '("manifest.scm" "guix.scm"))
        (#f
         (warning (G_ "no packages specified; creating an empty environment~%"))
         opts)
        (file
         (if (authorized-shell-directory? (dirname file))
             (begin
               (info (G_ "loading environment from '~a'...~%") file)
               (match (basename file)
                 ("guix.scm" (alist-cons 'load `(package ,file) opts))
                 ("manifest.scm" (alist-cons 'manifest file opts))))
             (begin
               (warning (G_ "not loading '~a' because not authorized to do so~%")
                        file)
               (display-hint (format #f (G_ "To allow automatic loading of
@file{~a} when running @command{guix shell}, you must explicitly authorize its
directory, like so:

@example
echo ~a >> ~a
@end example\n")
                                     file
                                     (dirname file)
                                     (authorized-directory-file)))
               opts))))))


;;;
;;; Profile cache.
;;;

(define %profile-cache-directory
  ;; Directory where profiles created by 'guix shell' alone (without extra
  ;; options) are cached.
  (make-parameter (string-append (cache-directory #:ensure? #f)
                                 "/profiles")))

(define (profile-cache-key file)
  "Return the cache key for the profile corresponding to FILE, a 'guix.scm' or
'manifest.scm' file, or #f if we lack channel information."
  (match (current-channels)
    (() #f)
    (((= channel-commit commits) ...)
     (let ((stat (stat file)))
       (bytevector->base32-string
        ;; Since FILE is not canonicalized, only include the device/inode
        ;; numbers.  XXX: In some rare cases involving Btrfs and NFS, this can
        ;; be insufficient: <https://lwn.net/Articles/866582/>.
        (sha256 (string->utf8
                 (string-append (string-join commits) ":"
                                (number->string (stat:dev stat)) ":"
                                (number->string (stat:ino stat))))))))))

(define (profile-cached-gc-root file)
  "Return the cached GC root for FILE, a 'guix.scm' or 'manifest.scm' file, or
#f if we lack information to cache it."
  (match (profile-cache-key file)
    (#f  #f)
    (key (string-append (%profile-cache-directory) "/" key))))


;;;
;;; One-time hints.
;;;

(define (hint-directory)
  "Return the directory name where previously given hints are recorded."
  (string-append (cache-directory #:ensure? #f) "/hints"))

(define (hint-file hint)
  "Return the name of the file that marks HINT as already printed."
  (string-append (hint-directory) "/" (symbol->string hint)))

(define (record-hint hint)
  "Mark HINT as already given."
  (let ((file (hint-file hint)))
    (mkdir-p (dirname file))
    (close-fdes (open-fdes file (logior O_CREAT O_WRONLY)))))

(define (hint-given? hint)
  "Return true if HINT was already given."
  (file-exists? (hint-file hint)))


(define-command (guix-shell . args)
  (category development)
  (synopsis "spawn one-off software environments")

  (define (cache-entries directory)
    (filter-map (match-lambda
                  ((or "." "..") #f)
                  (file (string-append directory "/" file)))
                (or (scandir directory) '())))

  (define* (entry-expiration file)
    ;; Return the time at which FILE, a cached profile, is considered expired.
    (match (false-if-exception (lstat file))
      (#f 0)                       ;FILE may have been deleted in the meantime
      (st (+ (stat:atime st) (* 60 60 24 7)))))

  (define opts
    (parse-args args))

  (define interactive?
    (not (assoc-ref opts 'exec)))

  (if (assoc-ref opts 'check?)
      (record-hint 'shell-check)
      (when (and interactive?
                 (not (hint-given? 'shell-check))
                 (not (assoc-ref opts 'container?))
                 (not (assoc-ref opts 'search-paths)))
        (display-hint (G_ "Consider passing the @option{--check} option once
to make sure your shell does not clobber environment variables."))) )

  (let ((result (guix-environment* opts)))
    (maybe-remove-expired-cache-entries (%profile-cache-directory)
                                        cache-entries
                                        #:entry-expiration entry-expiration)
    result))

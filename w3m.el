;;; -*- mode: Emacs-Lisp; coding: euc-japan -*-

;; Copyright (C) 2000,2001 TSUCHIYA Masatoshi <tsuchiya@pine.kuee.kyoto-u.ac.jp>

;; Authors: TSUCHIYA Masatoshi <tsuchiya@pine.kuee.kyoto-u.ac.jp>,
;;          Shun-ichi GOTO     <gotoh@taiyo.co.jp>,
;;          Satoru Takabayashi <satoru-t@is.aist-nara.ac.jp>,
;;          Hideyuki SHIRAI    <shirai@meadowy.org>,
;;          Keisuke Nishida    <kxn30@po.cwru.edu>,
;;          Yuuichi Teranishi  <teranisi@gohome.org>,
;;          Akihiro Arisawa    <ari@mbf.sphere.ne.jp>,
;;          Katsumi Yamaoka    <yamaoka@jpl.org>
;; Keywords: w3m, WWW, hypermedia

;; w3m.el is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; w3m.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with w3m.el; if not, write to the Free Software Foundation,
;; Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


;;; Commentary:

;; w3m.el is the interface program of w3m on Emacs.  For more detail
;; about w3m, see:
;;
;;    http://ei5nazha.yz.yamagata-u.ac.jp/~aito/w3m/


;;; How to install:

;; Please put this file to appropriate directory, and if you want
;; byte-compile it.  And add following lisp expressions to your
;; ~/.emacs.
;;
;;     (autoload 'w3m "w3m" "Interface for w3m on Emacs." t)


;;; Code:

(eval-and-compile
  (cond
   ((featurep 'xemacs)
    (require 'w3m-xmas))
   ((and (boundp 'emacs-major-version)
	 (>= emacs-major-version 21))
    (require 'w3m-e21))
   ((boundp 'MULE)
    (require 'w3m-om))))

(require 'thingatpt)
(require 'w3m-time)

;; this package using a few CL macros
(eval-when-compile
  (require 'cl))

;; Override the macro `dolist' which may have been defined in egg.el.
(eval-when-compile
  (unless (dolist (var nil t))
    (load "cl-macs" nil t)))

(put 'w3m-static-if 'lisp-indent-function 2)
(eval-and-compile
  (defmacro w3m-static-if (cond then &rest else)
    (if (eval cond) then (` (progn  (,@ else)))))
  (defmacro w3m-static-cond (&rest clauses)
    (while (and clauses
		(not (eval (car (car clauses)))))
      (setq clauses (cdr clauses)))
    (if clauses
	(cons 'progn (cdr (car clauses))))))

(w3m-static-cond ((fboundp 'find-coding-system))
		 ((fboundp 'coding-system-p)
		  (defsubst find-coding-system (obj)
		    "Return OBJ if it is a coding-system."
		    (if (coding-system-p obj) obj)))
		 (t
		  (require 'pces)))

;; Avoid byte-compile warnings.
(eval-when-compile
  (autoload 'w3m-fontify-forms "w3m-form")
  (autoload 'w3m-form-parse-region "w3m-form")
  (autoload 'rfc2368-parse-mailto-url "rfc2368")
  (autoload 'w3m-remove-image (if (featurep 'xemacs)
				  "w3m-xmas"
				"w3m-e21")))

(defconst emacs-w3m-version
  (eval-when-compile
    (let ((rev "$Revision: 1.126 $"))
      (and (string-match "\\.\\([0-9]+\\) \$$" rev)
	   (format "0.2.%d"
		   (- (string-to-number (match-string 1 rev)) 28)))))
  "Version number of this package.")

(defgroup w3m nil
  "w3m - the web browser of choice."
  :group 'hypermedia)

(defgroup w3m-face nil
  "Faces for w3m."
  :group 'w3m
  :prefix "w3m-")

(defcustom w3m-command "w3m"
  "*Name of the executable file of w3m."
  :group 'w3m
  :type 'string)

(defcustom w3m-fill-column -1
  "*Fill column of w3m.
Value is integer.
Positive value is for fixed column rendering.
Zero or negative value is for fitting w3m output with current frame
width using expression (+ (frame-width) VALUE)."
  :group 'w3m
  :type 'integer)

(defcustom w3m-mailto-url-function nil
  "*Mailto handling Function."
  :group 'w3m
  :type 'function)

(defcustom w3m-coding-system 'euc-japan
  "*Coding system for w3m."
  :group 'w3m
  :type 'coding-system)

(defcustom w3m-input-coding-system 'iso-2022-jp
  "*Coding system for w3m."
  :group 'w3m
  :type 'coding-system)

(defcustom w3m-output-coding-system 'euc-japan
  "*Coding system for w3m."
  :group 'w3m
  :type 'coding-system)

(defcustom w3m-use-cygdrive t
  "*If non-nil, use /cygdrive/ rule when expand-file-name."
  :group 'w3m
  :type 'boolean)

(defcustom w3m-profile-directory "~/.w3m"
  "*Directory of w3m profiles."
  :group 'w3m
  :type 'directory)

(defcustom w3m-default-save-directory "~/.w3m"
  "*Default directory for save file."
  :group 'w3m
  :type 'directory)

(defcustom w3m-delete-duplicated-empty-lines t
  "*Compactize page by deleting duplicated empty lines."
  :group 'w3m
  :type 'boolean)

(defcustom w3m-display-inline-image nil
  "*Display inline images."
  :group 'w3m
  :type 'boolean)

(defcustom w3m-icon-directory
  (if (fboundp 'locate-data-directory)
      (locate-data-directory "w3m")
    (let ((icons (expand-file-name "w3m/icons/"
				   data-directory)))
      (if (file-directory-p icons)
	  icons)))
  "*Icon directory for w3m (XEmacs or Emacs 21)."
  :group 'w3m
  :type 'directory)

(defun w3m-url-to-file-name (url)
  (if (string-match "^file:" url)
      (setq url (substring url (match-end 0))))
  (if (string-match "^\\(//\\|/cygdrive/\\)\\(.\\)/\\(.*\\)" url)
      (setq url (concat (match-string 2 url) ":/" (match-string 3 url))))
  url)

(defun w3m-expand-file-name-as-url (file &optional directory)
  ;; if filename is cygwin format,
  ;; then remove cygdrive prefix before expand-file-name
  (if directory
      (setq file (w3m-url-to-file-name file)))
  ;; expand to file scheme url considering Win32 environment
  (setq file (expand-file-name file directory))
  (if (string-match "^\\(.\\):\\(.*\\)" file)
      (if w3m-use-cygdrive
	  (concat "/cygdrive/" (match-string 1 file) (match-string 2 file))
	(concat "file://" (match-string 1 file) (match-string 2 file)))
    file))

(defcustom w3m-home-page
  (or (getenv "HTTP_HOME")
      (getenv "WWW_HOME")
      "http://namazu.org/~tsuchiya/emacs-w3m/")
  "*Home page of w3m.el."
  :group 'w3m
  :type 'string)

(defcustom w3m-arrived-file
  (expand-file-name ".arrived" w3m-profile-directory)
  "*File which has list of arrived URLs."
  :group 'w3m
  :type 'file)

(defcustom w3m-arrived-file-coding-system 'euc-japan
  "*Coding system for arrived file."
  :group 'w3m
  :type 'coding-system)

(defcustom w3m-keep-arrived-urls 500
  "*Arrived keep count of w3m."
  :group 'w3m
  :type 'integer)

(defcustom w3m-keep-cache-size 300
  "*Cache size of w3m."
  :group 'w3m
  :type 'integer)

(defface w3m-anchor-face
  '((((class color) (background light)) (:foreground "blue" :underline t))
    (((class color) (background dark)) (:foreground "cyan" :underline t))
    (t (:underline t)))
  "*Face to fontify anchors."
  :group 'w3m-face)

(defface w3m-arrived-anchor-face
  '((((class color) (background light)) (:foreground "navy" :underline t))
    (((class color) (background dark)) (:foreground "LightSkyBlue" :underline t))
    (t (:underline t)))
  "*Face to fontify anchors, if arrived."
  :group 'w3m-face)

(defface w3m-image-face
  '((((class color) (background light)) (:foreground "ForestGreen"))
    (((class color) (background dark)) (:foreground "PaleGreen"))
    (t (:underline t)))
  "*Face to fontify image alternate strings."
  :group 'w3m-face)

(defcustom w3m-mode-hook nil
  "*Hook run before w3m-mode called."
  :group 'w3m
  :type 'hook)

(defcustom w3m-fontify-before-hook nil
  "*Hook run before w3m-fontify called."
  :group 'w3m
  :type 'hook)

(defcustom w3m-fontify-after-hook nil
  "*Hook run after w3m-fontify called."
  :group 'w3m
  :type 'hook)

(defcustom w3m-async-exec nil
  "*If non-nil, w3m is executed an asynchronously process."
  :group 'w3m
  :type 'boolean)

(defcustom w3m-process-connection-type t
  "*Process connection type for w3m execution."
  :group 'w3m
  :type 'boolean)

(defcustom w3m-executable-type
  (if (eq system-type 'windows-nt)
      'cygwin ; xxx, cygwin on win32 by default
    'native)
  "*Executable binary type of w3m program.
Value is 'native or 'cygwin.
This value is mainly used for win32 environment.
In other environment, use 'native."
  :group 'w3m
  :type '(choice (const cygwin) (const native)))

;; FIXME: ������ mailcap ��Ŭ�ڤ��ɤ߹�������ꤹ��ɬ�פ�����
(defcustom w3m-content-type-alist
  (if (eq system-type 'windows-nt)
      '(("text/plain" "\\.\\(txt\\|tex\\|el\\)" nil)
	("text/html" "\\.s?html?$" w3m-w32-browser-with-fiber)
	("image/jpeg" "\\.jpe?g$" ("fiber.exe" file))
	("image/png" "\\.png$" ("fiber.exe" file))
	("image/gif" "\\gif$" ("fiber.exe" file))
	("image/tiff" "\\tif?f$" ("fiber.exe" file))
	("image/x-xwd" "\\.xwd$" ("fiber.exe" file))
	("image/x-xbm" "\\.xbm$" ("fiber.exe" file))
	("image/x-xpm" "\\.xpm$" ("fiber.exe" file))
	("image/x-bmp" "\\.bmp$" ("fiber.exe" file))
	("video/mpeg" "\\.mpe?g$" ("fiber.exe" file))
	("video/quicktime" "\\.mov$" ("fiber" file))
	("application/postscript" "\\.\\(ps\\|eps\\)$" ("fiber.exe" file))
	("application/pdf" "\\.pdf$" ("fiber.exe" file)))
    (cons
     (list "text/html" "\\.s?html?$"
	   (if (and (condition-case nil (require 'browse-url) (error nil))
		    (fboundp 'browse-url-netscape))
	       'browse-url-netscape
	     ("netscape" url)))
     '(("text/plain" "\\.\\(txt\\|tex\\|el\\)" nil)
       ("image/jpeg" "\\.jpe?g$" ("xv" file))
       ("image/png" "\\.png$" ("xv" file))
       ("image/gif" "\\gif$" ("xv" file))
       ("image/tiff" "\\tif?f$" ("xv" file))
       ("image/x-xwd" "\\.xwd$" ("xv" file))
       ("image/x-xbm" "\\.xbm$" ("xv" file))
       ("image/x-xpm" "\\.xpm$" ("xv" file))
       ("image/x-bmp" "\\.bmp$" ("xv" file))
       ("video/mpeg" "\\.mpe?g$" ("mpeg_play" file))
       ("video/quicktime" "\\.mov$" ("mpeg_play" file))
       ("application/postscript" "\\.\\(ps\\|eps\\)$" ("gv" file))
       ("application/pdf" "\\.pdf$" ("acroread" file)))))
  "Alist of file suffixes vs. content type."
  :group 'w3m
  :type '(repeat
	  (list
	   (string :tag "Type")
	   (string :tag "Regexp")
	   (choice
	    (const :tag "None" nil)
	    (cons :tag "Externai viewer"
		  (string :tag "Command")
		  (repeat :tag "Arguments"
			  (restricted-sexp :match-alternatives
					   (stringp 'file 'url))))
	    (function :tag "Function")))))

(defcustom w3m-charset-coding-system-alist
  (let ((rest
	 '((us-ascii      . raw-text)
	   (gb2312	  . cn-gb-2312)
	   (cn-gb	  . cn-gb-2312)
	   (iso-2022-jp-2 . iso-2022-7bit-ss2)
	   (iso-2022-jp-3 . iso-2022-7bit-ss2)
	   (tis-620	  . tis620)
	   (windows-874	  . tis-620)
	   (cp874	  . tis-620)
	   (x-ctext       . ctext)
	   (unknown       . undecided)
	   (x-unknown     . undecided)
	   (euc-jp        . euc-japan)
	   (shift-jis     . shift_jis)
	   (shift_jis     . shift_jis)
	   (sjis          . shift_jis)
	   (x-euc-jp      . euc-japan)
	   (x-shift-jis   . shift_jis)
	   (x-shift_jis   . shift_jis)
	   (x-sjis        . shift_jis)))
	(fn (if (fboundp 'find-coding-system)
		;; It might be unbound at run-time.
		'find-coding-system
	      'coding-system-p))
	dest)
    (while rest
      (or (funcall fn (car (car rest)))
	  (setq dest (cons (car rest) dest)))
      (setq rest (cdr rest)))
    dest)
  "Alist MIME CHARSET vs CODING-SYSTEM.
MIME CHARSET and CODING-SYSTEM must be symbol."
  :group 'w3m
  :type '(repeat (cons symbol coding-system)))

(defcustom w3m-horizontal-scroll-columns 10
  "*Column size to scroll horizontally."
  :group 'w3m
  :type 'integer)

(defcustom w3m-use-form nil
  "*Non-nil activates form extension. (EXPERIMENTAL)"
  :group 'w3m
  :type 'boolean
  :require 'w3m-form)
(when w3m-use-form (require 'w3m-form))

(defconst w3m-extended-characters-table
  '(("\xa0" . " ")
    ("\x80" . " ")))

(eval-and-compile
  (defconst w3m-entity-alist	  ; html character entities and values
    (eval-when-compile
      (let ((basic-entity-alist
	     '(("nbsp" . " ")
	       ("gt" . ">")
	       ("lt" . "<")
	       ("amp" . "&")
	       ("quot" . "\"")
	       ("apos" . "'")))
	    (latin1-entity
	     '(				;("nbsp" . 160)
	       ("iexcl" . 161) ("cent" . 162) ("pound" . 163)
	       ("curren" . 164) ("yen" . 165) ("brvbar" . 166) ("sect" . 167)
	       ("uml" . 168) ("copy" . 169) ("ordf" . 170) ("laquo" . 171)
	       ("not" . 172)  ("shy" . 173) ("reg" . 174) ("macr" . 175)
	       ("deg" . 176) ("plusmn" . 177) ("sup2" . 178) ("sup3" . 179)
	       ("acute" . 180) ("micro" . 181) ("para" . 182) ("middot" . 183)
	       ("cedil" . 184) ("sup1" . 185) ("ordm" . 186) ("raquo" . 187)
	       ("frac14" . 188) ("frac12" . 189) ("frac34" . 190) ("iquest" . 191)
	       ("Agrave" . 192) ("Aacute" . 193) ("Acirc" . 194) ("Atilde" . 195)
	       ("Auml" . 196) ("Aring" . 197) ("AElig" . 198) ("Ccedil" . 199)
	       ("Egrave" . 200) ("Eacute" . 201) ("Ecirc" . 202) ("Euml" . 203)
	       ("Igrave" . 204) ("Iacute" . 205) ("Icirc" . 206) ("Iuml" . 207)
	       ("ETH"  . 208) ("Ntilde" . 209) ("Ograve" . 210) ("Oacute" . 211)
	       ("Ocirc" . 212) ("Otilde" . 213) ("Ouml" . 214) ("times" . 215)
	       ("Oslash" . 216) ("Ugrave" . 217) ("Uacute" . 218) ("Ucirc" . 219)
	       ("Uuml" . 220) ("Yacute" . 221) ("THORN" . 222) ("szlig" . 223)
	       ("agrave" . 224) ("aacute" . 225) ("acirc" . 226) ("atilde" . 227)
	       ("auml" . 228) ("aring" . 229) ("aelig" . 230) ("ccedil" . 231)
	       ("egrave" . 232) ("eacute" . 233) ("ecirc" . 234) ("euml" . 235)
	       ("igrave" . 236) ("iacute" . 237) ("icirc" . 238) ("iuml" . 239)
	       ("eth" . 240) ("ntilde" . 241) ("ograve" . 242) ("oacute" . 243)
	       ("ocirc" . 244) ("otilde" . 245) ("ouml" . 246) ("divide" . 247)
	       ("oslash" . 248) ("ugrave" . 249) ("uacute" . 250) ("ucirc" . 251)
	       ("uuml" . 252) ("yacute" . 253) ("thorn" . 254) ("yuml" . 255))))
	(append basic-entity-alist
		(mapcar
		 (function
		  (lambda (entity)
		    (cons (car entity)
			  (char-to-string
			   (make-char
			    (w3m-static-if (boundp 'MULE) lc-ltn1 'latin-iso8859-1)
			    (cdr entity))))))
		 latin1-entity))))))
(defconst w3m-entity-regexp
  (eval-when-compile
    (format "&\\(%s\\|#[0-9]+\\);?"
	    (if (fboundp 'regexp-opt)
		(let ((fn (function regexp-opt)))
		  ;; Don't funcall directly for avoiding compile warning.
		  (funcall fn (mapcar (function car)
				      w3m-entity-alist)))
	      (mapconcat (lambda (s)
			   (regexp-quote (car s)))
			 w3m-entity-alist
			 "\\|")))))
(defvar w3m-entity-db nil)		; nil means un-initialized
(defconst w3m-entity-db-size 13)	; size of obarray

(defvar w3m-current-url nil "URL of this buffer.")
(defvar w3m-current-title nil "Title of this buffer.")
(defvar w3m-url-history nil "History of URL.")
(defvar w3m-url-yrotsih nil "FIXME: Sample of wrong symbol name.")
(make-variable-buffer-local 'w3m-current-url)
(make-variable-buffer-local 'w3m-current-title)
(make-variable-buffer-local 'w3m-url-history)
(make-variable-buffer-local 'w3m-url-yrotsih)

(defvar w3m-verbose t "Flag variable to control messages.")

(defvar w3m-cache-buffer nil)
(defvar w3m-cache-articles nil)
(defvar w3m-cache-hashtb nil)
(defvar w3m-input-url-history nil)

(defconst w3m-arrived-db-size 1023)
(defvar w3m-arrived-db nil)		; nil means un-initialized.
(defvar w3m-arrived-seq nil)
(defvar w3m-arrived-user-list nil)

(defvar w3m-process-message nil "Function to message status.")
(defvar w3m-process-user nil)
(defvar w3m-process-passwd nil)
(defvar w3m-process-user-counter 0)
(defvar w3m-process-temp-file nil)
(make-variable-buffer-local 'w3m-process-temp-file)

(defvar w3m-display-inline-image-status nil) ; 'on means image is displayed
(make-variable-buffer-local 'w3m-display-inline-image-status)

(defconst w3m-image-type-alist
  '(("image/jpeg" . jpeg)
    ("image/gif" . gif)
    ("image/png" . png)
    ("image/x-xbm" . xbm)
    ("image/x-xpm" . xpm))
  "An alist of CONTENT-TYPE and IMAGE-TYPE.")

(defconst w3m-toolbar-buttons
  '("back" "forward" "reload" "open" "home" "search" "image" "weather")
  "Toolbar button list for w3m.")

(defconst w3m-toolbar
  '([w3m-toolbar-back-icon w3m-view-previous-page
			   (nth 1 w3m-url-history) "���Υڡ��������"]
    [w3m-toolbar-forward-icon w3m-view-next-page w3m-url-yrotsih
			      "���Υڡ����˿ʤ�"]
    [w3m-toolbar-reload-icon w3m-reload-this-page t "�����Ф���ڡ�����⤦�����ɤ߹���"]
    [w3m-toolbar-open-icon w3m-goto-url t "URL �����Ϥ��ƥڡ����򳫤�"]
    [w3m-toolbar-home-icon
     (lambda () (interactive (w3m-goto-url w3m-home-page)))
     w3m-home-page "�ۡ���ڡ����إ�����"]
    [w3m-toolbar-search-icon w3m-search t "���󥿡��ͥåȾ�򸡺�"]
    [w3m-toolbar-image-icon w3m-toggle-inline-images t "������ɽ����ȥ��뤹��"]
    [w3m-toolbar-weather-icon w3m-weather t "ŷ��ͽ��򸫤�"]
    )
  "Toolbar definition for w3m.")

(defvar w3m-cid-retrieve-function-alist nil)

(eval-and-compile
  (condition-case nil
      :symbol-for-testing-whether-colon-keyword-is-available-or-not
    (void-variable
     (eval '(defconst :case-ignore ':case-ignore))
     (eval '(defconst :integer ':integer)))))

(defvar w3m-work-buffer-list nil)
(defconst w3m-work-buffer-name " *w3m-work*")

(defconst w3m-meta-content-type-charset-regexp
  (eval-when-compile
    (concat "<meta[ \t]+http-equiv=\"?Content-type\"?[ \t]+content=\"\\([^;]+\\)"
	    ";[ \t]*charset=\"?\\([^\"]+\\)\"?"
	    ">"))
  "Regexp used in parsing `<META HTTP-EQUIV=\"Content-Type\" content=\"...;charset=...\">
for a charset indication")

(defconst w3m-meta-charset-content-type-regexp
  (eval-when-compile
    (concat "<meta[ \t]+content=\"\\([^;]+\\)"
	    ";[ \t]*charset=\"?\\([^\"]+\\)\"?"
	    "[ \t]+http-equiv=\"?Content-type\"?>"))
  "Regexp used in parsing `<META content=\"...;charset=...\" HTTP-EQUIV=\"Content-Type\">
for a charset indication")

(eval-and-compile
  (defconst w3m-html-string-regexp
    "\\(\"\\(\\([^\"\\\\]+\\|\\\\.\\)+\\)\"\\|[^\"<> \t\r\f\n]*\\)"
    "Regexp used in parsing to detect string."))

(defconst w3m-command-arguments
  '("-T" "text/html" "-t" tab-width "-halfdump"
    "-cols" (if (< 0 w3m-fill-column)
		w3m-fill-column		; fixed columns
	      (+ (frame-width) (or w3m-fill-column -1)))) ; fit for frame
  "Arguments for execution of w3m.")

(defsubst w3m-anchor (&optional point)
  (get-text-property (or point (point)) 'w3m-href-anchor))

(defsubst w3m-image (&optional point)
  (get-text-property (or point (point)) 'w3m-image))
 
(defsubst w3m-action (&optional point)
  (get-text-property (or point (point)) 'w3m-action))

(defun w3m-message (&rest args)
  "Alternative function of `message' for w3m.el."
  (if w3m-verbose
      (apply (function message) args)
    (apply (function format) args)))

(defun w3m-sub-list (list n)
  "Make new list from LIST with top most N items.
If N is negative, last N items of LIST is returned."
  (if (< n 0)
      ;; N is negative, get items from tail of list
      (if (>= (- n) (length list))
	  (copy-sequence list)
	(nthcdr (+ (length list) n) (copy-sequence list)))
    ;; N is non-negative, get items from top of list
    (if (>= n (length list))
	(copy-sequence list)
      (nreverse (nthcdr (- (length list) n) (reverse list))))))

(defun w3m-load-list (file coding)
  "Load list from FILE with CODING and return list."
  (when (file-readable-p file)
    (with-temp-buffer
      (let ((file-coding-system-for-read coding)
	    (coding-system-for-read coding))
	(insert-file-contents file)
	(condition-case nil
	    (read (current-buffer))	; return value
	  (error nil))))))

(defun w3m-save-list (file coding list)
  "Save LIST into file with CODING."
  (when (and list (file-writable-p file))
    (with-temp-buffer
      (let ((file-coding-system coding)
	    (coding-system-for-write coding))
	(print list (current-buffer))
	(write-region (point-min) (point-max)	
	      file nil 'nomsg)))))

(defsubst w3m-arrived-p (url)
  "If URL has been arrived, return non-nil value.  Otherwise return nil."
  (intern-soft url w3m-arrived-db))

(defun w3m-arrived-last-modified (url)
  "If URL has been arrived, return its last modified time.  Otherwise return nil."
  (let ((v (intern-soft url w3m-arrived-db)))
    (and v (get v 'last-modified))))

(defsubst w3m-arrived-add (url &optional time)
  "Add URL to hash database of arrived URLs."
  (when (> (length url) 5) ;; ignore short
    (set-text-properties 0 (length url) nil url)
    (let ((ident (intern url w3m-arrived-db)))
      (put ident 'last-modified
	   (or time
	       (w3m-last-modified url)
	       (current-time)))
      (set ident (setq w3m-arrived-seq (1+ w3m-arrived-seq))))))

(defun w3m-arrived-setup ()
  "Load arrived url list from 'w3m-arrived-file' and setup hash database."
  (unless w3m-arrived-db
    (setq w3m-arrived-db (make-vector w3m-arrived-db-size nil)
	  w3m-arrived-seq 0)
    (let ((list (w3m-load-list w3m-arrived-file
			       w3m-arrived-file-coding-system)))
      (when (consp (car list))
	(dolist (url list)
	  (w3m-arrived-add (car url) (cdr url)))
	(unless w3m-input-url-history
	  (setq w3m-input-url-history (mapcar (function car) list)))))))

(defun w3m-arrived-shutdown ()
  "Save hash database of arrived URLs to 'w3m-arrived-file'."
  (when w3m-arrived-db
    (let (list)
      (mapatoms
       (lambda (sym)
	 (when sym
	   (push (cons (symbol-value sym)
		       (cons (symbol-name sym)
			     (get sym 'last-modified)))
		 list)))
       w3m-arrived-db)
      (w3m-save-list w3m-arrived-file
		     w3m-arrived-file-coding-system
		     (mapcar (function cdr)
			     (sort list
				   (lambda (a b) (< (car a) (car b)))))))
    (setq w3m-arrived-db nil)))
(add-hook 'kill-emacs-hook 'w3m-arrived-shutdown)

(defun w3m-arrived-store-position (url &optional point window-start)
  (when (stringp url)
    (let ((ident (intern-soft url w3m-arrived-db)))
      (when ident
	(put ident 'window-start (or window-start (window-start)))
	(put ident 'point (or point (point)))))))

(defun w3m-arrived-restore-position (url)
  (let* ((ident (intern-soft url w3m-arrived-db))
	 (start (get ident 'window-start))
	 (point (get ident 'point)))
    (when (and ident start point)
      (set-window-start nil start)
      (goto-char point))))


;;; Working buffers:
(defsubst w3m-get-buffer-create (name)
  "Return the buffer named NAME, or create such a buffer and return it."
  (or (get-buffer name)
      (let ((buf (get-buffer-create name)))
	(setq w3m-work-buffer-list (cons buf w3m-work-buffer-list))
	(buffer-disable-undo buf)
	buf)))

(put 'w3m-with-work-buffer 'lisp-indent-function 0)
(put 'w3m-with-work-buffer 'edebug-form-spec '(body))
(defmacro w3m-with-work-buffer (&rest body)
  "Execute the forms in BODY with working buffer as the current buffer."
  (` (with-current-buffer
	 (w3m-get-buffer-create w3m-work-buffer-name)
       (,@ body))))

(defun w3m-kill-all-buffer ()
  "Kill all working buffer."
  (dolist (buf w3m-work-buffer-list)
    (when (buffer-live-p buf)
      (kill-buffer buf)))
  (setq w3m-work-buffer-list nil))

(defun w3m-url-encode-string (str &optional coding)
  (apply (function concat)
	 (mapcar
	  (lambda (ch)
	    (cond
	     ((string-match "[-a-zA-Z0-9_:/]" (char-to-string ch)) ; xxx?
	      (char-to-string ch))	; printable
	     (t
	      (format "%%%02X" ch))))	; escape
	  ;; Coerce a string to a list of chars.
	  (append (encode-coding-string str (or coding 'iso-2022-jp))
		  nil))))

(put 'w3m-parse-attributes 'lisp-indent-function '1)
(put 'w3m-parse-attributes 'edebug-form-spec '(form))
(defmacro w3m-parse-attributes (attributes &rest form)
  (` (let ((,@ (mapcar
		(lambda (attr)
		  (if (listp attr) (car attr) attr))
		attributes)))
       (while
	   (cond
	    (,@ (mapcar
		 (lambda (attr)
		   (or (symbolp attr)
		       (and (listp attr)
			    (<= (length attr) 2)
			    (symbolp (car attr)))
		       (error "Internal error, type mismatch."))
		   (let ((sexp (quote
				(or (match-string 2)
				    (match-string 1)))))
		     (when (listp attr)
		       (cond
			((eq (nth 1 attr) :case-ignore)
			 (setq sexp
			       (quote
				(downcase
				 (or (match-string 2)
				     (match-string 1))))))
			((eq (nth 1 attr) :integer)
			 (setq sexp
			       (quote
				(string-to-number
				 (or (match-string 2)
				     (match-string 1))))))
			((nth 1 attr)
			 (error "Internal error, unknown modifier.")))
		       (setq attr (car attr)))
		     (` ((looking-at
			  (, (format "%s=%s"
				     (symbol-name attr)
				     w3m-html-string-regexp)))
			 (setq (, attr) (, sexp))))))
		 attributes))
	    ((looking-at
	      (, (concat "[A-z]*=" w3m-html-string-regexp))))
	    ((looking-at "[^<> \t\r\f\n]+")))
	 (goto-char (match-end 0))
	 (skip-chars-forward " \t\r\f\n"))
       (skip-chars-forward "^>")
       (,@ form))))


;;; HTML character entity handling:

(defun w3m-entity-db-setup ()
  ;; initialise entity database (obarray)
  (setq w3m-entity-db (make-vector w3m-entity-db-size 0))
  (dolist (elem w3m-entity-alist)
    (set (intern (car elem) w3m-entity-db)
	 (cdr elem))))

(defsubst w3m-entity-value (name)
  ;; initialise if need
  (if (null w3m-entity-db)
      (w3m-entity-db-setup))
    ;; return value of specified entity, or empty string for unknown entity.
    (or (symbol-value (intern-soft name w3m-entity-db))
	(if (not (char-equal (string-to-char name) ?#))
	    (concat "&" name)		; unknown entity
	  ;; case of immediate character (accept only 0x20 .. 0x7e)
	  (let ((char (string-to-int (substring name 1)))
		sym)
	    ;; make character's representation with learning
	    (set (setq sym (intern name w3m-entity-db))
		 (if (or (< char 32) (< 127 char))
		     "~"		; un-supported character
		   (char-to-string char)))))))

(defun w3m-fontify-bold ()
  "Fontify bold characters in this buffer which contains half-dumped data."
  (goto-char (point-min))
  (while (search-forward "<b>" nil t)
    (let ((start (match-beginning 0)))
      (delete-region start (match-end 0))
      (when (search-forward "</b>" nil t)
	(delete-region (match-beginning 0) (match-end 0))
	(put-text-property start (match-beginning 0) 'face 'bold)))))

(defun w3m-fontify-underline ()
  "Fontify underline characters in this buffer which contains half-dumped data."
  (goto-char (point-min))
  (while (search-forward "<u>" nil t)
    (let ((start (match-beginning 0)))
      (delete-region start (match-end 0))
      (when (search-forward "</u>" nil t)
	(delete-region (match-beginning 0) (match-end 0))
	(put-text-property start (match-beginning 0) 'face 'underline)))))

(defsubst w3m-decode-anchor-string (str)
  ;; FIXME: This is a quite ad-hoc function to process encoded URL
  ;;        string.  More discussion about timing &-sequence decode is
  ;;        required.  See [emacs-w3m:00150] for detail.
  (let ((start 0) (buf))
    (while (string-match "&amp;" str start)
      (setq buf (cons "&" (cons (substring str start (match-beginning 0)) buf))
	    start (match-end 0)))
    (apply (function concat)
	   (nreverse (cons (substring str start) buf)))))

(defun w3m-fontify-anchors ()
  "Fontify anchor tags in this buffer which contains half-dumped data."
  ;; Delete excessive `hseq' elements of anchor tags.
  (goto-char (point-min))
  (while (re-search-forward "<a\\( hseq=\"[-0-9]+\"\\)" nil t)
    (delete-region (match-beginning 1) (match-end 1)))
  ;; Re-ordering anchor elements.
  (goto-char (point-min))
  (let (href)
    (while (re-search-forward "<a\\([ \t\n]\\)[^>]+[ \t\n]href=\\([\"']?[^\"' >]*[\"']?\\)" nil t)
      (setq href (buffer-substring (match-beginning 2) (match-end 2)))
      (delete-region (match-beginning 2) (match-end 2))
      (goto-char (match-beginning 1))
      (insert " href=" href)))
  ;; Fontify anchor tags.
  (goto-char (point-min))
  (while (re-search-forward
	  "<a\\([ \t\n]+href=[\"']?\\([^\"' >]*\\)[\"']?\\)?\\([ \t\n]+name=\"?\\([^\" >]*\\)\"?\\)?[^>]*>"
	  nil t)
    (let ((url (match-string 2))
	  (tag (match-string 4))
	  (start (match-beginning 0))
	  (end))
      (delete-region start (match-end 0))
      (cond (url
	     (when (search-forward "</a>" nil t)
	       (delete-region (setq end (match-beginning 0)) (match-end 0))
	       (setq url (w3m-expand-url (w3m-decode-anchor-string url) w3m-current-url))
	       (put-text-property start end 'face
				  (if (w3m-arrived-p url)
				      'w3m-arrived-anchor-face
				    'w3m-anchor-face))
	       (put-text-property start end 'w3m-href-anchor url)
	       (put-text-property start end 'mouse-face 'highlight))
	     (when tag
	       (put-text-property start end 'w3m-name-anchor tag)))
	    (tag
	     (when (re-search-forward "<\\|\n" nil t)
	       (setq end (match-beginning 0))
	       (put-text-property start end 'w3m-name-anchor tag)))))))

(defun w3m-image-type (content-type)
  "Return image type which corresponds to CONTENT-TYPE."
  (cdr (assoc content-type w3m-image-type-alist)))

(unless (fboundp 'w3m-create-image)
  (defun w3m-create-image (url &optional no-cache)))
(unless (fboundp 'w3m-insert-image)
  (defun w3m-insert-image (beg end image)))
(unless (fboundp 'w3m-image-type-available-p)
  (defun w3m-image-type-available-p (image-type)
    "Return non-nil if an image with IMAGE-TYPE can be displayed inline."
    nil))
(unless (fboundp 'w3m-setup-toolbar)
  (defun w3m-setup-toolbar ()))

(defun w3m-fontify-images ()
  "Fontify image alternate strings in this buffer which contains half-dumped data."
  (goto-char (point-min))
  (while (re-search-forward "<\\(img_alt\\) src=\"\\([^\"]*\\)\">" nil t)
    (let ((src (match-string 2))
	  (upper (string= (match-string 1) "IMG_ALT"))
	  (start (match-beginning 0))
	  (end))
      (delete-region start (match-end 0))
      (setq src (w3m-expand-url src w3m-current-url))
      (when (search-forward "</img_alt>" nil t)
	(delete-region (setq end (match-beginning 0)) (match-end 0))
	(put-text-property start end 'face 'w3m-image-face)
	(put-text-property start end 'w3m-image src)
	(if upper (put-text-property start end 'w3m-image-redundant t))
	(put-text-property start end 'mouse-face 'highlight)))))

(defun w3m-toggle-inline-images (&optional force no-cache)
  "Toggle displaying of inline images on current buffer.
If optional argument FORCE is non-nil, displaying is forced.
If second optional argument NO-CACHE is non-nil, cache is not used."
  (interactive "P")
  (unless (and force (eq w3m-display-inline-image-status 'on))
    (let ((cur-point (point)) 
	  (buffer-read-only)
	  point end url image)
      (if (or force (eq w3m-display-inline-image-status 'off))
	  (save-excursion
	    (goto-char (point-min))
	    (while (if (get-text-property (point) 'w3m-image)
		       (setq point (point))
		     (setq point (next-single-property-change (point)
							      'w3m-image)))
	      (setq end (or (next-single-property-change point 'w3m-image)
			    (point-max)))
	      (goto-char end)
	      (if (setq url (w3m-image point))
		  (setq url (w3m-expand-url url w3m-current-url)))
	      (if (get-text-property point 'w3m-image-redundant)
		  (progn
		    ;; Insert dummy string instead of redundant image.
		    (setq image
			  (make-string
			   (string-width (buffer-substring point end))
			   ? ))
		    (put-text-property point end 'invisible t)
		    (setq point (point))
		    (insert image)
		    (put-text-property point (point) 'w3m-image-dummy t)
		    (put-text-property point (point) 'w3m-image "dummy"))
		(save-excursion
		  (goto-char cur-point)
		  (when (and url
			     (setq image (w3m-create-image url no-cache)))
		    (w3m-insert-image point end image)
		    ;; Redisplay
		    (sit-for 0)))))
	    (setq w3m-display-inline-image-status 'on))
	(save-excursion
	  (goto-char (point-min))
	  (while (if (get-text-property (point) 'w3m-image)
		     (setq point (point))
		   (setq point (next-single-property-change (point)
							    'w3m-image)))
	    (setq end (or (next-single-property-change point 'w3m-image)
			  (point-max)))
	    (goto-char end)
	    ;; IMAGE-ALT-STRING DUMMY-STRING
	    ;; <--------w3m-image---------->
	    ;; <---redundant--><---dummy--->
	    ;; <---invisible-->
	    (cond
	     ((get-text-property point 'w3m-image-redundant)
	      ;; Remove invisible property.
	      (remove-text-properties point end '(invisible)))
	     ((get-text-property point 'w3m-image-dummy)
	      ;; Remove dummy string.
	      (delete-region point end))
	     (t (w3m-remove-image point end))))
	  (setq w3m-display-inline-image-status 'off))))))

(defun w3m-fontify ()
  "Fontify this buffer."
  (let ((case-fold-search t)
	(buffer-read-only))
    (run-hooks 'w3m-fontify-before-hook)
    ;; Delete <?xml ... ?> tag
    (goto-char (point-min))
    (if (search-forward "<?xml" nil t)
	(let ((start (match-beginning 0)))
	  (search-forward "?>" nil t)
	  (delete-region start (match-end 0))))
    ;; Delete extra title tag.
    (goto-char (point-min))
    (let (start)
      (and (search-forward "<title>" nil t)
	   (setq start (match-beginning 0))
	   (search-forward "</title>" nil t)
	   (delete-region start (match-end 0))))
    (w3m-fontify-bold)
    (w3m-fontify-underline)
    (w3m-fontify-anchors)
    (if w3m-use-form
	(w3m-fontify-forms))
    (w3m-fontify-images)
    ;; Remove other markups.
    (goto-char (point-min))
    (while (re-search-forward "</?[A-z_][^>]*>" nil t)
      (delete-region (match-beginning 0) (match-end 0)))
    ;; Decode escaped characters (entities).
    (goto-char (point-min))
    (let (prop)
      (while (re-search-forward w3m-entity-regexp nil t)
	(setq prop (text-properties-at (match-beginning 0)))
	(replace-match (w3m-entity-value (match-string 1)) nil t)
	(if prop (add-text-properties (match-beginning 0) (point) prop))))
    (goto-char (point-min))
    (if w3m-delete-duplicated-empty-lines
	(while (re-search-forward "^[ \t]*\n\\([ \t]*\n\\)+" nil t)
	  (replace-match "\n" nil t)))
    (run-hooks 'w3m-fontify-after-hook)))

;;

(defun w3m-refontify-anchor (&optional buff)
  "Change face 'w3m-anchor-face to 'w3m-arrived-anchor-face."
  (save-excursion
    (and buff (set-buffer buff))
    (when (and (eq major-mode 'w3m-mode)
	       (eq (get-text-property (point) 'face) 'w3m-anchor-face))
      (let* ((start)
	     (end (next-single-property-change (point) 'face))
	     (buffer-read-only))
	(when (and end
		   (setq start (previous-single-property-change end 'face)))
	  (put-text-property start end 'face 'w3m-arrived-anchor-face))
	(set-buffer-modified-p nil)))))

(defun w3m-input-url (&optional prompt default)
  "Read a URL from the minibuffer, prompting with string PROMPT."
  (let (url candidates)
    (w3m-arrived-setup)
    (mapatoms (lambda (x)
		(setq candidates (cons (cons (symbol-name x) x) candidates)))
	      w3m-arrived-db)
    (setq default (or default (thing-at-point 'url)))
    (setq url (completing-read (or prompt
				   (if default
				       "URL: "
				     (format "URL (default %s): " w3m-home-page)))
			       candidates nil nil default
			       'w3m-input-url-history))
    (if (string= "" url) (setq url w3m-home-page))
    ;; remove duplication
    (setq w3m-input-url-history (cons url (delete url w3m-input-url-history)))
    ;; return value
    url))


;;; Cache:
(defun w3m-cache-setup ()
  "Initialise cache variables."
  (unless (and (bufferp w3m-cache-buffer)
	       (buffer-live-p w3m-cache-buffer))
    (save-excursion
      (set-buffer (w3m-get-buffer-create " *w3m cache*"))
      (buffer-disable-undo)
      (set-buffer-multibyte nil)
      (setq buffer-read-only t
	    w3m-cache-buffer (current-buffer)
	    w3m-cache-hashtb (make-vector 1021 0)))))

(defun w3m-cache-shutdown ()
  "Clear all cache variables and buffers."
  (when (buffer-live-p w3m-cache-buffer)
    (kill-buffer w3m-cache-buffer))
  (setq w3m-cache-hashtb nil
	w3m-cache-articles nil))

(defun w3m-cache-header (url header)
  "Store up URL's HEADER in cache."
  (w3m-cache-setup)
  (set (intern url w3m-cache-hashtb) header))

(defun w3m-cache-request-header (url)
  "Return the URL's header string, when it is stored in cache."
  (w3m-cache-setup)
  (let ((ident (intern url w3m-cache-hashtb)))
    (and (boundp ident)
	 (symbol-value ident))))

(defun w3m-cache-remove-oldest ()
  (save-excursion
    (set-buffer w3m-cache-buffer)
    (goto-char (point-min))
    (unless (zerop (buffer-size))
      (let ((ident (get-text-property (point) 'w3m-cache))
	    buffer-read-only)
	;; Remove the ident from the list of articles.
	(when ident
	  (setq w3m-cache-articles (delq ident w3m-cache-articles)))
	;; Delete the article itself.
	(delete-region (point)
		       (next-single-property-change
			(1+ (point)) 'w3m-cache nil (point-max)))))))

(defun w3m-cache-remove (url)
  "Remove URL's data from the cache."
  (w3m-cache-setup)
  (let ((ident (intern url w3m-cache-hashtb))
	beg end)
    (when (memq ident w3m-cache-articles)
      ;; It was in the cache.
      (save-excursion
	(set-buffer w3m-cache-buffer)
	(let (buffer-read-only)
	  (when (setq beg (text-property-any
			   (point-min) (point-max) 'w3m-cache ident))
	    ;; Find the end (i. e., the beginning of the next article).
	    (setq end (next-single-property-change
		       (1+ beg) 'w3m-cache (current-buffer) (point-max)))
	    (delete-region beg end)))
	(setq w3m-cache-articles (delq ident w3m-cache-articles))))))

(defun w3m-cache-contents (url buffer)
  "Store URL's contents which is placed in the BUFFER.
Return symbol to identify its cache data."
  (w3m-cache-setup)
  (let ((ident (intern url w3m-cache-hashtb)))
    (w3m-cache-remove url)
    ;; Remove the oldest article, if necessary.
    (and (numberp w3m-keep-cache-size)
	 (>= (length w3m-cache-articles) w3m-keep-cache-size)
	 (w3m-cache-remove-oldest))
    ;; Insert the new article.
    (save-excursion
      (set-buffer w3m-cache-buffer)
      (let (buffer-read-only)
	(goto-char (point-max))
	(unless (bolp) (insert "\n"))
	(let ((b (point)))
	  (insert-buffer-substring buffer)
	  ;; Tag the beginning of the article with the ident.
	  (when (> (point-max) b)
	    (put-text-property b (1+ b) 'w3m-cache ident)
	    (setq w3m-cache-articles (cons ident w3m-cache-articles))
	    ident))))))

(defun w3m-cache-request-contents (url &optional buffer)
  "Insert URL's data to the BUFFER.
If URL's data is found in the cache, return t.  Otherwise return nil.
When BUFFER is nil, all data will be inserted in the current buffer."
  (w3m-cache-setup)
  (let ((ident (intern url w3m-cache-hashtb)))
    (when (memq ident w3m-cache-articles)
      ;; It was in the cache.
      (let (beg end type charset)
	(save-excursion
	  (set-buffer w3m-cache-buffer)
	  (if (setq beg (text-property-any
			 (point-min) (point-max) 'w3m-cache ident))
	      ;; Find the end (i. e., the beginning of the next article).
	      (setq end (next-single-property-change
			 (1+ beg) 'w3m-cache (current-buffer) (point-max)))
	    ;; It wasn't in the cache after all.
	    (setq w3m-cache-articles (delq ident w3m-cache-articles))))
	(and beg
	     end
	     (save-excursion
	       (when buffer
		 (set-buffer buffer))
	       (let (buffer-read-only)
		 (insert-buffer-substring w3m-cache-buffer beg end))
	       t))))))


;;; Handle process:
(defun w3m-exec-process (&rest args)
  "Run w3m-command and return process exit status."
  (save-excursion
    (let ((coding-system-for-read 'binary)
	  (coding-system-for-write w3m-coding-system)
	  (default-process-coding-system (cons 'binary w3m-coding-system))
	  (process-connection-type w3m-process-connection-type))
      (if w3m-async-exec
	  ;; start-process
	  (let ((w3m-process-user)
		(w3m-process-passwd)
		(w3m-process-user-counter 2)
		(proc (apply 'start-process w3m-command (current-buffer) w3m-command args)))
	    (set-process-filter proc 'w3m-exec-filter)
	    (set-process-sentinel proc (lambda (proc event) nil))
	    (process-kill-without-query proc)
	    (while (eq (process-status proc) 'run)
	      (if (functionp w3m-process-message)
		  (funcall w3m-process-message))
	      (sleep-for 0.2)
	      (discard-input))
	    (prog1 (process-exit-status proc)
	      (delete-process proc) ;; Clean up resources of process.
	      (and w3m-current-url
		   w3m-process-user
		   (setq w3m-arrived-user-list
			 (cons
			  (cons w3m-current-url
				(list w3m-process-user w3m-process-passwd))
			  (delete (assoc w3m-current-url w3m-arrived-user-list)
				  w3m-arrived-user-list))))))
	;; call-process
	(apply 'call-process w3m-command nil t nil args)))))

(defun w3m-exec-get-user (url)
  (if (= w3m-process-user-counter 0)
      nil
    (catch 'get
      (dolist (elem w3m-arrived-user-list nil)
	(when (string-match (concat "^" (regexp-quote (car elem))) url)
	  (setq w3m-process-user-counter (1- w3m-process-user-counter))
	  (throw 'get (cdr elem)))))))

(defun w3m-read-file-name (&optional prompt dir default existing initial)
  (let* ((default (and default (file-name-nondirectory default)))
	 (prompt (or prompt
		     (if default (format "Save to (%s): " default) "Save to: ")))
	 (initial (or initial default))
	 (dir (file-name-as-directory (or dir w3m-default-save-directory)))
	 (default-directory dir)
	 (file (read-file-name prompt dir default existing initial)))
    (if (not (file-directory-p file))
	(setq w3m-default-save-directory
	      (or (file-name-directory file) w3m-default-save-directory))
      (setq w3m-default-save-directory file)
      (if default
	  (setq file (expand-file-name default file))))
    (expand-file-name file)))

(defun w3m-exec-filter (process string)
  (if (buffer-name (process-buffer process))
      (with-current-buffer (process-buffer process)
	(let ((buffer-read-only nil)
	      (case-fold-search nil))
	  (goto-char (process-mark process))
	  (insert string)
	  (set-marker (process-mark process) (point))
	  (unless (string= "" string)
	    (goto-char (point-min))
	    (cond
	     ((and (looking-at
		    "\\(\nWrong username or password\n\\)?Username: Password: ")
		   (= (match-end 0) (point-max)))
	      (setq w3m-process-passwd
		    (or (nth 1 (w3m-exec-get-user w3m-current-url))
			(read-passwd "Password: ")))
	      (condition-case nil
		  (progn
		    (process-send-string process
					 (concat w3m-process-passwd "\n"))
		    (delete-region (point-min) (point-max)))
		(error nil)))
	     ((and (looking-at
		    "\\(\nWrong username or password\n\\)?Username: ")
		   (= (match-end 0) (point-max)))
	      (setq w3m-process-user
		    (or (nth 0 (w3m-exec-get-user w3m-current-url))
			(read-from-minibuffer "Username: ")))
	      (condition-case nil
		  (process-send-string process
				       (concat w3m-process-user "\n"))
		(error nil)))))))))


;;; Handle character sets:
(defun w3m-charset-to-coding-system (charset)
  "Return coding-system corresponding with CHARSET.
CHARSET is a symbol whose name is MIME charset.
This function is imported from mcharset.el."
  (if (stringp charset)
      (setq charset (intern (downcase charset))))
  (let ((cs (assq charset w3m-charset-coding-system-alist)))
    (setq cs (if cs (cdr cs) charset))
    (if (find-coding-system cs)
	cs)))

(w3m-static-if (not (fboundp 'coding-system-category))
    (defalias 'coding-system-category 'get-code-mnemonic))

(defun w3m-decode-buffer (type charset)
  (if (and (not charset) (string= type "text/html"))
      (setq charset
	    (let ((case-fold-search t))
	      (goto-char (point-min))
	      (and (or (re-search-forward
			w3m-meta-content-type-charset-regexp nil t)
		       (re-search-forward
			w3m-meta-charset-content-type-regexp nil t))
		   (buffer-substring-no-properties (match-beginning 2)
						   (match-end 2))))))
  (decode-coding-region
   (point-min) (point-max)
   (if charset
       (w3m-charset-to-coding-system charset)
     (let ((default (condition-case nil
			(coding-system-category w3m-coding-system)
		      (error nil)))
	   (candidate (detect-coding-region (point-min) (point-max))))
       (unless (listp candidate)
	 (setq candidate (list candidate)))
       (catch 'coding
	 (dolist (coding candidate)
	   (if (eq default (coding-system-category coding))
	       (throw 'coding coding)))
	 (if (eq (coding-system-category 'binary)
		 (coding-system-category (car candidate)))
	     w3m-coding-system
	   (car candidate))))))
  (set-buffer-multibyte t))


;;; Retrieve local data:
(defun w3m-local-content-type (url)
  (catch 'type-detected
    (dolist (elem w3m-content-type-alist "unknown")
      (if (string-match (nth 1 elem) url)
	  (throw 'type-detected (car elem))))))

(defun w3m-local-attributes (url &rest args)
  "Return a list of attributes of URL.
Value is nil if retirieval of header is failed.  Otherwise, list
elements are:
 0. Type of contents.
 1. Charset of contents.
 2. Size in bytes.
 3. Encoding of contents.
 4. Last modification time.
"
  (let* ((file (w3m-url-to-file-name url))
	 (attr (when (file-exists-p file)
		 (file-attributes file))))
    (list (w3m-local-content-type url)
	  nil
	  (nth 7 attr)
	  nil
	  (nth 5 attr))))

(defun w3m-local-retrieve (url &optional no-decode &rest args)
  "Retrieve content of local URL and insert it to the working buffer.
This function will return content-type of URL as string when retrieval
succeed.  If NO-DECODE, set the multibyte flag of the working buffer
to nil."
  (let ((type (w3m-local-content-type url))
	(file))
    (setq file (w3m-url-to-file-name url))
    (w3m-with-work-buffer
      (delete-region (point-min) (point-max))
      (if (and (string-match "^text/" type)
	       (not no-decode))
	  (progn
	    (set-buffer-multibyte t)
	    (insert-file-contents file))
	(set-buffer-multibyte nil)
	(let ((coding-system-for-read 'binary)
	      (file-coding-system-for-read 'binary)
	      jka-compr-compression-info-list
	      jam-zcat-filename-list
	      format-alist)
	  (insert-file-contents file))))
    type))


;;; Retrieve data via HTTP:
(defun w3m-remove-redundant-spaces (str)
  "Remove spaces/tabs at the front of a string and at the end of a string"
  (save-match-data
    (if (string-match "^[ \t\r\f\n]+" str)
	(setq str (substring str (match-end 0))))
    (if (string-match "[ \t\r\f\n]+$" str)
	(setq str (substring str 0 (match-beginning 0)))))
  str)

(defun w3m-w3m-get-header (url &optional no-cache)
  "Return the header string of the URL.
If optional argument NO-CACHE is non-nil, cache is not used."
  (or (unless no-cache
	(w3m-cache-request-header url))
      (with-temp-buffer
	(let ((w3m-current-url url))
	  (w3m-message "Request sent, waiting for response...")
	  (when (zerop (prog1 (w3m-exec-process "-dump_head" url)
			 (w3m-message "Request sent, waiting for response... done")))
	    (w3m-cache-header url (buffer-string)))))))

(defun w3m-w3m-attributes (url &optional no-cache)
  "Return a list of attributes of URL.
Value is nil if retirieval of header is failed.  Otherwise, list
elements are:
 0. Type of contents.
 1. Charset of contents.
 2. Size in bytes.
 3. Encoding of contents.
 4. Last modification time.
If optional argument NO-CACHE is non-nil, cache is not used."
  (let ((header (w3m-w3m-get-header url no-cache)))
    (when (and header (string-match "HTTP/1\\.[0-9] 200 OK" header))
      (let (alist type charset)
	(dolist (line (split-string (substring header (match-end 0)) "\n"))
	  (when (string-match "^\\([^:]+\\):[ \t]*" line)
	    (push (cons (downcase (match-string 1 line))
			(substring line (match-end 0)))
		  alist)))
	(when (setq type (cdr (assoc "content-type" alist)))
	  (if (string-match ";[ \t]*charset=" type)
	      (setq charset (w3m-remove-redundant-spaces
			     (substring type (match-end 0)))
		    type (w3m-remove-redundant-spaces
			  (substring type 0 (match-beginning 0))))
	    (setq type (w3m-remove-redundant-spaces type))))
	(list (or type (w3m-local-content-type url))
	      charset
	      (let ((v (cdr (assoc "content-length" alist))))
		(and v (string-to-number v)))
	      (cdr (assoc "content-encoding" alist))
	      (let ((v (cdr (assoc "last-modified" alist))))
		(and v (apply (function encode-time)
			      (w3m-time-parse-string v)))))))))

(defun w3m-pretty-length (n)
  ;; This function imported from url.el.
  (cond
   ((< n 1024)
    (format "%d bytes" n))
   ((< n (* 1024 1024))
    (format "%dk" (/ n 1024.0)))
   (t
    (format "%2.2fM" (/ n (* 1024 1024.0))))))

(defun w3m-w3m-retrieve (url &optional no-decode no-cache)
  "Retrieve content of URL with w3m and insert it to the working buffer.
This function will return content-type of URL as string when retrieval
succeed.  If NO-DECODE, set the multibyte flag of the working buffer
to nil."
  (let ((headers (w3m-w3m-attributes url no-cache)))
    (when headers
      (let ((type    (car headers))
	    (charset (nth 1 headers))
	    (length  (nth 2 headers)))
	(w3m-with-work-buffer
	  (delete-region (point-min) (point-max))
	  (set-buffer-multibyte nil)
	  (or
	   (unless no-cache
	     (when (w3m-cache-request-contents url)
	       (and (string-match "^text/" type)
		    (unless no-decode
		      (w3m-decode-buffer type charset)))
	       type))
	   (let* ((buflines)
		  (w3m-current-url url)
		  (w3m-w3m-retrieve-length length)
		  (w3m-process-message
		   (lambda ()
		     (if w3m-w3m-retrieve-length
			 (w3m-message
			  "Reading... %s of %s (%d%%)"
			  (w3m-pretty-length (buffer-size))
			  (w3m-pretty-length w3m-w3m-retrieve-length)
			  (/ (* (buffer-size) 100) w3m-w3m-retrieve-length))
		       (w3m-message "Reading... %s"
				    (w3m-pretty-length (buffer-size)))))))
	     (w3m-message "Reading...")
	     (delete-region (point-min) (point-max))
	     (w3m-exec-process "-dump_source" url)
	     (w3m-message "Reading... done")
	     (cond
	      ((and length (eq w3m-executable-type 'cygwin))
	       (setq buflines (count-lines (point-min) (point-max)))
	       (cond
		;; no bugs in output.
		((= (buffer-size) length))
		;; new-line character is replaced to CRLF.
		((or (= (buffer-size) (+ length buflines))
		     (= (buffer-size) (+ length buflines -1)))
		 (while (search-forward "\r\n" nil t)
		   (delete-region (- (point) 2) (1- (point)))))))
	      ((and length (> (buffer-size) length))
	       (delete-region (point-min) (- (point-max) length)))
	      ((string= "text/html" type)
	       ;; Remove cookies.
	       (goto-char (point-min))
	       (while (and (not (eobp))
			   (looking-at "Received cookie: "))
		 (forward-line 1))
	       (skip-chars-forward " \t\r\f\n")
	       (if (or (looking-at "<!DOCTYPE")
		       (looking-at "<HTML>")) ; for eGroups.
		   (delete-region (point-min) (point)))))
	     (w3m-cache-contents url (current-buffer))
	     (and (string-match "^text/" type)
		  (not no-decode)
		  (w3m-decode-buffer type charset))
	     type)))))))

(defun w3m-retrieve (url &optional no-decode no-cache)
  "Retrieve content of URL and insert it to the working buffer.
This function will return content-type of URL as string when retrieval
succeed.  If NO-DECODE, set the multibyte flag of the working buffer
to nil."
  (cond
   ((string-match "^about:" url)
    (let (func)
      (if (and (string-match "^about://\\([^/]+\\)/" url)
	       (setq func (intern-soft
			   (concat "w3m-about-" (match-string 1 url))))
	       (fboundp func))
	  (funcall func url no-decode no-cache)
	(w3m-about url no-decode no-cache))))
   ((string-match "^\\(file:\\|/\\)" url)
    (w3m-local-retrieve url no-decode))
   ((string-match "^cid:" url)
    (let ((func (cdr (assq major-mode w3m-cid-retrieve-function-alist))))
      (when func
	(funcall func url no-decode no-cache))))
   (t
    (w3m-w3m-retrieve url no-decode no-cache))))

(defun w3m-download (url &optional filename no-cache)
  (unless filename
    (setq filename (w3m-read-file-name nil nil url)))
  (if (w3m-retrieve url t no-cache)
      (with-current-buffer (get-buffer w3m-work-buffer-name)
	(let ((buffer-file-coding-system 'binary)
	      (coding-system-for-write 'binary)
	      jka-compr-compression-info-list
	      jam-zcat-filename-list
	      format-alist)
	  (if (or (not (file-exists-p filename))
		  (y-or-n-p (format "File(%s) is already exists. Overwrite? " filename)))
	      (write-region (point-min) (point-max) filename))))
    (error "Unknown URL: %s" url)))

(defsubst w3m-attributes (url &optional no-cache)
  "Return a list of attributes of URL.
Value is nil if retirieval of header is failed.  Otherwise, list
elements are:
 0. Type of contents.
 1. Charset of contents.
 2. Size in bytes.
 3. Encoding of contents.
 4. Last modification time.
If optional argument NO-CACHE is non-nil, cache is not used."
  (cond
   ((string-match "^about:" url)
    (list "text/html" nil nil nil nil))
   ((string-match "^\\(file:\\|/\\)" url)
    (w3m-local-attributes url))
   (t
    (w3m-w3m-attributes url no-cache))))

(defmacro w3m-content-type (url &optional no-cache)
  (` (car (w3m-attributes (, url) (, no-cache)))))
(defmacro w3m-content-charset (url &optional no-cache)
  (` (nth 1 (w3m-attributes (, url) (, no-cache)))))
(defmacro w3m-content-length (url &optional no-cache)
  (` (nth 2 (w3m-attributes (, url) (, no-cache)))))
(defmacro w3m-content-encoding (url &optional no-cache)
  (` (nth 3 (w3m-attributes (, url) (, no-cache)))))
(defmacro w3m-last-modified (url &optional no-cache)
  (` (nth 4 (w3m-attributes (, url) (, no-cache)))))


;;; Retrieve data:
(defsubst w3m-decode-extended-characters ()
  "Decode w3m-specific extended characters in this buffer."
  (dolist (elem w3m-extended-characters-table)
    (goto-char (point-min))
    (while (search-forward (car elem) nil t)
      (delete-region (match-beginning 0) (match-end 0))
      (insert (cdr elem)))))

(defun w3m-rendering-region (start end)
  "Do rendering of contents in this buffer as HTML and return title."
  (save-restriction
    (narrow-to-region start end)
    (let ((buf (w3m-get-buffer-create " *w3m-rendering-region*"))
	  (coding-system-for-write w3m-input-coding-system)
	  (coding-system-for-read 'binary)
	  (default-process-coding-system
	    (cons 'binary w3m-input-coding-system)))
      (with-current-buffer buf
	(delete-region (point-min) (point-max))
	(set-buffer-multibyte nil))
      (if w3m-use-form
	  (w3m-form-parse-region start end))
      (w3m-message "Rendering...")
      (apply 'call-process-region
	     start end w3m-command t buf nil
	     (mapcar (lambda (x)
		       (if (stringp x)
			   x
			 (prin1-to-string (eval x))))
		     w3m-command-arguments))
      (w3m-message "Rendering... done")
      (goto-char (point-min))
      (insert
       (with-current-buffer buf
	 (w3m-decode-extended-characters)
	 (decode-coding-region (point-min) (point-max) w3m-output-coding-system)
	 (set-buffer-multibyte t)
	 (buffer-string)))
      (goto-char (point-min))
      (let (title)
	(dolist (regexp '("<title_alt[ \t\n]+title=\"\\([^\"]+\\)\">"
			  "<title>\\([^<]\\)</title>"))
	  (goto-char (point-min))
	  (when (re-search-forward regexp nil t)
	    (setq title (match-string 1))
	    (delete-region (match-beginning 0) (match-end 0))))
	(if (and (null title)
		 (stringp w3m-current-url)
		 (< 0 (length (file-name-nondirectory w3m-current-url))))
	    (setq title (file-name-nondirectory w3m-current-url)))
	(setq w3m-current-title (or title "<no-title>"))))))

(defun w3m-exec (url &optional buffer no-cache)
  "Download URL with w3m to the BUFFER.
If BUFFER is nil, all data is placed to the current buffer.  When new
content is retrieved and half-dumped data is placed in the BUFFER,
this function returns t.  Otherwise, returns nil."
  (save-excursion
    (if buffer (set-buffer buffer))
    (let ((type (w3m-retrieve url nil no-cache)))
      (if type
	  (cond
	   ((string-match "^text/" type)
	    (let (buffer-read-only)
	      (setq w3m-current-url url)
	      (setq w3m-url-history (cons url w3m-url-history))
	      (setq-default w3m-url-history
			    (cons url (default-value 'w3m-url-history)))
	      (setq w3m-url-yrotsih nil) 
	      (setq-default w3m-url-yrotsih nil)
	      (delete-region (point-min) (point-max))
	      (insert-buffer w3m-work-buffer-name)
	      (if (string= "text/html" type)
		  (progn (w3m-rendering-region (point-min) (point-max)) t)
		(setq w3m-current-title (file-name-nondirectory url))
		nil)))
	   ((and (w3m-image-type-available-p (w3m-image-type type))
		 (string-match "^image/" type))
	    (let (buffer-read-only)
	      (setq w3m-current-url url)
	      (setq w3m-url-history (cons url w3m-url-history))
	      (setq-default w3m-url-history
			    (cons url (default-value 'w3m-url-history)))
	      (setq w3m-url-yrotsih nil) 
	      (setq-default w3m-url-yrotsih nil)
	      (delete-region (point-min) (point-max))
	      (insert (file-name-nondirectory url))
	      (set-text-properties (point-min)(point-max)
				   (list 'face 'w3m-image-face
					 'w3m-image url
					 'mouse-face 'highlight))
	      (setq w3m-current-title (file-name-nondirectory url))
	      t))
	   (t (w3m-external-view url)
	      nil))
	(error "Unknown URL: %s" url)))))


(defun w3m-search-name-anchor (name &optional quiet)
  (interactive "sName: ")
  (let ((pos (point-min)))
    (catch 'found
      (while (setq pos (next-single-property-change pos 'w3m-name-anchor))
	(when (equal name (get-text-property pos 'w3m-name-anchor))
	  (goto-char pos)
	  (throw 'found t))
	(setq pos (next-single-property-change pos 'w3m-name-anchor)))
      (unless quiet
	(message "Not found such name anchor."))
      nil)))

(defun w3m-view-parent-page ()
  (interactive)
  (if (null w3m-current-url)
      (error "w3m-current-url is not set"))
  (let (parent-url)
    ;; Check whether http://foo/bar/ or http://foo/bar
    (if (string-match "/$" w3m-current-url)
	(if (string-match "\\(.*\\)/[^/]+/$" w3m-current-url)
	    ;; http://foo/bar/ -> http://foo/
	    (setq parent-url (concat (match-string 1 w3m-current-url) "/")))
      (if (string-match "\\(.*\\)/.+$" w3m-current-url)
	  ;; http://foo/bar -> http://foo/
	  (setq parent-url (concat (match-string 1 w3m-current-url) "/"))))
    ;; Ignore "http:/"
    (if (and parent-url
	     (string-match "^[a-z]+:/+$" parent-url))
	(setq parent-url nil))
    (if parent-url
	(w3m-goto-url parent-url)
      (error "No parent page for: %s" w3m-current-url))))

(defun w3m-view-previous-page (&optional arg)
  (interactive "p")
  (unless arg (setq arg 1))
  (let ((url (nth arg w3m-url-history)))
    (when url
      (let (w3m-url-history w3m-url-yrotsih) 
	(w3m-goto-url url))
      ;; restore last position
      (w3m-arrived-restore-position url)
      (while (< 0 arg)
	(setq w3m-url-yrotsih 
	      (cons (car w3m-url-history) w3m-url-yrotsih)
	      w3m-url-history (cdr w3m-url-history)
	      arg (1- arg))))))

(defun w3m-view-next-page (&optional arg)
  (interactive "p")
  (unless arg (setq arg 1))
  (setq arg (1- arg))
  (let ((url (nth arg w3m-url-yrotsih)))
    (when url
      (let (w3m-url-history w3m-url-yrotsih) 
	(w3m-goto-url url))
      ;; restore last position
      (w3m-arrived-restore-position url)
      (while (< -1 arg)
	(setq w3m-url-history 
	      (cons (car w3m-url-yrotsih) w3m-url-history)
	      w3m-url-yrotsih (cdr w3m-url-yrotsih)
	      arg (1- arg))))))

(defun w3m-view-previous-point ()
  (interactive)
  (w3m-arrived-restore-position w3m-current-url))

(defun w3m-expand-url (url base)
  "Convert URL to absolute, and canonicalise it."
  (save-match-data
    (if (not base) (setq base ""))
    (if (string-match "^[^:/]+://[^/]*$" base)
	(setq base (concat base "/")))
    (cond
     ;; URL is relative on BASE.
     ((string-match "^#" url)
      (concat base url))
     ;; URL has absolute spec.
     ((string-match "^[^:/]+:" url)
      url)
     ((string-match "^/" url)
      (if (string-match "^\\([^:/]+://[^/]*\\)/" base)
	  (concat (match-string 1 base) url)
	url))
     (t
      (let ((server "") path)
	(if (string-match "^\\([^:]+://[^/]*\\)/" base)
	    (setq server (match-string 1 base)
		  base (substring base (match-end 1))))
	(setq path (expand-file-name url (file-name-directory base)))
	;; remove drive (for Win32 platform)
	(if (string-match "^.:" path)
	    (setq path (substring path (match-end 0))))
	(concat server path))))))
 
(defun w3m-view-this-url (&optional arg)
  "*View the URL of the link under point."
  (interactive "P")
  (let ((url (w3m-anchor)) (act (w3m-action)))
    (cond
     (url (w3m-goto-url url arg))
     (act (eval act)))))

(defun w3m-mouse-view-this-url (event)
  (interactive "e")
  (mouse-set-point event)
  (let ((url (w3m-anchor)) (img (w3m-image)))
    (cond
     (url (w3m-view-this-url))
     (img (w3m-view-image))
     (t (message "No URL at point.")))))

(defsubst w3m-which-command (command)
  (catch 'found-command
    (let (bin)
      (dolist (dir exec-path)
	(when (or (file-executable-p
		   (setq bin (expand-file-name command dir)))
		  (file-executable-p
		   (setq bin (expand-file-name (concat command ".exe") dir))))
	  (throw 'found-command bin))))))

(defun w3m-external-view (url)
  (let* ((type (w3m-content-type url))
	 (method (nth 2 (assoc type w3m-content-type-alist))))
    (cond
     ((not method)
      (w3m-download url))
     ((functionp method)
      (funcall method url))
     ((consp method)
      (let ((command (w3m-which-command (car method)))
	    (arguments (cdr method))
	    (file (make-temp-name
		   (expand-file-name "w3mel" w3m-profile-directory)))
	    (proc))
	(if command
	    (unwind-protect
		(with-current-buffer
		    (generate-new-buffer " *w3m-external-view*")
		  (if (memq 'file arguments) (w3m-download url file))
		  (setq proc
			(apply 'start-process
			       "w3m-external-view"
			       (current-buffer)
			       command
			       (mapcar (function eval) arguments)))
		  (setq w3m-process-temp-file file)
		  (set-process-sentinel
		   proc
		   (lambda (proc event)
		     (and (string-match "^\\(finished\\|exited\\)" event)
			  (buffer-name (process-buffer proc))
			  (save-excursion
			    (set-buffer (process-buffer proc))
			    (if (file-exists-p w3m-process-temp-file)
				(delete-file w3m-process-temp-file)))
			  (kill-buffer (process-buffer proc))))))
	      (if (file-exists-p file)
		  (unless (and (processp proc)
			       (memq (process-status proc) '(run stop)))
		    (delete-file file))))
	  (w3m-download url)))))))

(defun w3m-view-image ()
  "*View the image under point."
  (interactive)
  (let ((url (w3m-image)))
    (if url
	(w3m-external-view url)
      (message "No file at point."))))

(defun w3m-save-image ()
  "*Save the image under point to a file."
  (interactive)
  (let ((url (w3m-image)))
    (if url
	(w3m-download url)
      (message "No file at point."))))

(defun w3m-view-current-url-with-external-browser ()
  "*View this URL."
  (interactive)
  (let ((url (w3m-anchor)))
    (or url
	(and (y-or-n-p (format "Browse <%s> ? " w3m-current-url))
	     (setq url w3m-current-url)))
    (when url
      (message "Browse <%s>" url)
      (w3m-external-view url))))

(defun w3m-download-this-url ()
  "*Download the URL of the link under point to a file."
  (interactive)
  (let ((url (w3m-anchor)))
    (if url
	(progn
	  (w3m-download url)
	  (w3m-refontify-anchor (current-buffer)))
      (message "No URL at point."))))

(defun w3m-print-current-url ()
  "*Print the URL of current page and push it into kill-ring."
  (interactive)
  (kill-new w3m-current-url)
  (message "%s" w3m-current-url))

(defun w3m-print-this-url ()
  "*Print the URL of the link under point."
  (interactive)
  (let ((url (w3m-anchor)))
    (message "%s" (or url "Not found"))))

(defun w3m-save-this-url ()
  (interactive)
  (let ((url (w3m-anchor)))
    (if url (kill-new url))))

(defun w3m-goto-next-anchor ()
  ;; move to the end of the current anchor
  (when (w3m-anchor)
    (goto-char (next-single-property-change (point) 'w3m-href-anchor)))
  ;; find the next anchor
  (or (w3m-anchor)
      (let ((pos (next-single-property-change (point) 'w3m-href-anchor)))
	(if pos (progn (goto-char pos) t) nil))))

(defun w3m-next-anchor (&optional arg)
  "*Move cursor to the next anchor."
  (interactive "p")
  (unless arg (setq arg 1))
  (if (< arg 0)
      (w3m-previous-anchor (- arg))
    (while (> arg 0)
      (unless (w3m-goto-next-anchor)
	;; search from the beginning of the buffer
	(goto-char (point-min))
	(w3m-goto-next-anchor))
      (setq arg (1- arg)))
    (w3m-print-this-url)))

(defun w3m-goto-previous-anchor ()
  ;; move to the beginning of the current anchor
  (when (w3m-anchor)
    (goto-char (previous-single-property-change (1+ (point))
						'w3m-href-anchor)))
  ;; find the previous anchor
  (let ((pos (previous-single-property-change (point) 'w3m-href-anchor)))
    (if pos (goto-char
	     (if (w3m-anchor pos) pos
	       (previous-single-property-change pos 'w3m-href-anchor))))))

(defun w3m-previous-anchor (&optional arg)
  "Move cursor to the previous anchor."
  (interactive "p")
  (unless arg (setq arg 1))
  (if (< arg 0)
      (w3m-next-anchor (- arg))
    (while (> arg 0)
      (unless (w3m-goto-previous-anchor)
	;; search from the end of the buffer
	(goto-char (point-max))
	(w3m-goto-previous-anchor))
      (setq arg (1- arg)))
    (w3m-print-this-url)))


(defun w3m-copy-buffer (buf &optional newname and-pop) "\
Create a twin copy of the current buffer.
if NEWNAME is nil, it defaults to the current buffer's name.
if AND-POP is non-nil, the new buffer is shown with `pop-to-buffer'."
  (interactive (list (current-buffer)
		     (if current-prefix-arg (read-string "Name: "))
		     t))
  (setq newname (or newname (buffer-name)))
  (if (string-match "<[0-9]+>\\'" newname)
      (setq newname (substring newname 0 (match-beginning 0))))
  (with-current-buffer buf
    (let ((ptmin (point-min))
	  (ptmax (point-max))
	  (content (save-restriction (widen) (buffer-string)))
	  (mode major-mode)
	  (lvars (buffer-local-variables))
	  (new (generate-new-buffer (or newname (buffer-name)))))
      (with-current-buffer new
	;;(erase-buffer)
	(insert content)
	(narrow-to-region ptmin ptmax)
	(funcall mode)			;still needed??  -sm
	(mapcar (lambda (v)
		  (if (not (consp v)) (makunbound v)
		    (condition-case ()	;in case var is read-only
			(set (make-local-variable (car v)) (cdr v))
		      (error nil))))
		lvars)
	(when and-pop (pop-to-buffer new))
	new))))


(defvar w3m-mode-map nil)
(unless w3m-mode-map
  (let ((map (make-keymap)))
    (define-key map " " 'scroll-up)
    (define-key map "b" 'scroll-down)
    (define-key map [backspace] 'scroll-down)
    (define-key map [delete] 'scroll-down)
    (define-key map "h" 'backward-char)
    (define-key map "j" 'next-line)
    (define-key map "k" 'previous-line)
    (define-key map "l" 'forward-char)
    (define-key map "J" (lambda () (interactive) (scroll-up 1)))
    (define-key map "K" (lambda () (interactive) (scroll-up -1)))
    (define-key map "G" 'goto-line)
    (define-key map "\C-?" 'scroll-down)
    (define-key map "\t" 'w3m-next-anchor)
    (define-key map [(shift tab)] 'w3m-previous-anchor)
    (define-key map [down] 'w3m-next-anchor)
    (define-key map "\M-\t" 'w3m-previous-anchor)
    (define-key map [up] 'w3m-previous-anchor)
    (define-key map "\C-m" 'w3m-view-this-url)
    (define-key map [right] 'w3m-view-this-url)
    (if (featurep 'xemacs)
	(define-key map [(button2)] 'w3m-mouse-view-this-url)
      (define-key map [mouse-2] 'w3m-mouse-view-this-url))
    (define-key map "\C-c\C-b" 'w3m-view-previous-point)
    (define-key map [left] 'w3m-view-previous-page)
    (define-key map "B" 'w3m-view-previous-page)
    (define-key map "N" 'w3m-view-next-page)
    (define-key map "^" 'w3m-view-parent-page)
    (define-key map "d" 'w3m-download-this-url)
    (define-key map "u" 'w3m-print-this-url)
    (define-key map "I" 'w3m-view-image)
    (define-key map "\M-I" 'w3m-save-image)
    (define-key map "c" 'w3m-print-current-url)
    (define-key map "M" 'w3m-view-current-url-with-external-browser)
    (define-key map "g" 'w3m-goto-url)
    (define-key map "t" 'w3m-toggle-inline-images)
    (define-key map "U" 'w3m-goto-url)
    (define-key map "V" 'w3m-goto-url)
    (define-key map "v" 'w3m-bookmark-view)
    (define-key map "q" 'w3m-close-window)
    (define-key map "Q" 'w3m-quit)
    (define-key map "\M-n" 'w3m-copy-buffer)
    (define-key map "R" 'w3m-reload-this-page)
    (define-key map "?" 'describe-mode)
    (define-key map "\M-a" 'w3m-bookmark-add-this-url)
    (define-key map "a" 'w3m-bookmark-add-current-url)
    (define-key map ">" 'w3m-scroll-left)
    (define-key map "<" 'w3m-scroll-right)
    (define-key map "\\" 'w3m-view-source)
    (define-key map "=" 'w3m-view-header)
    (define-key map "s" 'w3m-history)
    (setq w3m-mode-map map)))

(defun w3m-alive-p ()
  "When w3m is running, return that buffer.  Otherwise return nil."
  (catch 'alive
    (save-current-buffer
      (dolist (buf (buffer-list))
	(set-buffer buf)
	(when (eq major-mode 'w3m-mode)
	  (throw 'alive buf))))
    nil))

(defun w3m-quit (&optional force)
  "Quit browsing WWW after updating arrived URLs list."
  (interactive "P")
  (when (or force
	    (y-or-n-p "Do you want to exit w3m? "))
    (kill-buffer (current-buffer))
    (unless (w3m-alive-p)
      ;; If no w3m is running, then destruct all data.
      (w3m-cache-shutdown)
      (w3m-arrived-shutdown)
      (w3m-kill-all-buffer))))

(defun w3m-close-window ()
  "Close this window and make the other buffer current."
  (interactive)
  (bury-buffer (current-buffer))
  (set-window-buffer (selected-window) (other-buffer)))


(defun w3m-mode ()
  "\\<w3m-mode-map>
   Major mode to browsing w3m buffer.

\\[w3m-view-this-url]	View this url.
\\[w3m-mouse-view-this-url]	View this url.
\\[w3m-reload-this-page]	Reload this page.
\\[w3m-next-anchor]	Jump to next anchor.
\\[w3m-previous-anchor]	Jump to previous anchor.
\\[w3m-view-previous-page]	Back to previous page.
\\[w3m-view-next-page]	Forward to next page.
\\[w3m-view-parent-page]	Forward to next page.

\\[w3m-download-this-url]	Download this url.
\\[w3m-print-this-url]	Print this url.
\\[w3m-view-image]	View image.
\\[w3m-save-image]	Save image.

\\[w3m-print-current-url]	Print current url.
\\[w3m-view-current-url-with-external-browser]	View current url with external browser.

\\[scroll-up]	Scroll up.
\\[scroll-down]	Scroll down.
\\[w3m-scroll-left]	Scroll to left.
\\[w3m-scroll-right]	Scroll to right.

\\[next-line]	Next line.
\\[previous-line]	Previous line.

\\[forward-char]	Forward char.
\\[backward-char]	Backward char.

\\[goto-line]	Jump to line.
\\[w3m-view-previous-point]	w3m-view-previous-point.

\\[w3m]	w3m.
\\[w3m-bookmark-view]	w3m-bookmark-view.
\\[w3m-copy-buffer]	w3m-copy-buffer.

\\[w3m-quit]	w3m-quit.
\\[describe-mode]	describe-mode.
"
  (kill-all-local-variables)
  (buffer-disable-undo)
  (setq major-mode 'w3m-mode)
  (setq mode-name "w3m")
  (use-local-map w3m-mode-map)
  (setq truncate-lines t)
  (w3m-setup-toolbar)
  (run-hooks 'w3m-mode-hook))

(defun w3m-scroll-left (arg)
  "Scroll to left.
Scroll size is `w3m-horizontal-scroll-size' columns
or prefix ARG columns."
  (interactive "P")
  (scroll-left (if arg
		   (prefix-numeric-value arg)
		 w3m-horizontal-scroll-columns)))

(defun w3m-scroll-right (arg)
  "Scroll to right.
Scroll size is `w3m-horizontal-scroll-size' columns
or prefix ARG columns."
  (interactive "P")
  (scroll-right (if arg
		    (prefix-numeric-value arg)
		  w3m-horizontal-scroll-columns)))

(defun w3m-goto-mailto-url (url)
  (if (and (symbolp w3m-mailto-url-function)
	   (fboundp w3m-mailto-url-function))
      (funcall w3m-mailto-url-function url)
    (let (comp)
      ;; Require `mail-user-agent' setting
      (if (not (and (boundp 'mail-user-agent)
		    mail-user-agent
		    (setq comp (intern-soft (concat (symbol-name mail-user-agent)
						    "-compose")))
		    (fboundp comp)))
	  (error "You must specify valid `mail-user-agent'."))
      ;; Use rfc2368.el if exist.
      ;; rfc2368.el is written by Sen Nagata.
      ;; You can find it in "contrib" directory of Mew package
      ;; or in "utils" directory of Wanderlust package.
      (if (or (featurep 'rfc2368)
	      (condition-case nil (require 'rfc2368) (error nil)))
	  (let ((info (rfc2368-parse-mailto-url url)))
	    (apply comp (mapcar (lambda (x)
				  (cdr (assoc x info)))
				'("To" "Subject"))))
	;; without rfc2368.el.
	(funcall comp (match-string 1 url))))))

(defun w3m-convert-ftp-url-for-emacsen (url)
  (or (and (string-match "^ftp://?\\([^/@]+@\\)?\\([^/]+\\)\\(/~/\\)?" url)
	   (concat "/"
		   (if (match-beginning 1)
		       (substring url (match-beginning 1) (match-end 1))
		     "anonymous@")
		   (substring url (match-beginning 2) (match-end 2))
		   ":"
		   (substring url (match-end 2))))
      (error "URL is strange.")))

(defun w3m-goto-ftp-url (url)
  (let ((ftp (w3m-convert-ftp-url-for-emacsen url))
	(file (file-name-nondirectory url)))
    (if (string-match "\\(\\.gz\\|\\.bz2\\|\\.zip\\|\\.lzh\\)$" file)
	(copy-file ftp (w3m-read-file-name nil nil file))
      (dired-other-window ftp))))

(defun w3m-goto-url (url &optional reload)
  "*Retrieve contents of URL."
  (interactive
   (list (w3m-input-url) current-prefix-arg))
  (cond
   ;; process mailto: protocol
   ((string-match "^mailto:\\(.*\\)" url)
    (w3m-goto-mailto-url url))
   ;; process ftp: protocol
   ((and (string-match "^ftp://" url)
	 (not (string= "text/html" (w3m-local-content-type url))))
    (w3m-goto-ftp-url url))
   (t
    ;; When this buffer's major mode is not w3m-mode, generate an
    ;; appropriate buffer and select it.
    (unless (eq major-mode 'w3m-mode)
      (set-buffer (get-buffer-create "*w3m*"))
      (unless (eq major-mode 'w3m-mode)
	(w3m-mode)
	(setq mode-line-buffer-identification
	      (list "%b" " / " 'w3m-current-title))))
    ;; Setup arrived database.
    (w3m-arrived-setup)
    (w3m-arrived-store-position w3m-current-url)
    ;; Retrieve.
    (let ((orig url)
	  (name))
      (when (string-match "#\\([^#]+\\)$" url)
	(setq name (match-string 1 url)
	      url (substring url 0 (match-beginning 0))))
      (if (not (w3m-exec url nil reload))
	  (w3m-refontify-anchor)
	(w3m-arrived-add orig)
	(if name (w3m-arrived-add url))
	(w3m-fontify)
	(or (and name (w3m-search-name-anchor name))
	    (goto-char (point-min)))
	(setq w3m-display-inline-image-status 'off)
	(when w3m-display-inline-image
	  (sit-for 0)
	  (w3m-toggle-inline-images 'force reload))
	(setq buffer-read-only t)
	(set-buffer-modified-p nil)
	(switch-to-buffer (current-buffer)))))))


(defun w3m-reload-this-page (&optional arg)
  "Reload current page without cache."
  (interactive "P")
  (let ((w3m-display-inline-image (if arg t w3m-display-inline-image))
	w3m-url-yrotsih)
    (setq w3m-url-history (cdr w3m-url-history))
    (w3m-goto-url w3m-current-url 'reload)))


;;;###autoload
(defun w3m (url &optional args)
  "Interface for w3m on Emacs."
  (interactive
   (list (or (w3m-alive-p)
	     (w3m-input-url))))
  (if (bufferp url)
      (set-buffer url)
    (w3m-goto-url url))
  (switch-to-buffer (current-buffer)))


(defun w3m-browse-url (url &optional new-window)
  "w3m interface function for browse-url.el."
  (interactive
   (progn
     (require 'browse-url)
     (browse-url-interactive-arg "w3m URL: ")))
  (if new-window (split-window))
  (w3m-goto-url url))

(defun w3m-find-file (file)
  "w3m Interface function for local file."
  (interactive "fFilename: ")
  (w3m (w3m-expand-file-name-as-url file)))


(defun w3m-cygwin-path (path)
  "Convert win32 path into cygwin format.
ex.) c:/dir/file => //c/dir/file"
  (if (string-match "^\\([A-Za-z]\\):" path)
      (replace-match "//\\1" nil nil path)
    path))


(defun w3m-region (start end)
  "Render region in current buffer and replace with result."
  (interactive "r")
  (save-restriction
    (narrow-to-region start end)
    (w3m-rendering-region start end)
    (w3m-fontify)
    (setq w3m-display-inline-image-status 'off)
    (when w3m-display-inline-image
      (sit-for 0)
      (w3m-toggle-inline-images 'force))))


;;; About:
(defun w3m-about (url &rest args)
  (w3m-with-work-buffer
    (delete-region (point-min) (point-max)))
  "text/html")

(defun w3m-about-source (url &optional no-decode no-cache)
  (when (string-match "^about://source/" url)
    (let ((type (w3m-retrieve (substring url (match-end 0))
			      no-decode no-cache)))
      (and type "text/plain"))))

(defun w3m-view-source ()
  "*Display source of this current buffer."
  (interactive)
  (let (w3m-url-history w3m-url-yrotsih)
    (w3m-goto-url
     (if (string-match "^about://source/" w3m-current-url)
	 (substring w3m-current-url (match-end 0))
       (concat "about://source/" w3m-current-url)))))

(defun w3m-about-header (url &optional no-decode no-cache)
  (when (string-match "^about://header/" url)
    (w3m-with-work-buffer
      (delete-region (point-min) (point-max))
      (let ((header (w3m-w3m-get-header (substring url (match-end 0)) no-cache)))
	(when header
	  (insert header)
	  "text/plain")))))

(defun w3m-view-header ()
  "*Display header of this current buffer."
  (interactive)
  (w3m-goto-url (concat "about://header/" w3m-current-url)))

(defun w3m-about-history (&rest args)
  (let ((history w3m-url-history))
    (w3m-with-work-buffer
      (delete-region (point-min) (point-max))
      (insert "<head><title>URL history</title></head><body>\n")
      (dolist (url history)
	(unless (string-match "^about://\\(header\\|source\\|history\\)/" url)
	  (insert (format "<a href=\"%s\">%s</a><br>\n" url url))))
      (insert "</body>")))
  "text/html")

(defun w3m-history ()
  (interactive)
  (w3m-goto-url "about://history/"))

(defun w3m-w32-browser-with-fiber (url)
  (cond
   ((string-match "^file://\\([a-z]\\)\\(.*\\)" url)
    (setq url (concat (match-string 1 url) ":" (match-string 2 url))))
   ((string-match "^/cygdrive/\\([a-z]\\)\\(.*\\)" url)
    (setq url (concat (match-string 1 url) ":" (match-string 2 url)))))
  (start-process "w3m-w32-browser-with-fiber" (current-buffer) "fiber.exe" url))


;; Add-on programs:
(when (locate-library "w3m-bookmark.el")
  (autoload 'w3m-bookmark-view "w3m-bookmark" nil t)
  (autoload 'w3m-bookmark-add-this-url "w3m-bookmark"
    "*Add link under cursor to bookmark." t)
  (autoload 'w3m-bookmark-add-current-url "w3m-bookmark"
    "*Add link of current page to bookmark." t))
(when (locate-library "w3m-search.el")
  (autoload 'w3m-search "w3m-search"
    "*Search QUERY using SEARCH-ENGINE." t))
(when (locate-library "w3m-weather.el")
  (autoload 'w3m-weather "w3m-weather"
    "*Display weather report." t)
  (autoload 'w3m-about-weather "w3m-weather"))
(when (locate-library "w3m-antenna.el")
  (autoload 'w3m-antenna "w3m-antenna"
    "*Display antenna report." t)
  (autoload 'w3m-about-antenna "w3m-antenna"))

(provide 'w3m)
;;; w3m.el ends here.

;;; sb-asahi.el --- shimbun backend for asahi.com

;; Copyright (C) 2001, 2002, 2003 Yuuichi Teranishi <teranisi@gohome.org>

;; Author: TSUCHIYA Masatoshi <tsuchiya@namazu.org>,
;;         Yuuichi Teranishi  <teranisi@gohome.org>,
;;         Katsumi Yamaoka    <yamaoka@jpl.org>
;; Keywords: news

;; This file is a part of shimbun.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, you can either send email to this
;; program's maintainer or write to: The Free Software Foundation,
;; Inc.; 59 Temple Place, Suite 330; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Original code was nnshimbun.el written by
;; TSUCHIYA Masatoshi <tsuchiya@namazu.org>.

;;; Code:

(require 'shimbun)
(require 'sb-text)
(luna-define-class shimbun-asahi (shimbun-text) ())

(defvar shimbun-asahi-top-level-domain "asahi.com"
  "Name of the top level domain for the Asahi shimbun.")

(defvar shimbun-asahi-url (concat "http://www."
				  shimbun-asahi-top-level-domain
				  "/")
  "Name of the parent url.")

(defvar shimbun-asahi-groups '("business" "culture" "english" "international"
			       "national" "politics" "science" "sports")
  "List of available group names.  Each name should be a directory name
which is in existence under the parent url `shimbun-asahi-url'.")

(defvar shimbun-asahi-from-address (concat "webmaster@www."
					   shimbun-asahi-top-level-domain))

(defvar shimbun-asahi-content-start
  "<!--[\t\n ]*FJZONE START NAME=\"HONBUN\"[\t\n ]*-->")
(defvar shimbun-asahi-content-end
  "<!--[\t\n ]*FJZONE END NAME=\"HONBUN\"[\t\n ]*-->")
(defvar shimbun-asahi-x-face-alist
  '(("default" . "X-Face: +Oh!C!EFfmR$+Zw{dwWW]1e_>S0rnNCA*CX|\
bIy3rr^<Q#lf&~ADU:X!t5t>gW5)Q]N{Mmn\n L]suPpL|gFjV{S|]a-:)\\FR\
7GRf9uL:ue5_=;h{V%@()={uTd@l?eXBppF%`6W%;h`#]2q+f*81n$B\n h|t")))

(defvar shimbun-asahi-expiration-days 6)

(defvar shimbun-asahi-group-index-alist
  '(("business" . "list.html")
    ("culture" . "")
    ("english" . "")
    ("international" . "list.html")
    ("national" . "")
    ("politics" . "")
    ("science" . "list.html")
    ("sports" . ""))
  "Alist of group names and index pages.  Index page is a file name which
should be found under the \"http://SERVER/GROUP/\" directory.")

(defvar shimbun-asahi-group-regexp-alist
  (let ((default (list
		  (concat
		   "<[\t\n ]*a[\t\n ]+href[\t\n ]*=[\t\n ]*\"/"
		   ;; 1. url
		   "\\(%s/update/[01][0-9][0-3][0-9]/"
		   ;; 2. serial number
		   "\\([0-9]+\\)" "\\.html\\)"
		   "\"[\t\n ]*>[\t\n ]*"
		   ;; 3. subject
		   "\\(.+\\)" "[\t\n ]*<[\t\n ]*/a[\t\n ]*>[\t\n ]*([\t\n ]*"
		   ;; 4. month
		   "\\([01][0-9]\\)" "/"
		   ;; 5. day
		   "\\([0-3][0-9]\\)" "[\t\n ]+"
		   ;; 6. hour:minute
		   "\\([012][0-9]:[0-5][0-9]\\)" "[\t\n ]*)")
		  1 2 3 4 5 6)))
    `(("business" ,@default)
      ("culture" ,@default)
      ("english" ,(concat
		   "<[\t\n ]*a[\t\n ]+href[\t\n ]*=[\t\n ]*\"/"
		   ;; 1. url
		   "\\(%s/"
		   ;; 2. extra keyword
		   "\\([a-z]+\\)" "/[a-z]+200[0-9]"
		   ;; 3. month
		   "\\([01][0-9]\\)"
		   ;; 4. day
		   "\\([0-3][0-9]\\)"
		   ;; 5. serial number
		   "\\([0-9]+\\)" "\\.html\\)"
		   "\"[\t\n ]*>[\t\n ]*"
		   "<!--[\t\n ]*leadstart[\t\n ]*-->[\t\n ]*"
		   ;; 6. subject
		   "\\(.+\\)" "[\t\n ]*"
		   "<!--[\t\n ]*leadend[\t\n ]*-->")
       1 5 6 3 4 nil 2)
      ("international" ,@default)
      ("national" ,@default)
      ("politics" ,@default)
      ("science" ,(concat
		   "<[\t\n ]*a[\t\n ]+href[\t\n ]*=[\t\n ]*\"/"
		   ;; 1. url
		   "\\(%s/update/[01][0-9][0-3][0-9]/"
		   ;; 2. serial number
		   "\\([0-9]+\\)" "\\.html\\)"
		   "\"[\t\n ]*>[\t\n ]*"
		   ;; 3. subject
		   "\\(.+\\)" "[\t\n ]*<[\t\n ]*/a[\t\n ]*>[\t\n ]*([\t\n ]*"
		   ;; 4. month
		   "\\([01][0-9]\\)" "/"
		   ;; 5. day
		   "\\([0-3][0-9]\\)" "[\t\n ]*)")
       1 2 3 4 5)
      ("sports" ,(concat
		   "<[\t\n ]*a[\t\n ]+href[\t\n ]*=[\t\n ]*\"/"
		   ;; 1. url
		   "\\(%s/"
		   ;; 2. extra keyword
		   "\\([a-z]+\\)" "/[a-z]+200[0-9][01][0-9][0-3][0-9]"
		   ;; 3. serial number
		   "\\([0-9]+\\)" "\\.html\\)"
		   "\"[\t\n ]*>[\t\n ]*"
		   ;; 4. subject
		   "\\(.+\\)" "[\t\n ]*<[\t\n ]*/a[\t\n ]*>[\t\n ]*([\t\n ]*"
		   ;; 5. month
		   "\\([01][0-9]\\)" "/"
		   ;; 6. day
		   "\\([0-3][0-9]\\)" "[\t\n ]*"
		   ;; 7. hour:minute
		   "\\([012][0-9]:[0-5][0-9]\\)?" "[\t\n ]*)")
       1 3 4 5 6 7 2)))
  "Alist of group names, regexps and numbers.  Regexp may have the \"%s\"
token which is replaced with a regexp-quoted group name.  Numbers
point to the search result in order of a url, a serial number, a
subject, a month, a day, an hour:minute and an extra keyword.")

(defun shimbun-asahi-index-url (entity)
  "Return a url for the list page corresponding to the group of ENTITY."
  (let ((group (shimbun-current-group-internal entity)))
    (concat (shimbun-url-internal entity) group "/"
	    (cdr (assoc group shimbun-asahi-group-index-alist)))))

(luna-define-method shimbun-index-url ((shimbun shimbun-asahi))
  (shimbun-asahi-index-url shimbun))

(defun shimbun-asahi-get-headers (entity)
  "Return a list of headers."
  (let ((group (shimbun-current-group-internal entity))
	(parent (shimbun-url-internal entity))
	(from (shimbun-from-address-internal entity))
	(case-fold-search t)
	regexp numbers cyear cmonth month day year headers)
    (setq regexp (assoc group shimbun-asahi-group-regexp-alist)
	  numbers (cddr regexp)
	  regexp (format (cadr regexp) (regexp-quote group))
	  cyear (decode-time)
	  cmonth (nth 4 cyear)
	  cyear (nth 5 cyear))
    (while (re-search-forward regexp nil t)
      (setq month (string-to-number (match-string (nth 3 numbers)))
	    year (cond ((and (= 12 month) (= 1 cmonth))
			(1- cyear))
		       ((and (= 1 month) (= 12 cmonth))
			(1+ cyear))
		       (t
			cyear))
	    day (string-to-number (match-string (nth 4 numbers))))
      (push (shimbun-make-header
	     ;; number
	     0
	     ;; subject
	     (save-match-data
	       (shimbun-mime-encode-string
		(if (nth 6 numbers)
		    (concat (match-string (nth 6 numbers)) ": "
			    (match-string (nth 2 numbers)))
		  (match-string (nth 2 numbers)))))
	     ;; from
	     from
	     ;; date
	     (shimbun-make-date-string year month day
				       (when (nth 5 numbers)
					 (match-string (nth 5 numbers))))
	     ;; id
	     (if (nth 6 numbers)
		 (format "<%d%02d%02d.%s%%%s.%s.%s>"
			 year month day
			 (match-string (nth 1 numbers))
			 (match-string (nth 6 numbers))
			 group shimbun-asahi-top-level-domain)
	       (format "<%d%02d%02d.%s%%%s.%s>"
		       year month day
		       (match-string (nth 1 numbers))
		       group shimbun-asahi-top-level-domain))
	     ;; references, chars, lines
	     "" 0 0
	     ;; xref
	     (concat parent (match-string (nth 0 numbers))))
	    headers))
    headers))

(luna-define-method shimbun-get-headers ((shimbun shimbun-asahi)
					 &optional range)
  (shimbun-asahi-get-headers shimbun))

(defun shimbun-asahi-make-contents (entity header)
  "Return article contents with a correct date header."
  (let ((case-fold-search t)
	start date)
    (when (and (re-search-forward (shimbun-content-start-internal entity)
				  nil t)
	       (setq start (point))
	       (re-search-forward (shimbun-content-end-internal entity)
				  nil t))
      (delete-region (match-beginning 0) (point-max))
      (delete-region (point-min) start)
      (when (and (member (shimbun-current-group-internal entity)
			 '("science"))
		 (string-match " \\(00:00\\) "
			       (setq date (shimbun-header-date header))))
	(setq start (match-beginning 1))
	(goto-char (point-max))
	(forward-line -1)
	(when (re-search-forward
	       "([01][0-9]/[0-3][0-9] \\([012][0-9]:[0-5][0-9]\\))"
	       nil t)
	  (shimbun-header-set-date header
				   (concat (substring date 0 start)
					   (match-string 1)
					   (substring date (+ start 5))))))
      (goto-char (point-min))
      (insert "<html>\n<head>\n<base href=\""
	      (shimbun-header-xref header) "\">\n</head>\n<body>\n")
      (goto-char (point-max))
      (insert "\n</body>\n</html>\n"))
    (shimbun-make-mime-article entity header)
    (buffer-string)))

(luna-define-method shimbun-make-contents ((shimbun shimbun-asahi)
					   header)
  (shimbun-asahi-make-contents shimbun header))

(provide 'sb-asahi)

;;; sb-asahi.el ends here

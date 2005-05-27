;;; sb-mainichi.el --- shimbun backend for MSN-Mainichi -*- coding: iso-2022-7bit; -*-

;; Copyright (C) 2001, 2002, 2003, 2004, 2005
;; Koichiro Ohba <koichiro@meadowy.org>

;; Author: Koichiro Ohba <koichiro@meadowy.org>
;;         Katsumi Yamaoka <yamaoka@jpl.org>
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

;; Original code was sb-yomiuri.el which is written by
;; TSUCHIYA Masatoshi <tsuchiya@namazu.org> and
;; Yuuichi Teranishi <teranisi@gohome.org>

;;; Code:

(require 'shimbun)

(luna-define-class shimbun-mainichi (shimbun-japanese-newspaper shimbun) ())

(defvar shimbun-mainichi-prefer-text-plain nil
  "*Non-nil means prefer text/plain articles rather than html articles.")

(defvar shimbun-mainichi-top-level-domain "mainichi-msn.co.jp"
  "Name of the top level domain for the MSN-Mainichi INTERACTIVE.")

(defvar shimbun-mainichi-url
  (concat "http://www." shimbun-mainichi-top-level-domain "/")
  "Name of the parent url.")

(defvar shimbun-mainichi-group-table
  (let* ((s0 "[\t\n ]*")
	 (s1 "[\t\n ]+")
	 (column (list
		  (concat
		   "<a" s1 "href=\"/"
		   ;; 1. url
		   "\\(column/[^/]+/news/"
		   ;; 2. serial number
		   "\\("
		   ;; 3. year
		   "\\(20[0-9][0-9]\\)"
		   ;; 4. month
		   "\\([01][0-9]\\)"
		   ;; 5. day
		   "\\([0-3][0-9]\\)"
		   "[^.]+\\)"
		   "\\.html\\)"
		   "\"[^>]*>" s0
		   ;; 6. subject
		   "\\([^<]+\\)"
		   s0 "<")
		  1 nil 2 3 4 5 6))
	 (default (list
		   (concat
		    "<a" s1 "href=\"/"
		    ;; 1. url
		    "\\([^/]+/"
		    "\\(?:"
		    ;; 2. subgroup
		    "\\([^/]+\\)"
		    "/\\)?news/"
		    ;; 3. serial number
		    "\\("
		    ;; 4. year
		    "\\(20[0-9][0-9]\\)"
		    ;; 5. month
		    "\\([01][0-9]\\)"
		    ;; 6. day
		    "\\([0-3][0-9]\\)"
		    "[0-9a-z]+\\)"
		    "\\.html\\)"
		    "[^>]*>\\(?:" s0 "<[^>]+>\\)*" s0
		    ;; 7+8. subject
		    "\\([^<]+\\)\\(?:<br[^>]+>\\)?\\([^<]+\\)"
		    "\\(?:\\(?:" s0 "<[^>]+>\\)+" s0
		    ;; 9. hour
		    "\\([012]?[0-9]\\)"
		    ":"
		    ;; 10. minute
		    "\\([0-5]?[0-9]\\)"
		    "\\)?")
		   1 2 3 4 5 6 7 8 9 10)))
    `(("column.hassinbako" "$BH/?.H"(B" "column/hassinbako/" ,@column)
      ("column.hito" "$B$R$H(B" "column/hito/" ,@column)
      ("column.kishanome" "$B5-<T$NL\(B" "column/kishanome/" ,@column)
      ("column.shasetsu" "$B<R@b(B" "column/shasetsu/" ,@column)
      ("column.yoroku" "$BM>O?(B" "column/yoroku/" ,@column)
      ("geinou" "$B7]G=(B" nil ,@default)
      ("it" "IT" nil ,@default)
      ("kagaku.env" "$B4D6-(B" nil ,@default)
      ("kagaku.medical" "$B0e3X(B" nil ,@default)
      ("kagaku.science" "$B2J3X(B" nil ,@default)
      ("keizai" "$B7P:Q(B" nil ,@default)
      ("kokusai" "$B9q:](B" nil ,@default)
      ("kurashi" "$BJk$i$7(B" nil ,@default)
      ("seiji" "$B@/<#(B" nil ,@default)
      ("shakai" "$B<R2q(B" nil ,@default)
      ("shakai.edu" "$B650i(B" nil ,@default)
      ("sports" "$B%9%]!<%D(B" nil ,@default)))
  "Alist of group names, their Japanese translations, index pages,
regexps and numbers.  Where numbers point to the regexp search result
in order of [0]a url, [1]a subgroup, [2]a serial number, [3]a year,
\[4]a month, [5]a day, [6,7]a subject, [8]an hour and [9]a minute.")

(defvar shimbun-mainichi-server-name "$BKhF|?7J9(B")
(defvar shimbun-mainichi-from-address "nobody@example.com")
(defvar shimbun-mainichi-content-start
  "<!--[\t\n ]+START[\t\n ]+Article[\t\n ]+-->[\t\n ]*")
(defvar shimbun-mainichi-content-end
  "\\(?:[\t\n ]*<[^>]+>\\)*[\t\n ]*<!--[\t\n ]+END[\t\n ]+Article[\t\n ]+-->")

(defvar shimbun-mainichi-x-face-alist
  '(("default" . "\
Face: iVBORw0KGgoAAAANSUhEUgAAABwAAAAcBAMAAACAI8KnAAAABGdBTUEAALGPC/xhBQAAABh
 QTFRFC2zfDGzfEnDgJn3iU5fnj7vvzuH4+vz++nlsOQAAAC90RVh0U29mdHdhcmUAWFYgVmVyc2l
 vbiAzLjEwYStGTG1hc2sgIFJldjogMTIvMjkvOTQbx6p8AAABA0lEQVR4nGWRPW+DMBiED5vuqK0
 60yppVwQ0rFTYZo348poSA3uDzd/vCxNNT14en1/5zgZYEoCF69rk2zhWPR6GADwCl864tsaHFUJ
 dweTJuMcQZZ0kRQxkqnaHik2DbBwdVuPgtPG7WTcuhPdshdM5f7lp4SpyXUPoazu1i6HZpbY6R3a
 ZhAW8ztmZsDxPqf0Cb6zsVzQjJQA/2GNE2OWHbqaQvEggI7wFfOmxk1esLUL2GrJg2yBkrTSDqvB
 eJKmhqtNpttk3sllICskmdbXlGdkPNcd/TIuuvOxcM65IsxvSa2Q79w7V8AfL2u1nY9ZquuiWfK7
 1BSVNQzxF9B+40y/ui1KdNxt0ugAAAAd0SU1FB9QEDQAjJMA7GTQAAAAASUVORK5CYII=")))

(defvar shimbun-mainichi-expiration-days 7)

(luna-define-method shimbun-groups ((shimbun shimbun-mainichi))
  (mapcar 'car shimbun-mainichi-group-table))

(luna-define-method shimbun-current-group-name ((shimbun shimbun-mainichi))
  (nth 1 (assoc (shimbun-current-group-internal shimbun)
		shimbun-mainichi-group-table)))

(luna-define-method shimbun-index-url ((shimbun shimbun-mainichi))
  (shimbun-expand-url
   (or (nth 2 (assoc (shimbun-current-group-internal shimbun)
		     shimbun-mainichi-group-table))
       (concat (shimbun-subst-char-in-string
		?. ?/ (shimbun-current-group-internal shimbun))
	       "/"))
   (shimbun-url-internal shimbun)))

(defun shimbun-mainichi-make-date-string (&rest args)
  "Run `shimbun-make-date-string' with ARGS and fix a day if needed.

\(shimbun-mainichi-make-date-string YEAR MONTH DAY &optional TIME TIMEZONE)"
  (if (equal (nth 3 args) "23:59:59")
      (apply 'shimbun-make-date-string args)
    (save-match-data
      (let* ((ctime (current-time))
	     (date (apply 'shimbun-make-date-string args))
	     (time (shimbun-time-parse-string date))
	     (ms (car time))
	     (ls (cadr time))
	     (system-time-locale "C"))
	(if (or (> ms (car ctime))
		(and (= ms (car ctime))
		     (> ls (cadr ctime))))
	    ;; It should be yesterday's same time.
	    (progn
	      (setq ms (1- ms))
	      (when (< (setq ls (- ls (eval-when-compile
					(- (* 60 60 24) 65536))))
		       0)
		(setq ms (1- ms)
		      ls (+ ls 65536)))
	      (format-time-string "%a, %d %b %Y %R +0900" (list ms ls)))
	  date)))))

(defun shimbun-mainichi-get-headers (shimbun)
  (let* ((group (shimbun-current-group-internal shimbun))
	 (hierarchy (when (string-match "\\." group)
		      (mapconcat 'identity
				 (nreverse (split-string group "\\."))
				 ".")))
	 (regexp (nthcdr 3 (assoc group shimbun-mainichi-group-table)))
	 (whole (string-match "\\`column\\." group))
	 (from (concat (shimbun-server-name shimbun)
		       " (" (shimbun-current-group-name shimbun) ")"))
	 (case-fold-search t)
	 url urls numbers subgroup header topnews headers date)
    (setq numbers (cdr regexp)
	  regexp (car regexp))
    (shimbun-strip-cr)
    (goto-char (point-min))
    (while (and (not (eobp))
		(or whole
		    (re-search-forward "\
<!--[\t\n ]*MEROS[\t\n ]+START[\t\n ]+Module=[^>]+>"
				       nil t)))
      (narrow-to-region (point)
			(if whole
			    (point-max)
			  (or (re-search-forward "\
<!--[\t\n ]*MEROS[\t\n ]+END[\t\n ]+Module[^>]+>"
						 nil t)
			      (point-max))))
      (goto-char (point-min))
      (while (re-search-forward regexp nil t)
	(unless ;; Exclude duplications.
	    (member (setq url (file-name-nondirectory
			       (match-string (nth 0 numbers))))
		    urls)
	  (push url urls)
	  (setq subgroup (when (nth 1 numbers)
			   (match-string (nth 1 numbers))))
	  (setq header
		(shimbun-create-header
		 0
		 (concat (match-string (nth 6 numbers))
			 (when (nth 7 numbers)
			   (match-string (nth 7 numbers))))
		 from
		 (shimbun-mainichi-make-date-string
		  (string-to-number (match-string (nth 3 numbers)))
		  (string-to-number (match-string (nth 4 numbers)))
		  (string-to-number (match-string (nth 5 numbers)))
		  (if (and (nth 9 numbers)
			   (match-beginning (nth 9 numbers)))
		      (format
		       "%02d:%02d"
		       (string-to-number (match-string (nth 8 numbers)))
		       (string-to-number (match-string (nth 9 numbers))))
		    (when (and (nth 1 numbers)
			       (not subgroup))
		      ;; It may be a top news.
		      "23:59:59")))
		 (concat "<" (match-string (nth 2 numbers)) "%"
			 (or hierarchy
			     (concat (or subgroup "top") "." group))
			 "." shimbun-mainichi-top-level-domain ">")
		 "" 0 0
		 (concat shimbun-mainichi-url (match-string (nth 0 numbers)))))
	  (unless subgroup
	    (push header topnews))
	  (push header headers)))
      (goto-char (point-max))
      (widen))
    (prog1
	(shimbun-sort-headers headers)
      ;; Fix date headers for top news.
      (while topnews
	(setq header (pop topnews)
	      date (shimbun-header-date header))
	(when (string-match "23:59:59" date)
	  (shimbun-header-set-date header
				   (replace-match "00:00" nil nil date)))))))

(luna-define-method shimbun-get-headers ((shimbun shimbun-mainichi)
					 &optional range)
  (shimbun-mainichi-get-headers shimbun))

(defun shimbun-mainichi-prepare-article (shimbun header)
  (shimbun-with-narrowed-article
   shimbun
   ;; Remove the subject lines.
   (when (re-search-forward "<\\([0-9a-z]+\\)[\t\n ]+class=\"m-title" nil t)
     (let ((start (match-beginning 0)))
       (when (search-forward (concat "</" (match-string 1) ">") nil t)
	 (delete-region start (point)))))
   ;; Fix the Date header.
   (when (re-search-forward
	  (eval-when-compile
	    (let ((s0 "[\t\n $B!!(B]*")
		  (s1 "[\t\n $B!!(B]+"))
	      (concat "<span" s1 "class=\"m-txt[^>]+\">" s0 "$BKhF|?7J9(B" s1
		      ;; 1. year
		      "\\(20[0-9][0-9]\\)"
		      s0 "$BG/(B" s0
		      ;; 2. month
		      "\\([01]?[0-9]\\)"
		      s0 "$B7n(B" s0
		      ;; 3. day
		      "\\([0-3]?[0-9]\\)"
		      s0 "$BF|(B" s0
		      ;; 4. hour
		      "\\([012]?[0-9]\\)"
		      s0 "$B;~(B" s0
		      ;; 5. minute
		      "\\([0-5]?[0-9]\\)"
		      s0 "$BJ,(B")))
	  nil t)
     (shimbun-header-set-date
      header
      (shimbun-make-date-string
       (string-to-number (match-string 1))
       (string-to-number (match-string 2))
       (string-to-number (match-string 3))
       (format "%02d:%02d"
	       (string-to-number (match-string 4))
	       (string-to-number (match-string 5))))))
   ;; Break continuous lines.
   (when (or (string-equal "column.yoroku"
			   (shimbun-current-group-internal shimbun))
	     (string-match "\\`$BM>O?!'(B" (shimbun-header-subject header
							       'no-encode)))
     (goto-char (point-min))
     (while (search-forward "$B"%(B" nil t)
       (replace-match "$B!#(B<br><br>$B!!(B")))
   (if (shimbun-prefer-text-plain-internal shimbun)
       (let (footer)
	 ;; Open paragraphs.
	 (goto-char (point-min))
	 (while (re-search-forward
		 "[\t\n ]*</p>[\t\n ]*<p[\t\n ]+class=\"article\">[\t\n ]*"
		 nil t)
	   (replace-match "<br><br>"))
	 ;; Fix the position of the footer.
	 (require 'sb-text) ;; `shimbun-fill-column'
	 (goto-char (point-min))
	 (when (re-search-forward
		(eval-when-compile
		  (let ((s0 "[\t\n $B!!(B]*")
			(s1 "[\t\n $B!!(B]+"))
		    (concat s0 "\\(?:<[^>]+>" s0 "\\)*"
			    "<span" s1 "class=\"m-txt1\">" s0
			    "\\([^<]+\\)"
			    "\\(?:" s0 "</span>" s0
			    "\\(?:<[^!>]+>" s0 "\\)*\\)?")))
		nil t)
	   (setq footer (match-string 1))
	   (delete-region (match-beginning 0) (match-end 0))
	   (insert "<br><br>"
		   (make-string (max (- (symbol-value 'shimbun-fill-column)
					(string-width footer))
				     0)
				? )
		   footer "<br>")))
     ;; Break long lines.
     (shimbun-break-long-japanese-lines))))

(luna-define-method shimbun-make-contents :before ((shimbun shimbun-mainichi)
						   header)
  (shimbun-mainichi-prepare-article shimbun header))

(provide 'sb-mainichi)

;;; sb-mainichi.el ends here

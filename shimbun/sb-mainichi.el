;;; sb-mainichi.el --- shimbun backend for www.mainichi.co.jp -*- coding: iso-2022-7bit; -*-

;; Copyright (C) 2001, 2002, 2003 Koichiro Ohba <koichiro@meadowy.org>

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
(require 'sb-text)

(luna-define-class shimbun-mainichi (shimbun shimbun-text) ())

(defvar shimbun-mainichi-url "http://www.mainichi.co.jp/")
(defvar shimbun-mainichi-groups '("shakai" "sports" "seiji" "keizai"
				  "kokusai" "fuho"))
(defvar shimbun-mainichi-from-address  "webmaster@mainichi.co.jp")
(defvar shimbun-mainichi-content-start "\n<font class=\"news-text\">\n")
(defvar shimbun-mainichi-content-end  "\n</font>\n")

(defvar shimbun-mainichi-group-path-alist
  '(("shakai" . "news/flash/shakai")
    ("sports" . "news/flash/sports")
    ("seiji"  . "news/flash/seiji")
    ("keizai" . "news/flash/keizai")
    ("kokusai" . "news/flash/kokusai")
    ("fuho"    . "news/flash/jinji")))
(defvar shimbun-mainichi-expiration-days 7)

(luna-define-method shimbun-index-url ((shimbun shimbun-mainichi))
  (concat (shimbun-url-internal shimbun)
	  (cdr (assoc (shimbun-current-group-internal shimbun)
		      shimbun-mainichi-group-path-alist))
	  "/index.html"))

(luna-define-method shimbun-get-headers ((shimbun shimbun-mainichi)
					 &optional range)
  (let ((case-fold-search t)
	start headers)
    (goto-char (point-min))
    (when (and (search-forward
		(format "\n<table bgcolor=\"#FFFFFF\" width=\"564\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\">\n"
			(shimbun-current-group-internal shimbun)) nil t)
	       (setq start (point))
	       (search-forward
		(format "\n</tr>\n</table>\n<br>\n<br>\n"
			(shimbun-current-group-internal shimbun)) nil t))
      (forward-line -1)
      (save-restriction
	(narrow-to-region start (point))
	(goto-char start)
	(while (re-search-forward
		"<a href=\"\\./\\(\\(\\([0-9][0-9][0-9][0-9]\\)\\([0-9][0-9]\\)\\([0-9][0-9]\\)\\([a-z]\\)\\([0-9][0-9][0-9][0-9]\\)\\([a-z]\\)\\([0-9][0-9][0-9][0-9][0-9]\\)\\([0-9][0-9][0-9][0-9]\\)\\([a-z]\\)\\)\\.html\\)\"[^>]*>"
		nil t)
	  (let ((url   (concat
			(cdr (assoc (shimbun-current-group-internal shimbun)
				    shimbun-mainichi-group-path-alist))
			"/"
			(match-string 1)))
		(id    (format "<%s%%%s>"
			       (match-string 2)
			       (shimbun-current-group-internal shimbun)))
		(year  (string-to-number (match-string 3)))
		(month (string-to-number (match-string 4)))
		(day   (string-to-number (match-string 5)))
		(subject (mapconcat
			  'identity
			  (split-string
			   (buffer-substring
			    (match-end 0)
			    (progn (search-forward "</FONT></td>" nil t) (point)))
			   "<[^>]+>")
			  ""))
		date)
	    (when (string-match "<FONT class=\"news-text\">" subject)
	      (setq subject (substring subject (match-end 0))))
	    (if (string-match "[0-9][0-9]:[0-9][0-9]" subject)
		(setq date (shimbun-make-date-string
			    year month day (match-string 0 subject))
		      subject (substring subject 0 (match-beginning 0)))
	      (setq date (shimbun-make-date-string year month day)))
	    (push (shimbun-make-header
		   0
		   (shimbun-mime-encode-string subject)
		   (shimbun-from-address-internal shimbun)
		   date id "" 0 0 (concat
				   (shimbun-url-internal shimbun)
				   url))
		  headers)))))
    headers))

(luna-define-method shimbun-make-contents ((shimbun shimbun-mainichi)
					   header)
  (let ((case-fold-search t)
	start)
    (when (and (re-search-forward shimbun-mainichi-content-start
				  nil t)
	       (setq start (point))
	       (re-search-forward shimbun-mainichi-content-end
				  nil t))
      (delete-region (match-beginning 0) (point-max))
      (delete-region (point-min) start)
      (goto-char (point-min))
      (when (re-search-forward "<p>$B!NKhF|?7J9#1(B?[$B#0(B-$B#9(B]$B7n(B[$B#1(B-$B#3(B]?[$B#0(B-$B#9(B]$BF|!O(B\
  ( \\(20[0-9][0-9]\\)-\\([01][0-9]\\)-\\([0-3][0-9]\\)-\
\\([0-2][0-9]:[0-5][0-9]\\) )</p>"
			       nil t)
	(shimbun-header-set-date
	 header
	 (shimbun-make-date-string
	  (string-to-number (match-string 1))
	  (string-to-number (match-string 2))
	  (string-to-number (match-string 3))
	  (match-string 4)))
	(goto-char (point-min)))
      (insert "<html>\n<head>\n<base href=\""
	      (shimbun-header-xref header) "\">\n</head>\n<body>\n")
      (goto-char (point-max))
      (insert "\n</body>\n</html>\n"))
    (shimbun-make-mime-article shimbun header)
    (buffer-string)))

(provide 'sb-mainichi)

;;; sb-mainichi.el ends here

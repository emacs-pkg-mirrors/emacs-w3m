;;; sb-wired.el --- shimbun backend for Wired Japan

;; Copyright (C) 2001 Yuuichi Teranishi <teranisi@gohome.org>

;; Author: TSUCHIYA Masatoshi <tsuchiya@namazu.org>,
;;         Yuuichi Teranishi <teranisi@gohome.org>
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
(require 'sb-lump)

(luna-define-class shimbun-wired (shimbun-lump) ())

(defvar shimbun-wired-url "http://www.hotwired.co.jp/")
(defvar shimbun-wired-groups '("business" "culture" "technology"))
(defvar shimbun-wired-from-address "webmaster@www.hotwired.co.jp")
(defvar shimbun-wired-content-start
  "\\(\n<!-- articles -->\\|<FONT color=\"#ff0000\" size=\"-1\">.*</FONT>\\)\n")
(defvar shimbun-wired-content-end "\\(\n<!-- /articles -->\n\\|<DIV ALIGN=\"RIGHT\">\\[\\)")
(defvar shimbun-wired-x-face-alist
  '(("default" . "X-Face: \"yhMDxMBowCFKt;5Q$s_Wx)/'L][0@c\"#n\
2BwH{7mg]5^w1D]\"K^R]&fZ5xtt1Ynu6V;Cv(\n @BcZUf9IV$($6TZ`L)$,c\
egh`b:Uwy`8}#Db-kyCsr_UMRz=,U|>-:&`05lXB4(;h{[&~={Imb-az7\n &U\
5?|&X_8c;#'L|f.P,]|\\50pgSVw_}byL+%m{TrS[\"Ew;dbskaBL[ipk2m4V")))
(defvar shimbun-wired-expiration-days 7)

(luna-define-method shimbun-get-group-header-alist ((shimbun shimbun-wired)
						    &optional range)
  (let ((group-header-alist (mapcar (lambda (g) (cons g nil))
				    (shimbun-groups-internal shimbun)))
	(case-fold-search t)
	(regexp (format
		 "<a href=\"\\(%s\\|/\\)\\(news/news/\\(%s\\)/story/\\(\\([0-9][0-9][0-9][0-9]\\)\\([0-9][0-9]\\)\\([0-9][0-9]\\)[0-9]+\\)\\.html\\)[^>]*\">"
		 (regexp-quote (shimbun-url-internal shimbun))
		 (shimbun-regexp-opt (shimbun-groups-internal shimbun))))
	ids)
    (dolist (xover (list (concat (shimbun-url-internal shimbun)
				 "news/news/index.html")
			 (concat (shimbun-url-internal shimbun)
				 "news/news/last_seven.html")))
      (with-temp-buffer
	(shimbun-retrieve-url xover t)
	(goto-char (point-min))
	(search-forward "<!-- articles -->" nil t) ; Jump to article list.
	(while (re-search-forward regexp nil t)
	  (let* ((url   (concat (shimbun-url-internal shimbun)
				(match-string 2)))
		 (group (downcase (match-string 3)))
		 (id    (format "<%s%%%s>" (match-string 4) group))
		 (date  (shimbun-make-date-string
			 (string-to-number (match-string 5))
			 (string-to-number (match-string 6))
			 (string-to-number (match-string 7))))
		 (header (shimbun-make-header
			  0
			  (shimbun-mime-encode-string
			   (mapconcat 'identity
				      (split-string
				       (buffer-substring
					(match-end 0)
					(progn (search-forward "</b>" nil t) (point)))
				       "<[^>]+>")
				      ""))
			  (shimbun-from-address shimbun)
			  date id "" 0 0 url))
		 (x (assoc group group-header-alist)))
	    (unless (member id ids)
	      (setq ids (cons id ids))
	      (setcdr x (cons header (cdr x))))))))
    group-header-alist))

(provide 'sb-wired)

;;; sb-wired.el ends here

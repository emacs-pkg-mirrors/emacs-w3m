;;; sb-impress.el --- shimbun backend for www.watch.impress.co.jp -*- coding: iso-2022-7bit; -*-

;; Copyright (C) 2001, 2002, 2003, 2004 Yuuichi Teranishi <teranisi@gohome.org>

;; Author: Yuuichi Teranishi <teranisi@gohome.org>
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

;;; Code:
(require 'shimbun)
(luna-define-class shimbun-impress (shimbun) ())

(defvar shimbun-impress-url "http://www.watch.impress.co.jp/")

(defvar shimbun-impress-groups-alist
  '(("internet" "<a href=\"\\(cda/news/\\([0-9][0-9][0-9][0-9]\\)/\\([0-9][0-9]\\)/\\([0-9][0-9]\\)/\\([^>]*\\)\\)\">" "<!-- $BK\J83+;O(B -->" "<!-- $BK\J8=*N;(B -->" "http://internet.watch.impress.co.jp/")
    ("pc" "<a href=\"\\(docs/\\([0-9][0-9][0-9][0-9]\\)/\\([0-9][0-9]\\)\\([0-9][0-9]\\)/\\([^>]*\\)\\)\">" "<!-- $B5-;v8+=P$7(B -->" "<!-- /$B5-;v=pL>(B -->" "http://pc.watch.impress.co.jp/")
    ("akiba" "<a href=\"\\(hotline/\\([0-9][0-9][0-9][0-9]\\)\\([0-9][0-9]\\)\\([0-9][0-9]\\)/\\([^>]*\\)\\)\">" "<!-- $B",",!!!z(B2002/10/01 Modify End$B!z!!",",(B -->" "\\(<!-- $B"-"-!!!z(B2002/10/01 Modify start$B!z!!"-"-(B -->\\|<!-- 500x144 -->\\)")
    ("game" "<a href=\"\\(docs/\\([0-9][0-9][0-9][0-9]\\)\\([0-9][0-9]\\)\\([0-9][0-9]\\)/\\([^>]*\\)\\)\">" "\\(<tr>\n<td valign=TOP>\\|<!-- $BK\J83+;O(B -->\\)" "<!-- /$B5-;v=pL>(B -->")
    ("av" "<a href=\"\\(docs/\\([0-9][0-9][0-9][0-9]\\)\\([0-9][0-9]\\)\\([0-9][0-9]\\)/\\([^>]*\\)\\)\">" "\\(<!-- title -->\\|<hr size=3>\\)" "\\(<!-- /$B5-;v=pL>(B -->\\|<!-- 500x144 -->\\)")
    ))

(defvar shimbun-impress-groups (mapcar 'car shimbun-impress-groups-alist))
(defvar shimbun-impress-from-address "www-admin@impress.co.jp")
(defvar shimbun-impress-x-face-alist
  '(("default" . "X-Face: F3zvh@X{;Lw`hU&~@uiX9J0dwTeROiIz\
oSoe'Y.gU#(EqHA5K}v}2ah,QlHa[S^}5ZuTefR\n ZA[pF1_ZNlDB5D_D\
JzTbXTM!V{ecn<+l,RDM&H3CKdu8tWENJlbRm)a|Hk+limu}hMtR\\E!%r\
9wC\"6\n ebr5rj1[UJ5zDEDsfo`N7~s%;P`\\JK'#y.w^>K]E~{`wZru")))
;;(defvar shimbun-impress-expiration-days 7)

(luna-define-method shimbun-index-url ((shimbun shimbun-impress))
  (or (nth 4 (assoc (shimbun-current-group-internal shimbun)
		    shimbun-impress-groups-alist))
      (concat (shimbun-url-internal shimbun)
	      (shimbun-current-group-internal shimbun) "/")))

(luna-define-method shimbun-get-headers ((shimbun shimbun-impress)
					 &optional range)
  (let ((case-fold-search t)
	(regexp (nth 1 (assoc (shimbun-current-group-internal shimbun)
			      shimbun-impress-groups-alist)))
	ids
	headers)
    (goto-char (point-min))
    (while (re-search-forward regexp nil t)
      (let ((apath (match-string 1))
	    (year  (string-to-number (match-string 2)))
	    (month (string-to-number (match-string 3)))
	    (mday  (string-to-number (match-string 4)))
	    (uniq  (match-string 5))
	    (pos (point))
	    subject
	    id)
	(when (re-search-forward "</a>" nil t)
	  (setq subject (buffer-substring pos (match-beginning 0))
		subject (with-temp-buffer
			  (insert subject)
			  (goto-char (point-min))
			  (while (re-search-forward "[\r\n]" nil t)
			    (replace-match ""))
			  (shimbun-remove-markup)
			  (buffer-string))))
	(setq id (format "<%d%d%d%s%%%s@www.watch.impress.co.jp>"
			 year month mday uniq (shimbun-current-group-internal
					       shimbun)))
	(unless (member id ids)
	  (setq ids (cons id ids))
	  (push (shimbun-create-header
		 0
		 (or subject "")
		 (shimbun-from-address shimbun)
		 (shimbun-make-date-string year month mday)
		 id
		 "" 0 0
		 (shimbun-expand-url apath (shimbun-index-url shimbun)))
		headers))))
    headers))

(luna-define-method shimbun-make-contents :around ((shimbun shimbun-impress)
						   &optional header)
  (let ((entry (assoc (shimbun-current-group-internal shimbun)
		      shimbun-impress-groups-alist)))
    (shimbun-set-content-start-internal shimbun (nth 2 entry))
    (shimbun-set-content-end-internal shimbun (nth 3 entry))
    (luna-call-next-method)))

(provide 'sb-impress)

;;; sb-impress.el ends here

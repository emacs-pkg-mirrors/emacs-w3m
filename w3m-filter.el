;;; w3m-filter.el --- filtering utility of advertisements on WEB sites.

;; Copyright (C) 2001, 2002, 2003 TSUCHIYA Masatoshi <tsuchiya@namazu.org>

;; Authors: TSUCHIYA Masatoshi <tsuchiya@namazu.org>
;; Keywords: w3m, WWW, hypermedia

;; This file is a part of emacs-w3m.

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

;; w3m-filter.el is the add-on utility to filter advertisements on WEB
;; sites.


;;; Code:

(provide 'w3m-filter)
(require 'w3m)

(defcustom w3m-filter-rules
  `(("\\`http://www\\.geocities\\.co\\.jp/Technopolis/"
     w3m-filter-delete-regions
     "<DIV ALIGN=CENTER>\n<!--*/GeoGuide/*-->" "<!--*/GeoGuide/*-->\n</DIV>")
    ("\\`http://[a-z]+\\.hp\\.infoseek\\.co\\.jp/"
     w3m-filter-delete-regions
     "<!-- START_AD_Banner -->" "<!-- END_AD_Banner -->")
    ("\\`http://linux\\.ascii24\\.com/linux/"
     w3m-filter-delete-regions
     "<!-- DAC CHANNEL AD START -->" "<!-- DAC CHANNEL AD END -->")
    ("\\`http://www\\.google\\.com/search"
     w3m-filter-find-relationships
     "<a href=\\([^>]+\\)><img src=/\\(intl/[^/]+/\\)nav_next.gif"
     "<a href=\\([^>]+\\)><img src=/\\(intl/[^/]+/\\)nav_previous.gif")
    ("\\`http://www\\.zdnet\\.co\\.jp/news/"
     w3m-filter-find-relationships
     ,(concat "<a href=\\(" w3m-html-string-regexp "\\)>$B<!$N%Z!<%8(B</a>")
     ,(concat "<a href=\\(" w3m-html-string-regexp "\\)>$BA0$N%Z!<%8(B</a>"))
    ("\\`http://www\\.asahi\\.com/" w3m-filter-asahi-shimbun))
  "Rules to filter advertisements on WEB sites."
  :group 'w3m
  :type '(repeat
	  (cons :format "%v" :indent 4
		(regexp :format "Regexp: %v\n" :size 0)
		(choice
		 :tag "Filtering Rule"
		 (list :tag "Delete regions surrounded with these patterns"
		       (function-item :format "" w3m-filter-delete-region)
		       (regexp :tag "Start")
		       (regexp :tag "End"))
		 (list :tag "Find relationships with these patterns"
		       (function-item :format "" w3m-filter-find-relationships)
		       (regexp :tag "Next")
		       (regexp :tag "Previous"))
		 (list :tag "Filter with a user defined function"
		       function
		       (repeat :tag "Arguments" sexp))))))

;;;###autoload
(defun w3m-filter (url)
  "Exec filtering rule of URL to contents in this buffer."
  (save-match-data
    (catch 'apply-filtering-rule
      (dolist (elem w3m-filter-rules)
	(when (string-match (car elem) url)
	  (throw 'apply-filtering-rule
		 (apply (cadr elem) url (cddr elem))))))))

(defun w3m-filter-delete-regions (url start end)
  "Delete regions surrounded with a START pattern and an END pattern."
  (goto-char (point-min))
  (let (p (i 0))
    (while (and (search-forward start nil t)
		(setq p (match-beginning 0))
		(search-forward end nil t))
      (delete-region p (match-end 0))
      (incf i))
    (> i 0)))

(defun w3m-filter-find-relationships (url next previous)
  "Search relationships with a NEXT pattern and a PREVIOUS pattern."
  (goto-char (point-max))
  (and (not w3m-next-url)
       (re-search-backward next nil t)
       (setq w3m-next-url (w3m-expand-url (match-string 1) url)))
  (and (not w3m-previous-url)
       (re-search-backward previous nil t)
       (setq w3m-previous-url (w3m-expand-url (match-string 1) url))))

;; Filter functions:
(defun w3m-filter-asahi-shimbun (url)
  "Convert entity reference of UCS."
  (when w3m-use-mule-ucs
    (goto-char (point-min))
    (let ((case-fold-search t)
	  end ucs)
      (while (re-search-forward "alt=\"\\([^\"]+\\)" nil t)
	(goto-char (match-beginning 1))
	(setq end (match-end 1))
	(while (re-search-forward "&#\\([0-9]+\\);" end t)
	  (setq ucs (string-to-number (match-string 1)))
	  (delete-region (match-beginning 0) (match-end 0))
	  (insert-char (w3m-ucs-to-char ucs) 1))))))

;;; w3m-filter.el ends here.

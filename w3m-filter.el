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
  '(("http://www.geocities.co.jp/Technopolis/"
     "<DIV ALIGN=CENTER>\n<!--*/GeoGuide/*-->" "<!--*/GeoGuide/*-->\n</DIV>")
    ("http://linux.ascii24.com/linux/"
     "<!-- DAC CHANNEL AD START -->" "<!-- DAC CHANNEL AD END -->")
    ("http://lwn.net/" . w3m-filter-lwn.net)
    ("http://www.google.com/search" . w3m-filter-google.com)
    ("http://www.zdnet.co.jp/news/" . w3m-filter-www.zdnet.co.jp)
    ("http://www.asahi.com/" . w3m-filter-asahi-shimbun))
  "Rules to filter advertisements on WEB sites."
  :group 'w3m
  :type '(repeat
	  (group
	   :indent 4 :inline t
	   (cons
	    :format "%v" :offset 2
	    (string :format "URL: %v\n" :size 0)
	    (choice
	     :format "%[Value Menu%] %v"
	     (list :tag "Start and End patterns"
		   (string :size 0 :format "Start: %v\n")
		   (string :size 0 :format "  End: %v\n"))
	     (function :format "Filtering function:\n      Function: %v\n"
		       :size 0
		       :value-to-internal
		       (lambda (widget value)
			 (widget-sexp-value-to-internal
			  widget (if (functionp value) value 'ignore)))))))))


(defvar w3m-filter-db nil) ; nil means non-initialized.
(defconst w3m-filter-db-size 1023)

;; FIXME: In fact, the function which analyzes URL exactly is required.
(defconst w3m-filter-server-regexp "^\\([-+.A-z0-9]+://[^/]+/\\)")


(defun w3m-filter-setup ()
  "Initialize hash database of filtering rules."
  (unless w3m-filter-db
    (let ((db (make-vector w3m-filter-db-size 0)))
      (dolist (site w3m-filter-rules)
	(let* ((url (car site))
	       (func (cdr site))
	       (server (when (string-match w3m-filter-server-regexp url)
			 (match-string 1 url)))
	       (ident (intern server db)))
	  (unless (symbolp func)
	    ;; Process simple filtering rules.
	    (setq func (` (lambda (&rest args)
			    (w3m-filter-delete-region
			     (, (nth 1 site))
			     (, (nth 2 site)))))))
	  (set ident
	       (cons (cons (concat "^" (regexp-quote url)) func)
		     (when (boundp ident)
		       (symbol-value ident))))))
      (setq w3m-filter-db db))))

;;;###autoload
(defun w3m-filter (url)
  "Exec filtering rule of URL to contents in this buffer."
  (w3m-filter-setup)
  (and (stringp url)
       (string-match w3m-filter-server-regexp url)
       (let ((ident (intern-soft (match-string 1 url) w3m-filter-db)))
	 (when ident
	   (let (functions)
	     (dolist (site (symbol-value ident) nil)
	       (when (string-match (car site) url)
		 (push (cdr site) functions)))
	     (save-match-data
	       (run-hook-with-args-until-success 'functions url)))))))

(defun w3m-filter-delete-region (start end)
  "Delete region from START pattern to END pattern."
  (goto-char (point-min))
  (let (p)
    (and (search-forward start nil t)
	 (setq p (match-beginning 0))
	 (search-forward end nil t)
	 (progn
	   (delete-region p (match-end 0))
	   t))))


;; Filter functions:
(defun w3m-filter-lwn.net (url)
  "Filtering function of lwn.net."
  (goto-char (point-min))
  (let (p)
    (while (and (re-search-forward "<!-- Start of Ad ([-A-z0-9]+) -->" nil t)
		(setq p (match-beginning 0))
		(search-forward "<!-- End of Ad -->" nil t))
      (delete-region p (match-end 0))))
  (goto-char (point-min))
  (when (re-search-forward
	 "<a href=\"\\(/[0-9][0-9][0-9][0-9]/[0-9][0-9][0-9][0-9]/[A-z]+\\.php3\\)\"><img[^>]*>Next:"
	 nil t)
    (let ((next (match-string 1)))
      (goto-char (point-min))
      (when (search-forward "<head>" nil t)
	(insert "\n<link rel=\"next\" href=\"" next "\">"))))
  t)

(defun w3m-filter-google.com (url)
  "Add <LINK> tag to search results of www.google.com."
  (goto-char (point-max))
  (let ((next (when (re-search-backward
		     "<a href=\\([^>]+\\)><img src=/\\(intl/[^/]+/\\)nav_next.gif"
		     nil t)
		(match-string 1)))
	(prev (when (re-search-backward
		     "<a href=\\([^>]+\\)><img src=/\\(intl/[^/]+/\\)nav_previous.gif"
		     nil t)
		(match-string 1))))
    (goto-char (point-min))
    (when (search-forward "<head>" nil t)
      (when prev (insert "\n<link rel=\"prev\" href=\"" prev "\">"))
      (when next (insert "\n<link rel=\"next\" href=\"" next "\">")))
    t))

(defun w3m-filter-www.zdnet.co.jp (url)
  (goto-char (point-max))
  (let ((next (when (re-search-backward
		     (eval-when-compile
		       (concat
			"<a href=\\(" w3m-html-string-regexp "\\)>$B<!$N%Z!<%8(B</a>"))
		     nil t)
		(match-string 1)))
	(prev (when (re-search-backward
		     (eval-when-compile
		       (concat
			"<a href=\\(" w3m-html-string-regexp "\\)>$BA0$N%Z!<%8(B</a>"))
		     nil t)
		(match-string 1))))
    (goto-char (point-min))
    (when (search-forward "<head>" nil t)
      (when prev (insert "\n<link rel=\"prev\" href=" prev ">"))
      (when next (insert "\n<link rel=\"next\" href=" next ">")))
    t))

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

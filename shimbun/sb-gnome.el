;;; sb-gnome.el --- shimbun backend for mail.gnome.org

;; Author: Yuuichi Teranishi <teranisi@gohome.org>

;; Keywords: news

;;; Copyright:

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
(require 'sb-mhonarc)

(luna-define-class shimbun-gnome (shimbun-mhonarc) ())

(defvar shimbun-gnome-url "http://mail.gnome.org/archives")
(defvar shimbun-gnome-groups
  '("balsa-list" "calendar-list" "cvs-commits-list" "foundation-announce"
    "foundation-list" "fplan-list" "gconf-list" "gdome" "gnome-1.4-list"
    "gnome-announce-list" "gnome-components-list" "gnome-db-list"
    "gnome-de" "gnome-debugger-list" "gnome-devel-list" "gnome-doc-list"
    "gnome-gui-list" "gnome-hackers" "gnome-hackers-readonly"
    "gnome-hackers-test" "gnome-i18n" "gnome-i18n-tools" "gnome-kde-list"
    "gnome-list" "gnome-office-list" "gnome-pilot-list" "gnome-sound-list"
    "gnome-themes-list" "gnome-ui-hackers" "gnome-web-list"
    "gnome-webmaster-list" "gnome-workshop-list" "gnomecc-list"
    "gnumeric-list" "gtk-app-devel-list" "gtk-devel-list" "gtk-doc-list"
    "gtk-i18n-list" "gtk-list" "gtk-perl-list" "guppi-list" "libart"
    "libart-hackers" "orbit-list" "vote" "wm-spec-list"
    "xml" "xslt"))
(defvar shimbun-ding-coding-system 'iso-8859-1)

(luna-define-method shimbun-index-url ((shimbun shimbun-gnome))
  (concat (shimbun-url-internal shimbun)
	  "/" (shimbun-current-group-internal shimbun) "/index.html"))

(luna-define-method shimbun-reply-to ((shimbun shimbun-gnome))
  (concat (shimbun-current-group-internal shimbun)
	  "@gnome.org"))

;; <A href="2001-March/date.html">
(luna-define-method shimbun-get-headers ((shimbun shimbun-gnome))
  (let ((case-fold-search t) headers months)
    (goto-char (point-min))
    (if (shimbun-use-entire-index-internal shimbun)
	(while (re-search-forward
		"<a href=\"\\([^/]+\\)/date.html\">" nil t)
	  (push (match-string 1) months))
      (if (re-search-forward
	   "<a href=\"\\([^/]+\\)/date.html\">" nil t)
	  (push (match-string 1) months)))
    (catch 'stop
      (dolist (month months)
	(shimbun-retrieve-url
	 (concat (shimbun-url-internal shimbun)
		 "/" (shimbun-current-group-internal shimbun)
		 "/" month "/date.html")
	 'reload 'binary)
	(set-buffer-multibyte t)
	(decode-coding-region (point-min) (point-max)
			      (shimbun-coding-system-internal shimbun))
	(let (date date-next date-parsed beg end subject id)
	  (goto-char (point-min))
	  (while (or date-next
		     (re-search-forward "<strong>\\([^<]+\\)</strong>" nil t))
	    (setq beg (match-end 0))
	    (setq date (or date-next (concat (match-string 1) " 00:00:00"
					     )))
	    (if (re-search-forward "<strong>\\([^<]+\\)</strong>" nil t)
		(progn
		  (setq date-next (concat (match-string 1) " 00:00:00"))
		  (setq end (point)))
	      (setq date-next nil)
	      (setq end (point-max)))
	    (save-restriction
	      (narrow-to-region beg end)
	      (goto-char (point-min))
	      (while (re-search-forward
		      "<li><a name=\"\\([0-9]+\\)\" href=\"\\(msg[0-9]+.html\\)\">\\([^<]*\\)</a>\\([^<]*\\)</li>" nil t)
		(save-match-data
		  (setq date-parsed (timezone-parse-date date)))
		(setq id (format "<%s%s%s%s%%%s@mail.gnome.org>"
				 (match-string 1)
				 (aref date-parsed 0)
				 (aref date-parsed 1)
				 (aref date-parsed 2)
				 (shimbun-current-group-internal shimbun)
				 (match-string 1)))
		(if (shimbun-search-id shimbun id)
		    (throw 'stop (nreverse headers)))
		(push
		 (shimbun-make-header
		  0
		  (save-match-data
		    (shimbun-mime-encode-string (match-string 3))) ; subject
		  (save-match-data
		    (shimbun-mime-encode-string (match-string 4))) ; from
		  date
		  id
		  "" 0 0
		  (concat
		   "/" (shimbun-current-group-internal shimbun)
		   "/" month "/" (match-string 2)))
		 headers))))))
      (nreverse headers))))

(provide 'sb-gnome)

;;; sb-gnome.el ends here

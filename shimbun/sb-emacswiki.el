;;; sb-emacswiki.el --- emacswiki shimbun backend

;; Copyright (C) 2004 David Hansen

;; Author: David Hansen <david.hansen@physik.fu-berlin.de>
;; Keywords: news

;; This file is a part of shimbun.

;; This is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This program had been originally developed by David Hansen, and was
;; donated at May 7th, 2004.

;;; Code:

(require 'shimbun)
(require 'sb-rss)

(luna-define-class shimbun-emacswiki (shimbun-rss) ())

(defvar shimbun-emacswiki-url
  "http://www.emacswiki.org/cgi-bin/wiki.pl?action=rss")
(defvar shimbun-emacswiki-groups '("changes" "diff"))
(defvar shimbun-emacswiki-from-address  "invalid@emacswiki.org")
(defvar shimbun-emacswiki-content-start "<h1>")
(defvar shimbun-emacswiki-content-end "<div class=\"footer\">")

(defvar shimbun-emacswiki-x-face-alist
  '(("default" . "X-Face: 'Is?R.u_yTmkkPe(`Zyec$CF<xHX/m-bK|ROSqoD|DDW6;z&\
/T$@b=k:F#n>ri1KJ)/XVXzJ~!dA'H{,F+;f-IaJ$2~S9ZU6U@_\"%*YzLz8kAxsX3(q`>a&zos\
\\9.[2/gpE76Fim]r7o7hz&@@O#d{`BXdD)i]DQBW,Z]#$5YWYNT}@Y{cm}O}ev`l`QAeZI*NN<\
e2ibWOZWTFz8j~/m")))

(luna-define-method shimbun-index-url ((shimbun shimbun-emacswiki))
  shimbun-emacswiki-url)

(luna-define-method shimbun-get-headers :around ((shimbun shimbun-emacswiki)
						 &optional range)
  (let ((headers (luna-call-next-method)))
    (when (string= (shimbun-current-group shimbun) "diff")
      (dolist (header headers)
	(let ((url (shimbun-header-xref header)))
	  (when (string-match "id=.*?;\\(revision=[0-9]+\\)" url)
	    (shimbun-header-set-xref
	     header
	     (replace-match "diff=1" t nil url 1))))))
    headers))

(luna-define-method shimbun-rss-build-message-id
  ((shimbun shimbun-emacswiki) url date)
  (unless (string-match "id=\\(.*?\\);revision=\\([0-9]+\\)" url)
    (error "Cannot find message-id base"))
  (concat "<" (match-string 1 url) (match-string 2 url)
	  "%" (shimbun-current-group shimbun) "@emacswiki.org>"))

(provide 'sb-emacswiki)

;;; sb-emacswiki.el ends here

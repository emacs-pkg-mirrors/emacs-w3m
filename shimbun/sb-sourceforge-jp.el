;;; sb-sourceforge-jp.el --- shimbun backend for lists.sourceforge.jp

;; Copyright (C) 2003 TSUCHIYA Masatoshi <tsuchiya@namazu.org>

;; Author: TSUCHIYA Masatoshi <tsuchiya@namazu.org>
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
(require 'sb-mailman)

(luna-define-class shimbun-sourceforge-jp (shimbun-mailman) ())

(defcustom shimbun-sourceforge-jp-mailing-lists
  '(("aime-devel")
    ("anthy-dev")
    ("canna-dev")
    ("iiimf-skk-devel-ja" . "iiimf-skk-devel.ja")
    ("iiimf-skk-devel-en" . "iiimf-skk-devel.en")
    ("iiimf-skk-users-ja" . "iiimf-skk-users.ja")
    ("iiimf-skk-users-en" . "iiimf-skk-users.en")
    ("iiimf-skk-cvs-commit" . "iiimf-skk-cvs-commit"))
  "*List of mailing lists serverd by SourceForge-JP."
  :group 'shimbun
  :type '(repeat
	  (cons
	   (string :tag "Group Name")
	   (choice
	    (const :tag "Group Name and Mailing List Name are the same" nil)
	    (string :tag "Mailing List Name")))))

(defconst shimbun-sourceforge-jp-base-url
  "http://lists.sourceforge.jp/pipermail/"
  "Base URL of archives served by SourceForge-JP.")

(defconst shimbun-sourceforge-jp-coding-system 'euc-japan
  "Coding system used for archives of SourceForge-JP.")

(luna-define-method shimbun-groups ((shimbun shimbun-sourceforge-jp))
  (mapcar 'car shimbun-sourceforge-jp-mailing-lists))

(luna-define-method shimbun-index-url ((shimbun shimbun-sourceforge-jp))
  (let ((pair (assoc (shimbun-current-group-internal shimbun)
		     shimbun-sourceforge-jp-mailing-lists)))
    (shimbun-expand-url (or (cdr pair) (car pair))
			shimbun-sourceforge-jp-base-url)))

(provide 'sb-sourceforge-jp)

;;; sb-sourceforge-jp.el ends here

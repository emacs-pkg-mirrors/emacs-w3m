;;; sb-squeak-dev.el --- shimbun backend for Squeak-dev ML archive

;; Copyright (C) 2003 NAKAJIMA Mikio <minakaji@namazu.org>

;; Author: NAKAJIMA Mikio <minakaji@namazu.org>
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

(eval-when-compile
  (require 'cl))

(require 'shimbun)
(require 'sb-mailman)
(require 'sendmail)

(luna-define-class shimbun-squeak-dev (shimbun-mailman) ())

(defvar shimbun-squeak-dev-url
  "http://lists.squeakfoundation.org/pipermail/squeak-dev")

(defvar shimbun-squeak-dev-groups '("main"))

(luna-define-method shimbun-index-url ((shimbun shimbun-squeak-dev))
  shimbun-squeak-dev-url)

(luna-define-method shimbun-make-contents :after
  ((shimbun shimbun-squeak-dev) header)
  (save-excursion
    (let ((end (and (mail-position-on-field "From") (point)))
	  (begin (progn (beginning-of-line) (point)))
	  (marker (make-marker)))
      (when end
	(narrow-to-region begin end)
	(goto-char (point-min))
	(when (re-search-forward " at " nil t nil)
	  (set-marker marker (match-beginning 0))
	  (delete-region (match-beginning 0) (match-end 0))
	  (goto-char marker)
	  (insert "@"))
	(widen))))
  (buffer-string))

(provide 'sb-squeak-dev)
;;; sb-squeak-dev.el ends here

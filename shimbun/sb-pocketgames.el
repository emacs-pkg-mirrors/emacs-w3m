;;; sb-pocketgames.el --- shimbun backend class for www.pocketgames.jp. -*- coding: iso-2022-7bit; -*-

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

;;; Code:
(require 'shimbun)

(eval-and-compile
  (luna-define-class shimbun-pocketgames (shimbun) (content-hash))
  (luna-define-internal-accessors 'shimbun-pocketgames))

(defvar shimbun-pocketgames-content-hash-length 31)
(defvar shimbun-pocketgames-url "http://www.pocketgames.jp")
(defvar shimbun-pocketgames-groups '("news"))
(defvar shimbun-pocketgames-coding-system 'shift_jis)

(luna-define-method initialize-instance :after ((shimbun shimbun-pocketgames)
						&rest init-args)
  (shimbun-pocketgames-set-content-hash-internal
   shimbun
   (make-vector shimbun-pocketgames-content-hash-length 0))
  shimbun)

(luna-define-method shimbun-index-url ((shimbun shimbun-pocketgames))
  shimbun-pocketgames-url)

(luna-define-method shimbun-reply-to ((shimbun shimbun-pocketgames))
  "info@pocketgames.jp")

(defvar shimbun-pocketgames-expiration-days 6)

(luna-define-method shimbun-headers ((shimbun shimbun-pocketgames)
				     &optional range)
  (let ((case-fold-search t)
	(url (shimbun-index-url shimbun))
	from year month day time date
	next point subject id start end body headers)
    (with-temp-buffer
      (shimbun-retrieve-url url 'reload 'binary)
      (set-buffer-multibyte t)
      (decode-coding-region (point-min) (point-max)
			    (shimbun-coding-system-internal shimbun))
      (goto-char (point-min))
      (while (re-search-forward "\">\\([^<>]+\\)</a></font><br>" nil t nil)
	(catch 'next
	  (setq subject (match-string 1)
		start (point)
		end (re-search-forward "^<BR><BR>" nil t nil))
	  (goto-char start)
	  (unless
	      (re-search-forward
	       "Posted by: \\(.+\\) on \\([0-9]+\\)/\\([0-9]+\\)/\\([0-9]+\\) (\\($B7n(B\\|$B2P(B\\|$B?e(B\\|$BLZ(B\\|$B6b(B\\|$BEZ(B\\|$BF|(B\\))  - \\([0-9][0-9]:[0-9][0-9]\\) JST <\/font>"
	       end t nil)
	    (throw 'next nil))
	  (setq from (shimbun-mime-encode-string (match-string 1))
		year (string-to-number (match-string 2))
		month (string-to-number (match-string 3))
		day (string-to-number (match-string 4))
		time (match-string 6)
		date (shimbun-make-date-string year month day time))
	  (setq id (format "<%04d%02d%02d%s.news.pocketgames>"
		    year month day time)
		point (point)
		next (or (re-search-forward
			  "\">\\([^<>]+\\)</a></font><br>" nil t nil)
			 (point-max)))
	  (goto-char point)
	  (setq headers (shimbun-pocketgames-comment-article
			 shimbun headers url id next))
	  (when (shimbun-search-id shimbun id)
	    (throw 'next nil))
	  (with-temp-buffer
	    (insert subject)
	    (shimbun-remove-markup)
	    (setq subject (buffer-string)))
	  (setq start (re-search-forward
		       "^<TD ALIGN=\"left\" VALIGN=\"top\" CLASS=\"pn-normal\">"
		       end t nil))
	  (setq body (buffer-substring-no-properties start end))
	  (set (intern id (shimbun-pocketgames-content-hash-internal shimbun))
	       body)
	  (push (shimbun-make-header
		 0 (shimbun-mime-encode-string subject)
		 from date id "" 0 0 (concat url "/"))
		headers))))
      headers))

(defun shimbun-pocketgames-comment-article (shimbun headers baseurl ref-id end)
  (let (url from year month day date time
	subject body id)
    (save-excursion
      (when (re-search-forward
	     "<a class=\"pn-normal\" href=\"\\(modules.php\?.+\\)\">[0-9]+ $B%3%a%s%H(B<\/a>"
	     end t nil)
	(setq url (concat baseurl "/" (w3m-decode-anchor-string (match-string 1))))
	(with-temp-buffer
	  (shimbun-retrieve-url url 'reload 'binary)
	  (set-buffer-multibyte t)
	  (decode-coding-region (point-min) (point-max)
				(shimbun-coding-system-internal shimbun))
	  (goto-char (point-min))
	  (re-search-forward "<!-- *COMMENTS NAVIGATION BAR END *-->" nil t nil)
	  (while (re-search-forward "<font class=\"pn-title\">\\(Re: [^<]+\\)" nil t nil)
	    (catch 'next
	      (setq subject (match-string-no-properties 1))
	      (unless (re-search-forward
		       ;; <br>by <a class="pn-normal" href="mailto:-">aoshimak</a> <b>(-)</b></font><font class="pn-sub"> on 2003$BG/(B3$B7n(B08$BF|(B - 06:15 PM<br><font class="pn-normal">
		       "<br>by \\(.+\\) on \\([0-9]+\\)$BG/(B\\([0-9]+\\)$B7n(B\\([0-9]+\\)$BF|(B - \\([0-9][0-9]+:[0-9][0-9]+\\) \\(AM\\|PM\\)\\(</font></td></tr><tr><td>\\|<br>\\)<font class=\"pn-normal\">"
		       nil t nil)
		(throw 'next nil))
	      (setq from (match-string-no-properties 1)
		    year (string-to-number (match-string-no-properties 2))
		    month (string-to-number (match-string-no-properties 3))
		    day (string-to-number (match-string-no-properties 4))
		    time (match-string-no-properties 5)
		    body (buffer-substring
			  (point)
			  (progn
			    (search-forward 
			     "</font></td></tr></table><br><br><font class=\"pn-normal\">"
			     nil t nil)
			    (match-beginning 0)))
		    date (shimbun-make-date-string year month day time))
	      (setq id (format "<%04d%02d%02d%s.comment.pocketgames>"
			year month day time))
	      (when (shimbun-search-id shimbun id)
		(throw 'next nil))
	      (with-temp-buffer
		(insert from)
		(shimbun-remove-markup)
		(setq from (shimbun-mime-encode-string (buffer-string)))
		(erase-buffer)
		(insert subject)
		(shimbun-remove-markup)
		(setq subject (shimbun-mime-encode-string (buffer-string))))
	      (set (intern id (shimbun-pocketgames-content-hash-internal shimbun))
		   body)
	      (push (shimbun-make-header 0 subject from date id ref-id 0 0 url)
		    headers)))))
      headers)))

(luna-define-method shimbun-article
  ((shimbun shimbun-pocketgames) header &optional outbuf)
  (let (string)
    (with-current-buffer (or outbuf (current-buffer))
      (with-temp-buffer
	(let ((sym (intern-soft (shimbun-header-id header)
				(shimbun-pocketgames-content-hash-internal
				 shimbun))))
	  (when (and (boundp sym) (symbol-value sym))
	    (insert (symbol-value sym))
	    (goto-char (point-min))
	    (insert "<html>\n<head>\n<base href=\""
		    (shimbun-header-xref header) "\">\n</head>\n<body>\n")
	    (goto-char (point-max))
	    (insert "\n</body>\n</html>\n")
	    (encode-coding-string
	     (buffer-string)
	     (mime-charset-to-coding-system "ISO-2022-JP"))
	    (shimbun-make-mime-article shimbun header)
	    (setq string (buffer-string)))))
      (when string
	(w3m-insert-string string)))))

(provide 'sb-pocketgames)

;;; sb-pocketgames.el ends here

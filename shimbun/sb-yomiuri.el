;;; sb-yomiuri.el --- shimbun backend for www.yomiuri.co.jp -*- coding: iso-2022-7bit; -*-

;; Author: TSUCHIYA Masatoshi <tsuchiya@namazu.org>,
;;         Yuuichi Teranishi  <teranisi@gohome.org>,
;;         Katsumi Yamaoka    <yamaoka@jpl.org>

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

;; Original code was nnshimbun.el written by
;; TSUCHIYA Masatoshi <tsuchiya@namazu.org>.

;;; Code:

(require 'shimbun)
(require 'sb-text)

(luna-define-class shimbun-yomiuri
		   (shimbun-japanese-newspaper shimbun-text) ())

(defvar shimbun-yomiuri-top-level-domain "yomiuri.co.jp"
  "Name of the top level domain for the Yomiuri On-line.")

(defvar shimbun-yomiuri-url
  (concat "http://www." shimbun-yomiuri-top-level-domain "/")
  "Name of the parent url.")

(defvar shimbun-yomiuri-group-table
  (let* ((s0 "[\t\n ]*")
	 (s1 "[\t\n ]+")
	 (default
	   (list
	    (concat
	     "<a" s1 "href=\"/"
	     ;; 1. url
	     "\\(%s/news/"
	     ;; 2. serial number
	     "\\(20[0-9][0-9][01][0-9][0-3][0-9][0-9a-z]+\\)"
	     "\\.htm\\)\">" s0
	     ;; 3. subject
	     "\\([^<>]+\\)"
	     s0 "("
	     ;; 4. month
	     "\\([01]?[0-9]\\)"
	     "/"
	     ;; 5. day
	     "\\([0-3]?[0-9]\\)"
	     s1
	     ;; 6. hour:minute
	     "\\([012][0-9]:[0-5][0-9]\\)"
	     ")" s0 "</a>")
	    1 2 3 4 5 6)))
    `(("business" "$B7P:QLL(B" "index.htm" ,@default)
      ("culture" "$B7]G=!&J82=LL(B" "index.htm" ,@default)
      ("editorial" "$B<R@b!&%3%i%`(B" "index.htm"
       ,(concat "<a" s1 "href=\"/"
		;; 1. url
		"\\(%s/news/"
		;; 2. serial number
		"\\(20[0-9][0-9][01][0-9][0-3][0-9][0-9a-z]+\\)"
		"\\.htm\\)"
		"\">" s0
		;; 3. month(ja)
		"\\([$B#0#1(B]?[$B#0(B-$B#9(B]\\)"
		"$B7n(B"
		;; 4. day(ja)
		"\\([$B#0(B-$B#3(B]?[$B#0(B-$B#9(B]\\)"
		"$BF|IU!&(B"
		;; 5. subject
		"\\(.+\\)" s0 "</a>")
       1 2 5 nil nil nil 3 4)
      ("kyoiku" "$B650i%a!<%k(B" "main.htm"
       ,(concat "<a" s1 "href=\"/"
		;; 1. url
		"\\(%s/"
		;; 2. parent-directory
		"\\([0-9]+\\)"
		"/"
		;; 3. serial number
		"\\("
		;; 4. year
		"\\(20[0-9][0-9]\\)"
		;; 5. month
		"\\([01][0-9]\\)"
		;; 6. day
		"\\([0-3][0-9]\\)"
		"[0-9a-z]+\\)"
		"\\.htm\\)\""
		s1 "target=\"_top\">" s0 "\\(<[^<>]+>" s0 "\\)+$B"!(B?"
		;; 8. subject
		"\\([^<>]+\\)" s0)
		1 3 8 5 6 nil 2)
      ("national" "$B<R2qLL(B" "index.htm" ,@default)
      ("obit" "$B$*$/$d$_(B" "index.htm"
       ,(concat "<a" s1 "href=\"/"
		;; 1. url
		"\\(%s/news/"
		;; 2. serial number
		"\\(20[0-9][0-9][01][0-9][0-3][0-9][0-9a-z]+\\)"
		"\\.htm\\)"
		"\">" s0
		;; 3. subject
		"\\(.+\\)"
		s0 "("
		;; 4. month
		"\\([01]?[0-9]\\)"
		"/"
		;; 5. day
		"\\([0-3]?[0-9]\\)"
		")" s0 "</a>")
       1 2 3 4 5)
      ("politics" "$B@/<#LL(B" "index.htm" ,@default)
      ("science" "$B2J3XLL(B" "index.htm" ,@default)
      ("sports" "$B%9%]!<%DLL(B" "index.htm" ,@default)
      ("world" "$B9q:]LL(B" "index.htm" ,@default)))
  "Alist of group names, their Japanese translations, index pages,
regexps and numbers.
Regexp may contain the \"%s\" token which is replaced with a
regexp-quoted group name.  Numbers point to the search result in order
of a url, a serial number, a subject, a month, a day, an hour:minute
and extra keywords.")

(defvar shimbun-yomiuri-content-start "\n<!--  honbun start  -->\n")

(defvar shimbun-yomiuri-content-end  "\n<!--  honbun end  -->\n")

(defvar shimbun-yomiuri-x-face-alist
  '(("default" . "X-Face: #sUhc'&(fVr$~<rt#?PkH,u-.fV(>y)\
i\"#,TNF|j.dEh2dAzfa4=IH&llI]S<-\"dznMW2_j\n [N1a%n{SU&E&\
Ex;xlc)9`]D07rPEsbgyjP@\"_@g-kw!~TJNilrSC!<D|<m=%Uf2:eebg")))

(defvar shimbun-yomiuri-expiration-days 7)

(luna-define-method initialize-instance :after ((shimbun shimbun-yomiuri)
						 &rest init-args)
  (shimbun-set-server-name-internal shimbun "$Bl&Gd?7J9(B")
  (shimbun-set-from-address-internal shimbun
				     (concat "webmaster@www."
					     shimbun-yomiuri-top-level-domain))
  ;; To share class variables between `shimbun-yomiuri' and its
  ;; successor `shimbun-yomiuri-html'.
  (shimbun-set-x-face-alist-internal shimbun shimbun-yomiuri-x-face-alist)
  (shimbun-set-expiration-days-internal shimbun
					shimbun-yomiuri-expiration-days)
  shimbun)

(luna-define-method shimbun-groups ((shimbun shimbun-yomiuri))
  (mapcar 'car shimbun-yomiuri-group-table))

(luna-define-method shimbun-current-group-name ((shimbun shimbun-yomiuri))
  (nth 1 (assoc (shimbun-current-group-internal shimbun)
		shimbun-yomiuri-group-table)))

(luna-define-method shimbun-index-url ((shimbun shimbun-yomiuri))
  (let ((group (shimbun-current-group-internal shimbun)))
    (concat shimbun-yomiuri-url group "/"
	    (nth 2 (assoc group shimbun-yomiuri-group-table)))))

(defmacro shimbun-yomiuri-japanese-string-to-number (string)
  "Convert a Japanese zenkaku number to just a number."
  (let ((alist ''((?$B#0(B . 0) (?$B#1(B . 1) (?$B#2(B . 2) (?$B#3(B . 3) (?$B#4(B . 4)
		  (?$B#5(B . 5) (?$B#6(B . 6) (?$B#7(B . 7) (?$B#8(B . 8) (?$B#9(B . 9))))
    (if (= (length "$B#0(B") 1)
	`(let* ((str ,string)
		(alist ,alist)
		(len (length str))
		(idx 0)
		(num 0))
	   (while (< idx len)
	     (setq num (+ (cdr (assq (aref str idx) alist)) (* num 10))
		   idx (1+ idx)))
	   num)
      `(let* ((str ,string)
	      (alist ,alist)
	      (len (length str))
	      (idx 0)
	      (num 0)
	      char)
	 (while (< idx len)
	   (setq char (sref str idx)
		 num (+ (cdr (assq char alist)) (* num 10))
		 idx (+ idx (char-bytes char))))
	 num))))

(defun shimbun-yomiuri-shorten-brackets-in-string (string)
  "Replace Japanes zenkaku brackets with ascii characters in STRING.
It does also shorten too much spaces."
  (save-match-data
    (with-temp-buffer
      (insert string)
      (let ((alist '(("$B!J(B" . " (") ("$B!K(B" . ") ") ("$B!N(B" . " [")
		     ("$B!O(B" . "] ") ("$B!P(B" . " {") ("$B!Q(B" . "} ")))
	    elem)
	(while alist
	  (setq elem (pop alist))
	  (goto-char (point-min))
	  (while (search-forward (car elem) nil t)
	    (replace-match (cdr elem))))
	(goto-char (point-min))
	(while (re-search-forward "[\t $B!!(B]+" nil t)
	  (replace-match " "))
	(goto-char (point-min))
	(while (re-search-forward "\\([])}]\\) \\([])}]\\)" nil t)
	  (replace-match "\\1\\2")
	  (forward-char -1))
	(goto-char (point-min))
	(while (re-search-forward "\\([[({]\\) \\([[({]\\)" nil t)
	  (replace-match "\\1\\2")
	  (forward-char -1))
	(goto-char (point-min))
	(while (re-search-forward " ?\\([$B!V!W(B]\\) ?" nil t)
	  (replace-match "\\1"))
	(goto-char (point-min))
	(while (re-search-forward "^ \\| $" nil t)
	  (replace-match "")))
      (buffer-string))))

(defun shimbun-yomiuri-get-headers (shimbun)
  "Return a list of headers."
  (let ((group (shimbun-current-group-internal shimbun))
	(from (shimbun-from-address shimbun))
	(case-fold-search t)
	cyear cmonth month day time regexp numbers headers)
    (setq cyear (decode-time)
	  cmonth (nth 4 cyear)
	  cyear (nth 5 cyear))
    ;; Extracting top news.
    (when (and (not (member group '("editorial" "kyoiku" "obit")))
	       (re-search-forward
		(format
		 (eval-when-compile
		   (concat
		    "<a[\t\n ]+href=\"/"
		    ;; 1. url
		    "\\(%s/news/"
		    ;; 2. serial number
		    "\\(20[0-9][0-9]"
		    ;; 3. month
		    "\\([01][0-9]\\)"
		    ;; 4. day
		    "\\([0-3][0-9]\\)"
		    "[0-9a-z]+\\)"
		    "\\.htm\\)"
		    "\">[\t\n ]*\\(<[^<>]+>[\t\n ]*\\)+"
		    ;; 6. subject
		    "\\([^<>]+\\)"
		    "[\t\n ]*<"))
		 (regexp-quote group))
		nil t))
      (setq month (string-to-number (match-string 3))
	    day (string-to-number (match-string 4)))
      (save-match-data
	(when (re-search-forward
	       (concat "(\\([01]?[0-9]\\)/\\([0-3]?[0-9]\\)[\t\n ]+\
\\([012][0-9]:[0-5][0-9]\\))[\t\n ]+<a[\t\n ]+href=\"/"
		       (regexp-quote (match-string 1)) "\"")
	       nil t)
	  (setq month (string-to-number (match-string 1))
		day (string-to-number (match-string 2))
		time (match-string 3))))
      (push (shimbun-make-header
	     ;; number
	     0
	     ;; subject
	     (match-string 6)
	     ;; from
	     from
	     ;; date
	     (shimbun-make-date-string (cond ((and (= 12 month) (= 1 cmonth))
					      (1- cyear))
					     ((and (= 1 month) (= 12 cmonth))
					      (1+ cyear))
					     (t
					      cyear))
				       month day time)
	     ;; id
	     (concat "<" (match-string 2) "%" group "."
		     shimbun-yomiuri-top-level-domain ">")
	     ;; references, chars, lines
	     "" 0 0
	     ;; xref
	     (concat shimbun-yomiuri-url (match-string 1)))
	    headers))
    (setq regexp (assoc group shimbun-yomiuri-group-table)
	  numbers (nthcdr 4 regexp)
	  regexp (format (nth 3 regexp) (regexp-quote group)))
    ;; Generating headers.
    (while (re-search-forward regexp nil t)
      (if (string-equal group "editorial")
	  (setq month (shimbun-yomiuri-japanese-string-to-number
		       (match-string (nth 6 numbers)))
		day (shimbun-yomiuri-japanese-string-to-number
		     (match-string (nth 7 numbers))))
	(setq month (string-to-number (match-string (nth 3 numbers)))
	      day (string-to-number (match-string (nth 4 numbers)))))
      (push (shimbun-make-header
	     ;; number
	     0
	     ;; subject
	     (if (string-equal "editorial" group)
		 (shimbun-mime-encode-string
		  (format "%02d/%02d %s"
			  month day
			  (shimbun-yomiuri-shorten-brackets-in-string
			   (match-string (nth 2 numbers)))))
	       (shimbun-mime-encode-string (match-string (nth 2 numbers))))
	     ;; from
	     from
	     ;; date
	     (shimbun-make-date-string (cond ((and (= 12 month) (= 1 cmonth))
					      (1- cyear))
					     ((and (= 1 month) (= 12 cmonth))
					      (1+ cyear))
					     (t
					      cyear))
				       month day
				       (when (nth 5 numbers)
					 (match-string (nth 5 numbers))))
	     ;; id
	     (concat "<" (match-string (nth 1 numbers)) "%" group "."
		     shimbun-yomiuri-top-level-domain ">")
	     ;; references, chars, lines
	     "" 0 0
	     ;; xref
	     (if (string-equal group "kyoiku")
		 (concat shimbun-yomiuri-url
			 (buffer-substring (match-beginning (nth 0 numbers))
					   (match-end (nth 6 numbers)))
			 "a"
			 (buffer-substring (match-end (nth 6 numbers))
					   (match-end (nth 0 numbers))))
	       (concat shimbun-yomiuri-url (match-string (nth 0 numbers)))))
	    headers))
    headers))

(luna-define-method shimbun-get-headers ((shimbun shimbun-yomiuri)
					 &optional range)
  (shimbun-yomiuri-get-headers shimbun))

(defun shimbun-yomiuri-prepare-article (shimbun header)
  "Prepare an article: adjusting a date header if there is a correct
information available, removing useless contents, etc."
  (let ((group (shimbun-current-group-internal shimbun))
	(case-fold-search t)
	end)
    (if (string-equal group "kyoiku")
	(when (re-search-forward "^$B"!(B<b>.+</b>[\t\n ]*" nil t)
	  (delete-region (point-min) (point))
	  (while (re-search-forward "[\t\n ]*\\(<\\([^<>]+\\)>[\t\n ]*\\)+"
				    nil t)
	    (unless (string-equal (match-string 2) "p")
	      (delete-region (match-beginning 0) (match-end 0)))))
      (when (and (re-search-forward (shimbun-content-start-internal shimbun)
				    nil t)
		 (re-search-forward (shimbun-content-end-internal shimbun)
				    nil t)
		 (progn
		   (goto-char (setq end (match-beginning 0)))
		   (forward-line -1)
		   (re-search-forward "\\(20[0-9][0-9]\\)/\\(1?[0-9]\\)/\
\\([123]?[0-9]\\)/\\([012][0-9]:[0-5][0-9]\\)"
				      end t)))
	(shimbun-header-set-date
	 header
	 (shimbun-make-date-string
	  (string-to-number (match-string 1))
	  (string-to-number (match-string 2))
	  (string-to-number (match-string 3))
	  (match-string 4))))))
  (goto-char (point-min)))

(luna-define-method shimbun-make-contents :before ((shimbun shimbun-yomiuri)
						   header)
  (shimbun-yomiuri-prepare-article shimbun header))

(provide 'sb-yomiuri)

;;; sb-yomiuri.el ends here

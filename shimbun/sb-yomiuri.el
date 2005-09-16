;;; sb-yomiuri.el --- shimbun backend for www.yomiuri.co.jp -*- coding: iso-2022-7bit; -*-

;; Copyright (C) 2001, 2002, 2003, 2004, 2005 Authors

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
;; Inc.; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;; Original code was nnshimbun.el written by
;; TSUCHIYA Masatoshi <tsuchiya@namazu.org>.

;;; Code:

(require 'shimbun)

(luna-define-class shimbun-yomiuri (shimbun-japanese-newspaper shimbun) ())

(defvar shimbun-yomiuri-prefer-text-plain t
  "*Non-nil means prefer text/plain articles rather than html articles.")

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
	     ;; 2. serial number[1]
	     "\\("
	     ;; 3. year
	     "\\(20[0-9][0-9]\\)"
	     "[01][0-9][0-3][0-9]\\)"
	     ;; 4. serial number[2]
	     "\\([^.]+\\)"
	     "[^\"]+\\)"
	     "\"[^>]*>" s0
	     ;; 5. subject
	     "\\([^<]+\\)"
	     s0 "</a>[^<$B!J(B]*$B!J(B" s0
	     ;; 6. month
	     "\\([01]?[0-9]\\)"
	     s0 "$B7n(B" s0
	     ;; 7. day
	     "\\([0-3]?[0-9]\\)"
	     s0 "$BF|(B" s0
	     ;; 8. hour:minute
	     "\\([012][0-9]:[0-5][0-9]\\)")
	    1 2 4 3 5 6 7 8)))
    `(("atmoney" "$B%^%M!<!&7P:Q(B" "news/" ,@default) ;; business
      ("editorial" "$B<R@b!&%3%i%`(B" ""
       ,(concat "<a" s1 "href=\"/"
		;; 1. url
		"\\(%s/news/"
		;; 2. serial number[1]
		"\\("
		;; 3. year
		"\\(20[0-9][0-9]\\)"
		"[01][0-9][0-3][0-9]\\)"
		;; 4. serial number[2]
		"\\([^.]+\\)"
		"[^\"]+\\)"
		"\"[^>]*>" s0
		;; 5. ja month
		"\\([$B#0#1(B]?[$B#0(B-$B#9(B]\\)"
		"$B7n(B"
		;; 6. ja day
		"\\([$B#0(B-$B#3(B]?[$B#0(B-$B#9(B]\\)"
		"$BF|IU!&(B"
		;; 7. subject
		"\\([^<]+\\)"
		s0)
       1 2 4 3 7 nil nil nil 5 6)
      ("entertainment" "$B%(%s%?!<%F%$%s%a%s%H(B" "news/" ,@default) ;; culture
      ("kyoiku" "$B650i(B" ""
       ,(concat "<a" s1 "href=\"/"
		;; 1. url
		"\\(%s/\\(?:[^\t\n /]+/\\)+"
		;; 2. serial number[1]
		"\\("
		;; 3. year
		"\\(20[0-9][0-9]\\)"
		"[01][0-9][0-3][0-9]\\)"
		;; 4. serial number[2]
		"\\([^.]+\\)"
		"[^\"]+\\.htm\\)"
		"\"[^>]*>" s0
		;; 5. subject
		"\\([^<]+\\)"
		s0 "</a>"
		s0 "<span" s1 "class=\"date\">" s0 "<span class=\"m\">" s0
		;; 6. month
		"\\([01]?[0-9]\\)"
		s0 "$B7n(B" s0 "</span>" s0 "<span" s1 "class=\"d\">" s0
		;; 7. day
		"\\([0-3]?[0-9]\\)")
       1 2 4 3 5 6 7)
      ("national" "$B<R2q(B" "" ,@default)
      ("obit" "$B$*$/$d$_(B" "http://www.yomiuri.co.jp/national/obit/"
       ,(concat
	 "<a" s1 "href=\"/"
	 ;; 1. url
	 "\\(national/%s/news/"
	 ;; 2. serial number[1]
	 "\\("
	 ;; 3. year
	 "\\(20[0-9][0-9]\\)"
	 "[01][0-9][0-3][0-9]\\)"
	 ;; 4. serial number[2]
	 "\\([^.]+\\)"
	 "[^\"]+\\)"
	 "\"[^>]*>" s0
	 ;; 5. subject
	 "\\([^<]+\\)"
	 s0 "</a>[^<$B!J(B]*$B!J(B" s0
	 ;; 6. month
	 "\\([01]?[0-9]\\)"
	 s0 "$B7n(B" s0
	 ;; 7. day
	 "\\([0-3]?[0-9]\\)")
       1 2 4 3 5 6 7)
      ("politics" "$B@/<#(B" "" ,@default)
      ("science" "$B2J3X(B" "" ,@default)
      ("sports" "$B%9%]!<%D(B" ""
       ,(concat
	 "<a" s1 "href=\"/"
	 ;; 1. url
	 "\\(%s/"
	 ;; 2. subgroup
	 "\\([^/]+\\)"
	 "/news/"
	 ;; 3. serial number[1]
	 "\\("
	 ;; 4. year
	 "\\(20[0-9][0-9]\\)"
	 "[01][0-9][0-3][0-9]\\)"
	 ;; 5. serial number[2]
	 "\\([^.]+\\)"
	 "[^\"]+\\)"
	 "\"[^>]*>" s0
	 ;; 6. subject
	 "\\([^<]+\\)"
	 s0 "</a>[^<$B!J(B]*$B!J(B" s0
	 ;; 7. month
	 "\\([01]?[0-9]\\)"
	 s0 "$B7n(B" s0
	 ;; 8. day
	 "\\([0-3]?[0-9]\\)"
	 s0 "$BF|(B" s0
	 ;; 9. hour:minute
	 "\\([012][0-9]:[0-5][0-9]\\)")
       1 3 5 4 6 7 8 9 nil nil 2)
      ("world" "$B9q:](B" "" ,@default)))
  "Alist of group names, their Japanese translations, index pages,
regexps and numbers.
Regexp may contain the \"%s\" token which is replaced with a
regexp-quoted group name.  Numbers point to the search result in order
of [0]url, [1,2]serial numbers, [3]year, [4]subject, [5]month, [6]day,
\[7]hour:minute, [8]ja month, [9]ja day and [10]subgroup.")

(defvar shimbun-yomiuri-content-start
  "\n<!--// article_start //-->\n\
\\|\n<!-- $B"'<L??%F!<%V%k"'(B -->\n\
\\|\n<!--  honbun start  -->\n")

(defvar shimbun-yomiuri-content-end
  "\n<!--// article_end //-->\n\\|\n<!--  honbun end  -->\n")

(defvar shimbun-yomiuri-text-content-start
  "\n<!--// article_start //-->\n\\|\n<!--  honbun start  -->\n")

(defvar shimbun-yomiuri-text-content-end shimbun-yomiuri-content-end)

(defvar shimbun-yomiuri-x-face-alist
  '(("default" . "X-Face: #sUhc'&(fVr$~<rt#?PkH,u-.fV(>y)\
i\"#,TNF|j.dEh2dAzfa4=IH&llI]S<-\"dznMW2_j\n [N1a%n{SU&E&\
Ex;xlc)9`]D07rPEsbgyjP@\"_@g-kw!~TJNilrSC!<D|<m=%Uf2:eebg")))

(defvar shimbun-yomiuri-expiration-days 7)

(luna-define-method initialize-instance :after ((shimbun shimbun-yomiuri)
						&rest init-args)
  (shimbun-set-server-name-internal shimbun "$Bl&Gd?7J9(B")
  (shimbun-set-from-address-internal shimbun "nobody@example.com")
  ;; To share class variables between `shimbun-yomiuri' and its
  ;; successor `shimbun-yomiuri-html'.
  (shimbun-set-x-face-alist-internal shimbun shimbun-yomiuri-x-face-alist)
  (shimbun-set-expiration-days-internal shimbun
					shimbun-yomiuri-expiration-days)
  (shimbun-set-content-start-internal shimbun shimbun-yomiuri-content-start)
  (shimbun-set-content-end-internal shimbun shimbun-yomiuri-content-end)
  shimbun)

(luna-define-method shimbun-groups ((shimbun shimbun-yomiuri))
  (mapcar 'car shimbun-yomiuri-group-table))

(luna-define-method shimbun-current-group-name ((shimbun shimbun-yomiuri))
  (nth 1 (assoc (shimbun-current-group-internal shimbun)
		shimbun-yomiuri-group-table)))

(luna-define-method shimbun-index-url ((shimbun shimbun-yomiuri))
  (let* ((group (shimbun-current-group-internal shimbun))
	 (index (nth 2 (assoc group shimbun-yomiuri-group-table))))
    (if (string-match "\\`http:" index)
	index
      (concat shimbun-yomiuri-url group "/" index))))

(defun shimbun-yomiuri-japanese-string-to-number (string)
  "Convert a Japanese zenkaku number to just a number."
  (let ((alist '((?$B#0(B . 0) (?$B#1(B . 1) (?$B#2(B . 2) (?$B#3(B . 3) (?$B#4(B . 4)
		 (?$B#5(B . 5) (?$B#6(B . 6) (?$B#7(B . 7) (?$B#8(B . 8) (?$B#9(B . 9)))
	(len (length string))
	(idx 0)
	(num 0))
    (while (< idx len)
      (setq num (+ (cdr (assq (aref string idx) alist)) (* num 10))
	    idx (1+ idx)))
    num))

(defun shimbun-yomiuri-get-top-header (group from)
  "Return a list of a header for the top news."
  (when (re-search-forward
	 (format
	  (eval-when-compile
	    (let ((s0 "[\t\n ]*")
		  (s1 "[\t\n ]+"))
	      (concat
	       "<a" s1 "href=\"/"
	       ;; 1. url
	       "\\(%s/"
	       ;; 2. subgroup
	       "\\(?:\\([^/]+\\)/\\)?"
	       "news/"
	       ;; 3. serial number[1]
	       "\\("
	       ;; 4. year
	       "\\(20[0-9][0-9]\\)"
	       "[01][0-9][0-3][0-9]\\)"
	       ;; 5. serial number[2]
	       "\\([^.]+\\)"
	       "[^\"]+\\)"
	       "\"[^>]*>" s0
	       ;; 6. subject
	       "\\([^<]+\\)"
	       s0)))
	  group)
	 nil t)
    (let* ((url (shimbun-expand-url (match-string 1) shimbun-yomiuri-url))
	   (subgroup (match-string 2))
	   (id (concat "<" (match-string 3) "." (match-string 5)
		       "%" (when subgroup
			     (concat subgroup "."))
		       group "." shimbun-yomiuri-top-level-domain ">"))
	   (year (string-to-number (match-string 4)))
	   (subject (if subgroup
			(concat "[" subgroup "] " (match-string 6))
		      (match-string 6))))
      (prog1
	  (when (re-search-forward
		 (eval-when-compile
		   (let ((s0 "[\t\n ]*"))
		     (concat
		      ">" s0 "$B!J(B" s0
		      ;; 1. month
		      "\\([01]?[0-9]\\)"
		      s0 "$B7n(B" s0
		      ;; 2. day
		      "\\([0-3][0-9]\\)"
		      s0 "$BF|(B" s0
		      ;; 3. hour:minute
		      "\\([012][0-9]:[0-5][0-9]\\)"
		      s0 "$B!K(B" s0 "<")))
		 nil t)
	    (list (shimbun-create-header
		   0
		   subject
		   from
		   (shimbun-make-date-string
		    year
		    (string-to-number (match-string 1))
		    (string-to-number (match-string 2))
		    (match-string 3))
		   id "" 0 0 url)))
	(goto-char (point-min))))))

(defun shimbun-yomiuri-get-headers (shimbun)
  "Return a list of headers."
  (shimbun-strip-cr)
  (goto-char (point-min))
  (let ((group (shimbun-current-group-internal shimbun))
	(from (concat (shimbun-server-name shimbun)
		      " (" (shimbun-current-group-name shimbun) ")"))
	(case-fold-search t)
	headers regexp numbers subject month day subgroup)
    ;; Extract top news.
    (when (member group '("atmoney" "entertainment" "national" "politics"
			  "science" "sports" "world"))
      (setq headers (shimbun-yomiuri-get-top-header group from)))
    (setq regexp (assoc group shimbun-yomiuri-group-table)
	  numbers (nthcdr 4 regexp)
	  regexp (format (nth 3 regexp) (regexp-quote group)))
    (while (re-search-forward regexp nil t)
      (setq subject (match-string (nth 4 numbers))
	    month (if (nth 8 numbers)
		      (shimbun-yomiuri-japanese-string-to-number
		       (match-string (nth 8 numbers)))
		    (string-to-number (match-string (nth 5 numbers))))
	    day (if (nth 9 numbers)
		    (shimbun-yomiuri-japanese-string-to-number
		     (match-string (nth 9 numbers)))
		  (string-to-number (match-string (nth 6 numbers))))
	    subgroup (when (nth 10 numbers)
		       (match-string (nth 10 numbers))))
      (cond ((string-equal group "editorial")
	     (setq subject
		   (format
		    "%02d/%02d %s"
		    month day
		    (save-match-data
		      (if (string-match "\\`$B!N(B\\(.+\\)$B!O!V(B\\(.+\\)$B!W(B\\'"
					subject)
			  (replace-match "\\1: \\2" nil nil subject)
			subject)))))
	    (subgroup
	     (setq subject (concat "[" subgroup "] " subject))))
      (push (shimbun-create-header
	     0 subject from
	     (shimbun-make-date-string
	      (string-to-number (match-string (nth 3 numbers)))
	      month day
	      (when (nth 7 numbers)
		(match-string (nth 7 numbers))))
	     (concat "<" (match-string (nth 1 numbers))
		     "." (match-string (nth 2 numbers))
		     "%" (when subgroup
			   (concat subgroup "."))
		     group "." shimbun-yomiuri-top-level-domain ">")
	     "" 0 0
	     (shimbun-expand-url (match-string (nth 0 numbers))
				 shimbun-yomiuri-url))
	    headers))
    (shimbun-sort-headers headers)))

(luna-define-method shimbun-get-headers ((shimbun shimbun-yomiuri)
					 &optional range)
  (shimbun-yomiuri-get-headers shimbun))

(defun shimbun-yomiuri-prepare-article (shimbun header)
  (shimbun-with-narrowed-article
   shimbun
   ;; Correct Date header.
   (when (re-search-forward
	  (eval-when-compile
	    (let ((s0 "[\t\n ]*")
		  (s1 "[\t\n ]+"))
	      (concat
	       "<!--" s0 "//" s1 "date_start" s1 "//" s0 "-->" s0
	       ;; 1. year
	       "\\(20[0-9][0-9]\\)"
	       s0 "$BG/(B" s0
	       ;; 2. month
	       "\\([01]?[0-9]\\)"
	       s0 "$B7n(B" s0
	       ;; 3. day
	       "\\([0-3]?[0-9]\\)"
	       s0 "$BF|(B" s0
	       ;; 4. hour
	       "\\([012]?[0-9]\\)"
	       s0 "$B;~(B" s0
	       ;; 5. minute
	       "\\([0-5]?[0-9]\\)"
	       s0 "$BJ,(B" s0 "<!--" s0 "//" s1 "date_end" s1 "//" s0 "-->")))
	  nil t)
     (shimbun-header-set-date
      header
      (shimbun-make-date-string
       (string-to-number (match-string 1))
       (string-to-number (match-string 2))
       (string-to-number (match-string 3))
       (format "%02d:%02d"
	       (string-to-number (match-string 4))
	       (string-to-number (match-string 5)))))
     (goto-char (point-min)))
   ;; Remove the $B%U%)%H%K%e!<%9(B, the $B<L??$N3HBg(B buttons, etc.
   (while (re-search-forward
	   (eval-when-compile
	     (let ((s0 "[\t\n ]*")
		   (s1 "[\t\n ]+")
		   (n1 "[^\t\n >]+"))
	       (concat
		s0
		"\\(?:"
		"<a\\(?:" s1 n1 "\\)*" s1
		"\\(?:class=\"photo-pn\"\\|target=\"photoWin\"\\)"
		"\\(?:" s1 n1 "\\)*" s0 ">"
		"\\|"
		"<img\\(?:" s1 n1 "\\)*" s1
		"\\(?:alt=\"$B%U%)%H%K%e!<%9(B\"\\|class=\"photo-el\"\\)"
		"\\(?:" s1 n1 "\\)*" s0 ">"
		"\\|"
		"<div" s1
		"class=\"enlargedphoto\">\\(?:[^<>]+\\)?"
		"<img" s1 "[^>]+>" s0 "</div>"
		"\\|"
		"<div" s1 "class=\"[^\"]+\">" s0
		"<img\\(?:" s1 n1 "\\)*" s1 "src=\"/g/d\\.gif\""
		"\\(?:" s1 n1 "\\)*" s0 ">" s0 "</div>"
		"\\|"
		s0 "rectangle(\"[^\"]+\");" s0
		"\\)" s0)))
	   nil t)
     (delete-region (match-beginning 0) (match-end 0)))
   (goto-char (point-min))
   ;; Replace $B<L??$N3HBg(B with $B<L??(B.
   (while (re-search-forward
	   (eval-when-compile
	     (let ((s1 "[\t\n ]+")
		   (n1 "[^\t\n >]+"))
	       (concat "<img\\(?:" s1 n1 "\\)*" s1
		       "alt=\"$B<L??(B\\($B$N3HBg(B\\)\"")))
	   nil t)
     (delete-region (match-beginning 1) (match-end 1)))
   (goto-char (point-min))
   ;; Break continuous lines in editorial articles.
   (when (and (string-equal "editorial"
			    (shimbun-current-group-internal shimbun))
	      (string-match " \\(?:$B$h$_$&$j@#I>(B\\|$BJT=8<jD"(B\\)\\'"
			    (shimbun-header-subject header 'no-encode)))
     (while (search-forward "$B"!(B" nil t)
       (replace-match "$B!#(B<br><br>\n$B!!(B")))))

(luna-define-method shimbun-make-contents :before ((shimbun shimbun-yomiuri)
						   header)
  (shimbun-yomiuri-prepare-article shimbun header))

(provide 'sb-yomiuri)

;;; sb-yomiuri.el ends here

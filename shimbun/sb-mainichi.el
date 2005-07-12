;;; sb-mainichi.el --- shimbun backend for MSN-Mainichi -*- coding: iso-2022-7bit; -*-

;; Copyright (C) 2001, 2002, 2003, 2004, 2005
;; Koichiro Ohba <koichiro@meadowy.org>

;; Author: Koichiro Ohba <koichiro@meadowy.org>
;;         Katsumi Yamaoka <yamaoka@jpl.org>
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
;; Inc.; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;; Original code was sb-yomiuri.el which is written by
;; TSUCHIYA Masatoshi <tsuchiya@namazu.org> and
;; Yuuichi Teranishi <teranisi@gohome.org>

;;; Code:

(require 'shimbun)

(luna-define-class shimbun-mainichi (shimbun-japanese-newspaper shimbun) ())

(defvar shimbun-mainichi-prefer-text-plain nil
  "*Non-nil means prefer text/plain articles rather than html articles.")

(defvar shimbun-mainichi-top-level-domain "mainichi-msn.co.jp"
  "Name of the top level domain for the MSN-Mainichi INTERACTIVE.")

(defvar shimbun-mainichi-url
  (concat "http://www." shimbun-mainichi-top-level-domain "/")
  "Name of the parent url.")

(defvar shimbun-mainichi-header-regexp-default
  (let ((s0 "[\t\n ]*")
	(s1 "[\t\n ]+"))
    (list
     (concat
      "<a" s1 "href=\"/"
      ;; 1. url
      "\\("
      "\\(?:[^\t\n \"/]+/\\)+news/\\(?:20[0-9][0-9]/[01]?[0-9]/\\)?"
      ;; 2. serial number
      "\\("
      ;; 3. year
      "\\(20[0-9][0-9]\\)"
      ;; 4. month
      "\\([01][0-9]\\)"
      ;; 5. day
      "\\([0-3][0-9]\\)"
      "\\(?:[^\t\n \"./]\\)+\\)"
      "\\.html\\)"
      "[^>]*>" s0
      ;; 6 subject
      "\\([^<]+\\)"
      s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>"
      "\\(?:" s0 "</td>" s0 "<td" s1 "class=\"time\">"
      s0 "<span" s1 "[^>]+>" s0
      ;; 7?. hour
      "\\([012]?[0-9]\\)"
      ":"
      ;; 8?. minute
      "\\([0-5]?[0-9]\\)"
      "\\)?")
     1 2 3 4 5 6 7 8))
  "List of the default regexp used to extract headers and matching numbers.")

(defvar shimbun-mainichi-group-table
  '(("entertainment" "$B%(%s%?!<%F%$%s%a%s%H(B")
    ("entertainment.car" "$B<V(B")
    ("entertainment.cinema" "$B1G2h(B")
    ("entertainment.game" "$B%2!<%`(B")
    ("entertainment.geinou" "$B7]G=(B")
    ("entertainment.igo" "$B8k(B")
    ("entertainment.manga" "$B%"%K%a!&%^%s%,(B")
    ("entertainment.music" "$B2;3Z(B")
    ("entertainment.shougi" "$B>-4}(B")
    ("entertainment.tv" "$B%F%l%S(B")
    ("eye.closeup" "$B%/%m!<%:%"%C%W(B")
    ("eye.hassinbako" "$BH/?.H"(B")
    ("eye.hito" "$B$R$H(B")
    ("eye.kinji" "$B6a;vJR!9(B")
    ("eye.kishanome" "$B5-<T$NL\(B")
    ("eye.shasetsu" "$B<R@b(B")
    ("eye.shasetsu.archive" "$B<R@b%"!<%+%$%V(B")
    ("eye.tenbou" "$B%K%e!<%9E8K>(B")
    ("eye.yoroku" "$BM>O?(B")
    ("eye.yuuraku" "$BM+3ZD"(B")
    ("keizai" "$B7P:Q(B")
    ("keizai.it" "IT")
    ("keizai.it.net.archive" "$B%M%C%H;~Be$N%8%c!<%J%j%:%`$H$O2?$+(B")
    ("keizai.kaigai" "$B7P:Q!&3$30(B")
    ("keizai.kigyou" "$B4k6H(B")
    ("keizai.kigyou.info" "$B4k6H>pJs(B")
    ("keizai.kinyu" "$B6bM;!&3t(B")
    ("keizai.seisaku" "$B7P:Q!&@/:v(B")
    ("keizai.wadai" "$B7P:Q!&OCBj(B")
    ("keizai.wadai.kansoku.archive" "$B7P:Q4QB,(B")
    ("keizai.wadai.seika.archive" "$B!V@.2L<g5A!W$C$F2?$G$9$+(B")
    ("kokusai" "$B9q:](B")
    ("kokusai.afro-ocea" "$B%"%U%j%+!&%*%;%"%K%"(B")
    ("kokusai.america" "$BFnKL%"%a%j%+(B")
    ("kokusai.asia" "$B%"%8%"(B")
    ("kokusai.europe" "$B%h!<%m%C%Q(B")
    ("kokusai.mideast" "$BCf6aEl!&%m%7%"(B")
    ("kurashi" "$BJk$i$7(B")
    ("kurashi.bebe" "$B;R0i$F(B")
    ("kurashi.fashion" "$B%U%!%C%7%g%s(B")
    ("kurashi.katei" "$B2HDm(B")
    ("kurashi.kenko" "$B7r9/(B")
    ("kurashi.kokoro" "$B$3$3$m(B")
    ("kurashi.shoku" "$B?)(B")
    ("kurashi.shumi" "$B<qL#(B")
    ("kurashi.travel" "$BN9(B")
    ("kurashi.women" "$B=w$HCK(B")
    ("science" "$B%5%$%(%s%9(B")
    ("science.env" "$B4D6-(B")
    ("science.kagaku" "$B2J3X(B")
    ("science.medical" "$B0eNE(B")
    ("science.rikei" "$BM}7OGr=q(B")
    ("seiji" "$B@/<#(B")
    ("seiji.feature" "$B@/<#!&$=$NB>(B")
    ("seiji.gyousei" "$B9T@/(B")
    ("seiji.kokkai" "$B9q2q(B")
    ("seiji.seitou" "$B@/E^(B")
    ("seiji.senkyo" "$BA*5s(B")
    ("shakai" "$B<R2q(B")
    ("shakai.edu" "$B650i(B")
    ("shakai.edu.mori" "$B650i$N?9(B")
    ("shakai.edu.elearningschool.nyushi.archive" "IT$B$GF~;n$,JQ$o$k(B")
    ("shakai.edu.net.archive" "$B%M%C%H<R2q$H;R6!$?$A(B")
    ("shakai.edu.manabito.archive" "$B!V(Be$B!W$H!V3X$S!W$H(B")
    ("shakai.fu" "$Bk>Js(B")
    ("shakai.gakugei" "$B3X7](B")
    ("shakai.ji" "$B?M;v(B")
    ("shakai.jiken" "$B;v7o(B")
    ("shakai.koushitsu" "$B9D<<(B")
    ("shakai.tenki" "$BE75$(B")
    ("shakai.wadai" "$B<R2q!&OCBj(B")
    ("sokuhou" "$BB.Js(B")
    ("sports" "$B%9%]!<%D(B")
    ("sports.ama" "$B%"%^Ln5e(B")
    ("sports.battle" "$B3JF.5;(B")
    ("sports.feature" "$B%9%]!<%D!&$=$NB>(B")
    ("sports.field" "$BN&>e6%5;(B")
    ("sports.keiba" "$B6%GO(B")
    ("sports.major" "$BBg%j!<%0(B")
    ("sports.pro" "$BLn5e(B")
    ("sports.soccer" "$B%5%C%+!<(B")
    ("yougo" "$B%K%e!<%9$J8@MU(B"))
  "Alist of group names, their Japanese translations, regexps and numbers.
Where numbers point to the regexp search result in order of [0]a url,
\[1]a serial number, [2]a year, [3]a month, [4]a day, [5]a subject,
\[6]an hour and [7]a minute.  If regexps and numbers are omitted, the
value of `shimbun-mainichi-header-regexp-default' is used by default.")

(defvar shimbun-mainichi-server-name "$BKhF|?7J9(B")

(defvar shimbun-mainichi-from-address "nobody@example.com")

(defvar shimbun-mainichi-content-start
  (let ((s0 "[\t\n ]*"))
    (concat "</div>" s0
	    "\\(?:<div" s0 "class=\"img_[^\"]+\"" s0 ">" s0 "\\|<p>\\)")))

(defvar shimbun-mainichi-content-end
  (let ((s0 "[\t\n ]*"))
    (concat "\\(?:" s0 "</[^>]+>\\)*" s0
	    "<!--" s0 "||" s0 "/todays_topics" s0 "||-->")))

(defvar shimbun-mainichi-x-face-alist
  '(("default" . "\
Face: iVBORw0KGgoAAAANSUhEUgAAABwAAAAcBAMAAACAI8KnAAAABGdBTUEAALGPC/xhBQAAABh
 QTFRFC2zfDGzfEnDgJn3iU5fnj7vvzuH4+vz++nlsOQAAAC90RVh0U29mdHdhcmUAWFYgVmVyc2l
 vbiAzLjEwYStGTG1hc2sgIFJldjogMTIvMjkvOTQbx6p8AAABA0lEQVR4nGWRPW+DMBiED5vuqK0
 60yppVwQ0rFTYZo348poSA3uDzd/vCxNNT14en1/5zgZYEoCF69rk2zhWPR6GADwCl864tsaHFUJ
 dweTJuMcQZZ0kRQxkqnaHik2DbBwdVuPgtPG7WTcuhPdshdM5f7lp4SpyXUPoazu1i6HZpbY6R3a
 ZhAW8ztmZsDxPqf0Cb6zsVzQjJQA/2GNE2OWHbqaQvEggI7wFfOmxk1esLUL2GrJg2yBkrTSDqvB
 eJKmhqtNpttk3sllICskmdbXlGdkPNcd/TIuuvOxcM65IsxvSa2Q79w7V8AfL2u1nY9ZquuiWfK7
 1BSVNQzxF9B+40y/ui1KdNxt0ugAAAAd0SU1FB9QEDQAjJMA7GTQAAAAASUVORK5CYII=")))

(defvar shimbun-mainichi-expiration-days 7)

(luna-define-method shimbun-groups ((shimbun shimbun-mainichi))
  (mapcar 'car shimbun-mainichi-group-table))

(luna-define-method shimbun-current-group-name ((shimbun shimbun-mainichi))
  (nth 1 (assoc (shimbun-current-group-internal shimbun)
		shimbun-mainichi-group-table)))

(luna-define-method shimbun-index-url ((shimbun shimbun-mainichi))
  (shimbun-expand-url
   (concat (shimbun-subst-char-in-string
	    ?. ?/ (shimbun-current-group-internal shimbun))
	   "/")
   (shimbun-url-internal shimbun)))

(defun shimbun-mainichi-make-date-string (&rest args)
  "Run `shimbun-make-date-string' with ARGS and fix a day if needed.

\(shimbun-mainichi-make-date-string YEAR MONTH DAY &optional TIME TIMEZONE)"
  (if (equal (nth 3 args) "23:59:59")
      (apply 'shimbun-make-date-string args)
    (save-match-data
      (let* ((ctime (current-time))
	     (date (apply 'shimbun-make-date-string args))
	     (time (shimbun-time-parse-string date))
	     (ms (car time))
	     (ls (cadr time))
	     (system-time-locale "C"))
	(if (or (> ms (car ctime))
		(and (= ms (car ctime))
		     (> ls (cadr ctime))))
	    ;; It should be yesterday's same time.
	    (progn
	      (setq ms (1- ms))
	      (when (< (setq ls (- ls (eval-when-compile
					(- (* 60 60 24) 65536))))
		       0)
		(setq ms (1- ms)
		      ls (+ ls 65536)))
	      (format-time-string "%a, %d %b %Y %R +0900" (list ms ls)))
	  date)))))

(luna-define-method shimbun-get-headers ((shimbun shimbun-mainichi)
					 &optional range)
  (shimbun-mainichi-get-headers shimbun))

(defun shimbun-mainichi-get-headers (shimbun)
  (let* ((group (shimbun-current-group-internal shimbun))
	 (regexp (or (nthcdr 2 (assoc group shimbun-mainichi-group-table))
		     shimbun-mainichi-header-regexp-default))
	 (from (concat (shimbun-server-name shimbun)
		       " (" (shimbun-current-group-name shimbun) ")"))
	 (editorial (string-match "\\`eye\\.shasetsu" group))
	 (case-fold-search t)
	 numbers start url urls id month day subject headers header date)
    (setq numbers (cdr regexp)
	  regexp (car regexp))
    (shimbun-strip-cr)

    ;; Ignore unwanted links.
    (cond ((string-equal "eye.shasetsu" group)
	   (goto-char (point-min))
	   (when (re-search-forward "\\(?:[\t\n ]*<[^>]+>\\)*[\t\n ]*\
<a[\t\n ]+href=\"/eye/shasetsu/archive/\">"
				    nil t)
	     (delete-region (match-beginning 0) (point-max)))
	   (goto-char (point-min))
	   (re-search-forward "<div[\t\n ]+class=\"blocks\">[\t\n ]*" nil t))
	  ((string-match "\\`eye\\." group)
	   (goto-char (point-min))
	   (re-search-forward "<td[\t\n ]+class=\"date_md\">" nil t))
	  (t
	   (goto-char (point-max))
	   (when (re-search-backward "<!--[\t\n ]*||[\t\n ]*\
\\(?:todays_topics\\|/movie_news\\|/photo_news\\|/top_navi\\)[\t\n ]*||-->"
				     nil 'move))))
    (delete-region (point-min) (point))

    ;; Remove special sections.
    (while (and (re-search-forward "\
\[\t\n ]*\\(<!--[\t\n ]*|[\t\n ]*\\)\\(special[\t\n ]*|-->\\)"
				   nil t)
		(progn
		  (setq start (match-beginning 0))
		  (re-search-forward (concat (regexp-quote (match-string 1))
					     "/"
					     (regexp-quote (match-string 2))
					     "[\t\n ]*")
				     nil t)))
      (delete-region start (match-end 0)))

    ;; Remove ranking sections.
    (goto-char (point-min))
    (while (and (re-search-forward "\
\[\t\n ]*\\(<!--[\t\n ]*|[\t\n ]*\\)\\(ranking[\t\n ]*|-->\\)"
				   nil t)
		(progn
		  (setq start (match-beginning 0))
		  (re-search-forward (concat (regexp-quote (match-string 1))
					     "/"
					     (regexp-quote (match-string 2))
					     "[\t\n ]*")
				     nil t)))
      (delete-region start (match-end 0)))

    ;; Rearrange the group name so as to be the reverse order.
    (when (string-match "\\." group)
      (setq group (mapconcat 'identity
			     (nreverse (split-string group "\\."))
			     ".")))

    (goto-char (point-min))
    (while (re-search-forward regexp nil t)
      (unless ;; Exclude duplications.
	  (or (member (setq url (match-string (nth 0 numbers))) urls)
	      (progn
		(push url urls)
		(shimbun-search-id
		 shimbun
		 (setq id (concat
			   "<" (match-string (nth 1 numbers)) "%" group
			   "." shimbun-mainichi-top-level-domain ">")))))
	(setq month (string-to-number (match-string (nth 3 numbers)))
	      day (string-to-number (match-string (nth 4 numbers)))
	      subject (match-string (nth 5 numbers)))
	(push
	 (shimbun-create-header
	  0
	  (if editorial
	      (format "%02d/%02d %s" month day subject)
	    subject)
	  from
	  (shimbun-mainichi-make-date-string
	   (string-to-number (match-string (nth 2 numbers)))
	   month day
	   (when (nth 7 numbers)
	     (if (match-beginning (nth 7 numbers))
		 (format "%02d:%02d"
			 (string-to-number (match-string (nth 6 numbers)))
			 (string-to-number (match-string (nth 7 numbers))))
	       "23:59:59")))
	  id "" 0 0
	  (shimbun-expand-url url shimbun-mainichi-url))
	 headers)))
    (prog1
	(setq headers (shimbun-sort-headers headers))
      (while headers
	(setq header (pop headers)
	      date (shimbun-header-date header))
	(when (string-match "23:59:59" date)
	  (shimbun-header-set-date header
				   (replace-match "00:00" nil nil date)))))))

(luna-define-method shimbun-make-contents :before ((shimbun shimbun-mainichi)
						   header)
  (shimbun-mainichi-prepare-article shimbun header))

(defun shimbun-mainichi-prepare-article (shimbun header)
  (shimbun-with-narrowed-article
   shimbun
   ;; Fix the Date header.
   (when (re-search-forward "<p>$BKhF|?7J9!!(B\
\\(20[0-9][0-9]\\)$BG/(B\\([01]?[0-9]\\)$B7n(B\\([0-3]?[0-9]\\)$BF|!!(B\
\\([012]?[0-9]\\)$B;~(B\\([0-5]?[0-9]\\)$BJ,(B\\(?:$B!!!J:G=*99?7;~4V!!(B\
\\([01]?[0-9]\\)$B7n(B\\([0-3]?[0-9]\\)$BF|!!(B\
\\([012]?[0-9]\\)$B;~(B\\([0-5]?[0-9]\\)$BJ,!K(B\\)?\\'"
			    nil t)
     (shimbun-header-set-date
      header
      (shimbun-make-date-string
       (string-to-number (match-string 1))
       (string-to-number (or (match-string 6) (match-string 2)))
       (string-to-number (or (match-string 7) (match-string 3)))
       (format "%02d:%02d"
	       (string-to-number (or (match-string 8) (match-string 4)))
	       (string-to-number (or (match-string 9) (match-string 5)))))))
   (let ((group (shimbun-current-group-internal shimbun))
	 (subject (shimbun-header-subject header 'no-encode)))
     (cond ((or (string-equal "eye.kinji" group)
		(string-match "\\`$B6a;vJR!9!'(B" subject))
	    ;; Shorten paragraph separators.
	    (goto-char (point-min))
	    (while (search-forward "</p><p>$B!!!!!!!~(B</p><p>" nil t)
	      (replace-match "<br>$B!!!!!!!~(B<br>")))
	   ((or (string-equal "eye.yoroku" group)
		(string-match "\\`$BM>O?!'(B" subject))
	    ;; Break continuous lines.
	    (goto-char (point-min))
	    (while (search-forward "$B"%(B" nil t)
	      (replace-match "$B!#(B<br><br>$B!!(B")))))
   (if (shimbun-prefer-text-plain-internal shimbun)
       (progn
	 ;; Replace images with text.
	 (goto-char (point-min))
	 (while (re-search-forward "[\t\n ]*<img[\t\n ]+[^>]+>[\t\n ]*" nil t)
	   (replace-match "($B<L??(B)")))
     ;; Break long lines.
     (shimbun-break-long-japanese-lines))))

(provide 'sb-mainichi)

;;; sb-mainichi.el ends here

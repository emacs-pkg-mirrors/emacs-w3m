;;; sb-asahi.el --- shimbun backend for asahi.com -*- coding: iso-2022-7bit; -*-

;; Copyright (C) 2001, 2002, 2003, 2004, 2005, 2006
;; Yuuichi Teranishi <teranisi@gohome.org>

;; Author: TSUCHIYA Masatoshi <tsuchiya@namazu.org>,
;;         Yuuichi Teranishi  <teranisi@gohome.org>,
;;         Katsumi Yamaoka    <yamaoka@jpl.org>,
;;         NOMIYA Masaru      <nomiya@ttmy.ne.jp>
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

;; Original code was nnshimbun.el written by
;; TSUCHIYA Masatoshi <tsuchiya@namazu.org>.

;;; Code:

(require 'shimbun)

(luna-define-class shimbun-asahi (shimbun-japanese-newspaper shimbun) ())

(defvar shimbun-asahi-prefer-text-plain t
  "*Non-nil means prefer text/plain articles rather than html articles.")

(defvar shimbun-asahi-top-level-domain "asahi.com"
  "Name of the top level domain for the Asahi shimbun.")

(defvar shimbun-asahi-url
  (concat "http://www." shimbun-asahi-top-level-domain "/")
  "Name of the parent url.")

(defun shimbun-asahi-make-regexp (name)
  "Return a list of a regexp and numbers for the kansai.NAME group.
Every `.' in NAME will be replaced with `/'."
  (list (let ((s0 "[\t\n $B!!(B]*")
	      (s1 "[\t\n ]+")
	      (no-nl "[^\n<>]+"))
	  (concat "<a" s1 "href=\"/"
		  ;; 1. url
		  "\\(" (shimbun-subst-char-in-string ?. ?/ name) "/"
		  ;; 2. serial number
		  "\\([a-z]*"
		  ;; 3. year
		  "\\(20[0-9][0-9]\\)"
		  ;; 4. month
		  "\\([01][0-9]\\)"
		  ;; 5. day
		  "\\([0-3][0-9]\\)"
		  "[0-9]+\\)"
		  "\\.html\\)"
		  "\">" s0
		  ;; 6. subject
		  "\\(" no-nl "\\)"
		  s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>"))
	1 nil 2 6 3 4 5))

(defvar shimbun-asahi-group-table
  (let* ((s0 "[\t\n $B!!(B]*")
	 (s1 "[\t\n ]+")
	 (no-nl "[^\n<>]+")
	 (default (list
		   (concat
		    "<a" s1 "href=\"/"
		    ;; 1. url
		    "\\(%s/update/"
		    ;; 2. month
		    "\\([01][0-9]\\)"
		    ;; 3. day
		    "\\([0-3][0-9]\\)"
		    "/"
		    ;; 4. serial number
		    "\\([a-z]*[0-9]+\\)"
		    "\\.html\\)"
		    "\">" s0
		    ;; 5. subject
		    "\\(" no-nl "\\)"
		    s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>")
		   1 4 nil 5 nil 2 3))
	 (default2 (shimbun-asahi-make-regexp "%s"))
	 (default3 (list
		    (concat
		     "<li>" s0 "<a" s1 "href=\"/+"
		     ;; 1. url
		     "\\(\\(?:[^\"/<>]+/\\)+"
		     ;; 2. serial number
		     "\\([a-z]*"
		     ;; 3. year
		     "\\(20[0-9][0-9]\\)"
		     ;; 4. month
		     "\\([01][0-9]\\)"
		     ;; 5. day
		     "\\([0-3][0-9]\\)"
		     "[0-9]+\\)"
		     "\\.html\\)"
		     "\">" s0
		     ;; 6. subject
		     "\\(" no-nl "\\)"
		     s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>")
		    1 nil 2 6 3 4 5))
	 (book1 (list
		 (concat
		  "<a" s1 "href=\"/"
		  ;; 1. url
		  "\\(\\(?:[^\"/>]+/\\)+"
		  ;; 3. serial number
		  "\\("
		  "\\(?:[^0-9]+\\)?"
		  ;; 4. year
		  "\\(20[0-9][0-9]\\)"
		  "[^.]+\\)"
		  "\\.html\\)"
		  "\"" s0 ">" s0
		  ;; 5. subject
		  "\\(" no-nl "\\)"
		  s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>\\(?:"
		  s0 "<[^>]+>\\)*" s0 "("
		  ;; 6. month
		  "\\([01][0-9]\\)"
		  "/"
		  ;; 7.day
		  "\\([0-3][0-9]\\)"
		  ")")
		 1 2 nil 4 3 5 6))
	 (book2 (list
		 (concat
		  "<a" s1 "href=\"/"
		  ;; 1. url
		  "\\(\\(?:[^\"/>]+/\\)+"
		  ;; 2. serial number
		  "\\([^.]+\\)"
		  "\\.html\\)"
		  "\"" s0 ">" s0
		  ;; 3. subject
		  "\\(" no-nl "\\)"
		  s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>"
		  "\\(?:[^<>]*<[^!>]+>\\)+" s0 "\\[$B7G:\(B\\]\\(?:\\cj\\)*"
		  ;; 4. year
		  "\\(20[0-9][0-9]\\)"
		  "$BG/(B"
		  ;; 5. month
		  "\\([01]?[0-9]\\)"
		  "$B7n(B"
		  ;; 6. day
		  "\\([0-3]?[0-9]\\)"
		  "$BF|(B\\(?:\\cj\\)*" s0 "<")
		 1 2 nil 3 4 5 6))
	 (edu (shimbun-asahi-make-regexp "edu.news"))
	 (health (shimbun-asahi-make-regexp "health.news"))
	 (international (list
			 (concat
			  "<a" s1 "href=\"/"
			  ;; 1. url
			  "\\(international/update/"
			  ;; 2. month
			  "\\([01][0-9]\\)"
			  ;; 3. day
			  "\\([0-3][0-9]\\)"
			  "/"
			  ;; 4. serial number
			  "\\([a-z]*[0-9]+\\)"
			  "\\.html\\)"
			  "\">" s0
			  ;; 5. subject
			  "\\(" no-nl "\\)"
			  s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>")
			 1 4 nil 5 nil 2 3)))
    `(("book.author" "BOOK: $BCx<T$K2q$$$?$$(B" nil ,@book2)
      ("book.bestseller" "BOOK: $B%Y%9%H%;%i!<2wFI(B" nil ,@book2)
      ("book.booktimes" "BOOK: BOOK TIMES" nil ,@book2)
      ("book.bunko" "BOOK: $B0&$G$?$$J88K(B" nil ,@book2)
      ("book.comic" "BOOK: $B%3%_%C%/65M\9V:B(B" nil ,@book2)
      ("book.edu" "BOOK: $B650i!&$3$I$b$NK\(B" nil ,@book2)
      ("book.hondana" "BOOK: $BOCBj$NK\C*(B" "book/hondana/index.html" ,@book2)
      ("book.navi" "BOOK: $BFI=q%J%S(B" nil ,@book2)
      ("book.news" "BOOK: $B=PHG%K%e!<%9(B" nil
       ,(concat
	 "<a" s1 "href=\"/"
	 ;; 1. url
	 "\\(\\(?:[^\"/>]+/\\)+"
	 ;; 2. serial number
	 "\\([^.]+\\)"
	 "\\.html\\)"
	 "\"" s0 ">" s0
	 ;; 3. subject
	 "\\(" no-nl "\\)"
	 s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>\\(?:[^<>]*<[^!>]+>\\)+"
	 s0 "\\[$B99?7(B\\]"
	 ;; 4. year
	 "\\(20[0-9][0-9]\\)"
	 "$BG/(B"
	 ;; 5. month
	 "\\([01][0-9]\\)"
	 "$B7n(B"
	 ;; 6. day
	 "\\([0-3][0-9]\\)"
	 "$BF|(B"
	 ;; 7. hour
	 "\\([012][0-9]\\)"
	 "$B;~(B"
	 ;; 8. minute
	 "\\([0-5][0-9]\\)"
	 "$BJ,(B" s0 "<")
       1 2 nil 3 4 5 6)
      ("book.paperback" "BOOK: $BJ88K!&?7=q(B" nil ,@book2)
      ("book.pocket" "BOOK: $B%]%1%C%H$+$i(B" nil ,@book2)
      ("book.ranking" "BOOK: $BGd$l6Z%i%s%-%s%0(B" nil ,@book1)
      ("book.review" "BOOK: $B=qI>(B" nil ,@book2)
      ("book.shinsho" "BOOK: $B?7=q$N7j(B" nil ,@book2)
      ("book.special" "BOOK: $BFC=8(B" nil ,@book1)
      ("book.topics" "BOOK: $B%K%e!<%9$JK\(B" nil ,@book2)
      ("book.watch" "BOOK: $B%^%,%8%s%&%*%C%A(B" nil ,@book2)
      ("business" "$B%S%8%M%9(B" "%s/list.html" ,@default)
      ;; The url should be ended with "index.html".
      ("business.column" "$B7P:Q5$>]Bf(B" "business/column/index.html" ,@default2)
      ("car" "$B0&<V(B" "%s/news/" ,@(shimbun-asahi-make-regexp "car.news"))
      ("car.italycolumn" "$B%$%?%j%"H/%"%b!<%l!*%b%H!<%l!*(B" nil ,@default2)
      ("car.motorsports" "$B%b!<%?!<%9%]!<%D(B" nil ,@default2)
      ("car.newcar" "$B?7<V>pJs(B" nil ,@default2)
      ("car.newcarbywebcg" "$B?7<VH/I=2q(B" nil ,@default2)
      ("culture" "$BJ82=!&7]G=(B" "%s/list.html" ,@default)
      ("culture.column" "$B$b$d$7$N$R$2(B" "culture/column/moyashi/"
       ,@(shimbun-asahi-make-regexp "culture.column.moyashi"))
      ("culture.yurufemi" "$B$f$k$f$k%U%'%_%K%s(B" "culture/column/yurufemi/"
       ,@(shimbun-asahi-make-regexp "culture.column.yurufemi"))
      ("digital" "$B%G%8%?%k5!4o(B" "digital/av/"
       ,@(shimbun-asahi-make-regexp "digital.av"))
      ("digital.apc" "$B;(;o!V(BASAHI$B%Q%=%3%s!W%K%e!<%9(B" nil ,@default2)
      ("digital.av" "$B%G%8%?%k5!4o(B" nil ,@default2)
      ("digital.bcnnews" "e$B%S%8%M%9>pJs(B ($BDs6!!'#B#C#N(B)" nil ,@default2)
      ("digital.column01" "$B%G%8%?%k%3%i%`(B" nil ,@default2)
      ("digital.hotwired" "HotWired Japan" nil ,@default2)
      ("digital.internet" "$B%M%C%H!&%&%$%k%9(B" nil ,@default2)
      ("digital.mobile" "$B7HBSEEOC(B" nil ,@default2)
      ("digital.nikkanko" "$BF|4)9)6H?7J9%K%e!<%9(B" nil ,@default2)
      ("digital.pc" "$B#P#C!&%2!<%`(B" nil ,@default2)
      ("editorial" "$B<R@b(B" "paper/editorial.html"
       ,(concat
	 "<a" s1 "href=\"\\./"
	 ;; 1. url
	 "\\(editorial"
	 ;; 2. year
	 "\\(20[0-9][0-9]\\)"
	 ;; 3. month
	 "\\([01][0-9]\\)"
	 ;; 4. day
	 "\\([0-3][0-9]\\)"
	 "\\.html\\)"
	 "\"")
       1 nil nil nil 2 3 4)
      ("edu" "$B650i(B" "%s/news/index.html" ,@edu)
      ("edu.column" "$B650i%3%i%`(B" "edu/column/ikuji/"
       ,@(shimbun-asahi-make-regexp "edu.column.ikuji"))
      ("edu.it" "IT$B650i(B" "edu/news/it.html" ,@edu)
      ("edu.kosodate" "$B;R0i$F(B" "edu/news/kosodate.html" ,@edu)
      ("edu.news" "$B650i0lHL(B" nil ,@edu)
      ("edu.nyushi" "$BBg3X!&F~;n(B" "edu/news/nyushi.html" ,@edu)
      ("edu.tamate" "$B$N$N$A$c$s$N$U$7$.6L<jH"(B" "edu/nie/tamate/"
       ,@(shimbun-asahi-make-regexp "edu.nie.tamate.kiji"))
      ("english" "ENGLISH" "%s/index.html"
       ,@(let ((rest (shimbun-asahi-make-regexp "english.Herald-asahi")))
	   (cons (concat
		  (car rest)
		  "\\(?:" s0 "<[^>]+>\\)*" s0 "([01]?[0-9]/[0-3]?[0-9])")
		 (cdr rest))))
      ("health" "$B7r9/!&@83h(B" "%s/news/" ,@health)
      ("health.aged" "$BJ!;c!&9bNp(B" "health/news/aged.html" ,@health)
      ("health.alz" "$BG'CN>IFC=8(B" "health/news/alz.html" ,@health)
      ("health.medical" "$B0eNE!&IB5$(B" "health/news/medical.html" ,@health)
      ("housing" "$B=;$^$$(B" "%s/news/"
       ,@(shimbun-asahi-make-regexp "housing.news"))
      ("housing.amano" "$BE7Ln>4$N$$$$2H$$$$2HB2(B" nil ,@default2)
      ("housing.column" "$B=;$^$$$N$*LrN)$A%3%i%`(B" nil ,@default2)
      ("housing.diary" "$B>.$5$J2H$N@83hF|5-(B" nil ,@default2)
      ("housing.soudan" "$B$3$3$,CN$j$?$$!*(B" nil ,@default2)
      ("housing.world" "$B@$3&$N%&%A(B" nil ,@default2)
      ("igo" "$B0O8k(B" "%s/news/" ,@(shimbun-asahi-make-regexp "igo.news"))
      ("international" "$B9q:](B" "%s/list.html" ,@default)
      ("international.america" "$BFnKL%"%a%j%+(B" "international/america.html"
       ,@international)
      ("international.asia" "$B%"%8%"!&B@J?MN(B" "international/asia.html"
       ,@international)
      ("international.asiamachi" "$B%"%8%"$N393Q(B" nil ,@default2)
      ("international.europe" "$B%h!<%m%C%Q(B" "international/europe.html"
       ,@international)
      ("international.etc" "$B9qO"!&$=$NB>(B" "international/etc.html"
       ,@international)
      ("international.jinmin" "$B?ML1F|Js(B" "international/jinmin/index.html"
       ,@default2)
      ("international.middleeast" "$BCfEl!&%"%U%j%+(B"
       "international/middleeast.html" ,@international)
      ("international.seoul" "$B%9%Q%$%7!<!*%=%&%k(B" nil ,@default2)
      ("international.shien" "$B9q:];Y1g$N8=>l$+$i(B" nil ,@default2)
      ("job" "$B="?&!&E>?&(B" "%s/news/"
       ,@(shimbun-asahi-make-regexp "job.news"))
      ("job.special" "$B=54)D+F|!&#A#E#R#A$+$i(B" nil
       ,(concat
	 (car default2)
	 "\\(?:" s0 "<[^>]+>\\)*" s0 "$B!J(B" s0
	 ;; 7. extra
	 "\\(" no-nl "\\)"
	 "$B!'(B")
       ,@(cdr default2) nil 7)
      ("kansai" "$B4X@>(B" "%s/news/" ,@(shimbun-asahi-make-regexp "kansai.news"))
      ("kansai.honma" "$B$+$-$/$1$3$I$b$N$O$R$U$X$[$s$^!)(B" nil ,@default2)
      ("kansai.beichou" "$BJFD+8}$^$+$;(B" nil ,@default2)
      ("kansai.kansaiisan" "$B>!<j$K4X@>@$3&0d;:(B" nil ,@default2)
      ("kansai.umaimon" "$B$&$^$$$b$s(B" nil ,@default2)
      ("kansai.sweets" "$B?h!&$9$$!<$D(B" nil ,@default2)
      ("kansai.fuukei" "$B?7(B $BIw7J$rJb$/(B" "kansai/fuukei2/"
       ,@(shimbun-asahi-make-regexp "kansai.fuukei2"))
      ("kansai.otoriyose" "$B$o$/$o$/$*<h$j4s$;(B" nil ,@default2)
      ("kansai.sakana" "$B$d$5$7$$:h(B" nil ,@default2)
      ("kansai.depa" "$B%G%QCO2<#N#E#W#S(B" nil ,@default2)
      ("kansai.kataritsugu" "$B8l$j$D$0@oAh(B" nil ,@default2)
      ("kansai.okan" "$BJl$5$s$NCN7CB^(B" nil ,@default2)
      ("kansai.madam" "$BM<4)%^%@%`(B" nil ,@default2)
      ("kansai.heibon" "$B=54)!zJ?K^!z=w@-(B" nil ,@default2)
      ("kansai.sanshi" "$B;0;^$N>P%&%$%s%I%&(B" nil ,@default2)
      ("life" "$BJk$i$7(B" "%s/list.html" ,@default)
      ("life.column" "$BJk$i$7%3%i%`(B" nil
       ,(concat
	 "<a" s1 "href=\"/"
	 ;; 1. url
	 "\\(life/column/"
	 ;; 2. serial number
	 "\\(.+/[a-z]*"
	 ;; 3. year
	 "\\(20[0-9][0-9]\\)"
	 ;; 4. month
	 "\\([01][0-9]\\)"
	 ;; 5. day
	 "\\([0-3][0-9]\\)"
	 "[0-9]*\\)"
	 "\\.html\\)"
	 "\">" s0
	 ;; 6. subject
	 "\\(" no-nl "\\)"
	 s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>")
       1 nil 2 6 3 4 5)
      ("life.food" "$B?)$HNAM}(B" nil
       ,(concat
	 "<a" s1 "href=\"/"
	 ;; 1. url
	 "\\(life/food/"
	 ;; 2. serial number
	 "\\(.+/[a-z]*"
	 ;; 3. year
	 "\\(20[0-9][0-9]\\)"
	 ;; 4. month
	 "\\([01][0-9]\\)"
	 ;; 5. day
	 "\\([0-3][0-9]\\)"
	 "[0-9]+\\)"
	 "\\.html\\)"
	 "\">" s0
	 ;; 6. subject
	 "\\(" no-nl "\\)"
	 s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>")
       1 nil 2 6 3 4 5)
      ("national" "$B<R2q(B" "%s/list.html" ,@default)
      ("national.calamity" "$B:R32!&8rDL>pJs(B" "national/calamity.html"
       ,@default3)
      ("national.etc" "$B$=$NB>!&OCBj(B" "national/etc.html" ,@default3)
      ("national.trial" "$B:[H=(B" "national/trial.html" ,@default3)
      ("obituaries" "$B$*$/$d$_(B" "obituaries" ,@default)
      ("politics" "$B@/<#(B" "%s/list.html" ,@default)
      ("rss" "RSS" "http://www3.asahi.com/rss/index.rdf"
       ,(concat
	 "<title>"
	 ;; 1. subject
	 "\\([^<]+\\)"
	 "</title>\n<link>"
	 ;; 2. url
	 "\\(http://www\\.asahi\\.com/"
	 ;; 3. extra keyword (en)
	 "\\([^/]+\\)"
	 "/update/"
	 ;; 4 and 5. serial number
	 "\\([0-9]+\\)/\\([a-z]*[0-9]+\\)"
	 "\\.html\\?ref=rss\\)"
	 "</link>\n<description/>\n<dc:subject>"
	 ;; 6. extra keyword (ja)
	 "\\([^<]+\\)"
	 "</dc:subject>\n<dc:date>20[0-9][0-9]-"
	 ;; 7. month
	 "\\([01][0-9]\\)"
	 "-"
	 ;; 8. day
	 "\\([0-3][0-9]\\)"
	 "T"
	 ;; 9. hour:min:sec
	 "\\([012][0-9]:[0-5][0-9]:[0-5][0-9]\\)")
       2 4 5 1 nil 7 8 9 3 nil 6)
      ("science" "$B%5%$%(%s%9(B" "%s/list.html"
       ,@(shimbun-asahi-make-regexp "science.news"))
      ("shopping" "$B%7%g%C%T%s%0(B" "%s/"
       ,(concat
	 "<a" s1 "href=\"/"
	 ;; 1. url
	 "\\(\\(?:[^\"/]+/\\)+"
	 ;; 2. extra
	 "\\([^\"/]+\\)"
	 "/"
	 ;; 3. serial number
	 "\\([a-z]*"
	 ;; 4. year
	 "\\(20[0-9][0-9]\\)"
	 ;; 5. month
	 "\\([01][0-9]\\)"
	 ;; 6. day
	 "\\([0-3][0-9]\\)"
	 "[0-9]+\\)"
	 "\\.html\\)"
	 "\">\\(?:" s0 "<[^<>]+>\\)*" s0
	 ;; 7. subject
	 "\\([^>]+\\)"
	 "\\(?:" s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>\\)?"
	 s0 "<span" s1 "class=\"s\">")
       1 3 nil 7 4 5 6 nil 2)
      ("shopping.kishi" "$B4_D+;R$N5$$K$J$k$*<h$j4s$;(B12$B%+7n(B"
       "shopping/food/kishi"
       ,(concat
	 "<a" s1 "href=\"/"
	 ;; 1. url
	 "\\(shopping/food/kishi/"
	 ;; 2. serial number
	 "\\([a-z]*"
	 ;; 3. year
	 "\\(20[0-9][0-9]\\)"
	 ;; 4. month
	 "\\([01][0-9]\\)"
	 ;; 5. day
	 "\\([0-3][0-9]\\)"
	 "[0-9]+\\)\\.html\\)\">" s0 "<div" s1 "class=\"keyword\">" s0
	 ;; 6. subject
	 "\\(" no-nl s0 "</div>" s0 no-nl "\\)"
	 s0)
       1 nil 2 6 3 4 5)
      ("shougi" "$B>-4}(B" "%s/news/" ,@(shimbun-asahi-make-regexp "shougi.news"))
      ("sports" "$B%9%]!<%D(B" "%s/list.html"
       ,(concat
	 "<a" s1 "href=\"/?"
	 ;; 1. url
	 "\\(\\(?:sports/update/\
\\|http://www2.asahi.com/torino2006/news/[a-z]+2006\\)"
	 ;; 2. month
	 "\\([01][0-9]\\)"
	 ;; 3. day
	 "\\([0-3][0-9]\\)"
	 "/?"
	 ;; 4. serial number
	 "\\([a-z]*[0-9]+\\)"
	 "\\.html\\)"
	 "\">" s0
	 ;; 5. subject
	 "\\(" no-nl "\\)"
	 s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>")
       1 4 nil 5 nil 2 3)
    ("sports.baseball" "$BLn5e(B" "sports/bb/"
       ,@(shimbun-asahi-make-regexp "sports.bb"))
      ("sports.column" "$B%9%]!<%D%3%i%`(B" nil ,@default2)
      ("sports.football" "$B%5%C%+!<(B" "sports/fb/"
       ,@(shimbun-asahi-make-regexp "sports.fb"))
      ("sports.spo" "$B0lHL%9%]!<%D(B" nil ,@default2)
      ("tenjin" "$BE7@<?M8l(B" "paper/column.html"
       ,(concat
	 "<a" s1 "href=\"\\./"
	 ;; 1. url
	 "\\(column"
	 ;; 2. year
	 "\\(20[0-9][0-9]\\)"
	 ;; 3. month
	 "\\([01][0-9]\\)"
	 ;; 4. day
	 "\\([0-3][0-9]\\)"
	 "\\.html\\)"
	 "\"")
       1 nil nil nil 2 3 4)
      ("travel" "$B%H%i%Y%k(B" "%s/news/"
       ,@(shimbun-asahi-make-regexp "travel.news"))
      ("travel.kaido" "$B;JGONKB@O:!&39F;$r$f$/(B" nil ,@default2)
      ("travel.matsuri" "$BF|K\$N:W$j(B" nil ,@default2)
      ("travel.zeitaku" "$BCO5e$NlT$?$/(B" nil
       ,(concat "<a" s1 "href=\""
		;; 1. url
		"\\(http://www\\.asahi\\.com/travel/zeitaku/"
		;; 2. serial number
		"\\([a-z]*"
		;; 3. year
		"\\(20[0-9][0-9]\\)"
		;; 4. month
		"\\([01][0-9]\\)"
		;; 5. day
		"\\([0-3][0-9]\\)"
		"[0-9]+\\)"
		"\\.html\\)"
		"\">" s0
		;; 6. subject
		"\\(" no-nl "\\)"
		s0 "\\(?:<img" s1 "[^>]+>" s0 "\\)?</a>")
       1 nil 2 6 3 4 5)
      ("wakamiya" "$BIw9M7W(B ($BO@@b<g44!&<c5\7<J8(B)" nil
       ,@(shimbun-asahi-make-regexp "column.wakamiya"))
      ("world.china" "$BCf9qFC=8(B" nil
       ,@(shimbun-asahi-make-regexp "world.china.news"))
      ("world.germany" "$B%I%$%DG/FC=8(B" nil
       ,@(shimbun-asahi-make-regexp "world.germany.news"))

      ;; The following groups are obsolete, though old articles still
      ;; can be read.
      ("kansai.densetsu" "$B$[$s$^!)4X@>EA@b(B" nil ,@default2)
      ("kansai.kaban" "$B$+$P$s$NCf?H(B" nil ,@default2)
      ("kansai.keiki" "$B$1!A$-$N!H$($(OC!I(B" nil ,@default2)
      ("kansai.kyosho" "$B5p>"$K3X$Y(B" nil ,@default2)
      ("kansai.okiniiri" "DJ$B$N$*5$$KF~$j(B" nil ,@default2)
      ("kansai.onayami" "$B$_$&$i$8$e$s$N$*G:$_:W$j(B" nil ,@default2)
      ("kansai.smile" "$B%9%^%$%k%9%?%$%k(B" nil ,@default2)
      ("kansai.syun" "$B=\$N4i(B" nil ,@default2)
      ("kansai.takara" "$B$?$+$i?^4U(B" nil ,@default2)
      ("kansai.yotsuba" "$B$h$DMU$S$h$j(B" nil ,@default2)
      ("nankyoku" "$BFn6K%W%m%8%'%/%H(B" "%s/news/"
       ,@(shimbun-asahi-make-regexp "nankyoku.news"))
      ("nankyoku.borderless" "$B9q6-$N$J$$BgN&$+$i(B" nil ,@default2)
      ("nankyoku.people" "$B1[E_Bb$N?M$S$H(B" nil ,@default2)
      ("nankyoku.whitemail" "WhiteMail$B!wFn6K(B" nil ,@default2)))
  "Alist of group names, their Japanese translations, index pages,
regexps and numbers.  Where index pages and regexps may contain the
\"%s\" token which is replaced with group names, numbers point to the
search result in order of [0]a url, [1,2]a serial number, [3]a subject,
\[4]a year, [5]a month, [6]a day, [7]an hour:minute, [8,9,10]an extra
keyword, [11]hour and [12]minute.  If an index page is nil, a group
name in which \".\" is substituted with \"/\" is used instead.")

(defvar shimbun-asahi-content-start
  "<!--[\t\n ]*Start of \\(Kiji\\|photo\\)[\t\n ]*-->\
\\|<!--[\t\n ]*FJZONE START NAME=\"HONBUN\"[\t\n ]*-->")

(defvar shimbun-asahi-content-end
  "<!--[\t\n ]*End of Kiji[\t\n ]*-->\
\\|<!--[\t\n ]*End of related link[\t\n ]*-->\
\\|<!--[\t\n ]*FJZONE END NAME=\"HONBUN\"[\t\n ]*-->")

(defvar shimbun-asahi-text-content-start
  "<!--[\t\n ]*Start of Kiji[\t\n ]*-->\
\\|<!--[\t\n ]*FJZONE START NAME=\"HONBUN\"[\t\n ]*-->")

(defvar shimbun-asahi-text-content-end
  "<!--[\t\n ]*End of Kiji[\t\n ]*-->\
\\|<!--[\t\n ]*FJZONE END NAME=\"HONBUN\"[\t\n ]*-->")

(defvar shimbun-asahi-x-face-alist
  '(("default" . "X-Face: +Oh!C!EFfmR$+Zw{dwWW]1e_>S0rnNCA*CX|\
bIy3rr^<Q#lf&~ADU:X!t5t>gW5)Q]N{Mmn\n L]suPpL|gFjV{S|]a-:)\\FR\
7GRf9uL:ue5_=;h{V%@()={uTd@l?eXBppF%`6W%;h`#]2q+f*81n$B\n h|t")))

(defvar shimbun-asahi-expiration-days 6)

(luna-define-method initialize-instance :after ((shimbun shimbun-asahi)
						 &rest init-args)
  (shimbun-set-server-name-internal shimbun "$BD+F|?7J9(B")
  (shimbun-set-from-address-internal shimbun "nobody@example.com")
  ;; To share class variables between `shimbun-asahi' and its
  ;; successor `shimbun-asahi-html'.
  (shimbun-set-x-face-alist-internal shimbun shimbun-asahi-x-face-alist)
  (shimbun-set-expiration-days-internal shimbun shimbun-asahi-expiration-days)
  (shimbun-set-content-start-internal shimbun shimbun-asahi-content-start)
  (shimbun-set-content-end-internal shimbun shimbun-asahi-content-end)
  shimbun)

(luna-define-method shimbun-groups ((shimbun shimbun-asahi))
  (mapcar 'car shimbun-asahi-group-table))

(luna-define-method shimbun-current-group-name ((shimbun shimbun-asahi))
  (nth 1 (assoc (shimbun-current-group-internal shimbun)
		shimbun-asahi-group-table)))

(luna-define-method shimbun-index-url ((shimbun shimbun-asahi))
  (let* ((group (shimbun-current-group-internal shimbun))
	 (index (or (nth 2 (assoc group shimbun-asahi-group-table))
		    (concat (shimbun-subst-char-in-string ?. ?/ group) "/"))))
    (cond ((string-match "\\`http:" index)
	   index)
	  ((string-match "\\`book\\." group)
	   (shimbun-expand-url (substring index 5) "http://book.asahi.com/"))
	  ((string-equal "wakamiya" group)
	   "http://www.asahi.com/column/wakamiya/")
	  (t
	   (shimbun-expand-url (format index group) shimbun-asahi-url)))))

(defun shimbun-asahi-get-headers (shimbun)
  "Return a list of headers."
  (let ((group (shimbun-current-group-internal shimbun))
	(from (concat (shimbun-server-name shimbun)
		      " (" (shimbun-current-group-name shimbun) ")"))
	(case-fold-search t)
	regexp jname numbers cyear cmonth rss-p paper-p en-category
	hour-min month year day serial num extra rgroup id headers
	backnumbers book-p)
    (setq regexp (assoc group shimbun-asahi-group-table)
	  jname (nth 1 regexp)
	  numbers (nthcdr 4 regexp)
	  regexp (format (nth 3 regexp)
			 (regexp-quote (shimbun-subst-char-in-string
					?. ?/ group)))
	  cyear (shimbun-decode-time nil 32400)
	  cmonth (nth 4 cyear)
	  cyear (nth 5 cyear)
	  rss-p (string-equal group "rss")
	  paper-p (member group '("editorial" "tenjin"))
	  book-p (string-match "\\`book\\." group))
    (catch 'stop
      ;; The loop for fetching all the articles in the whitemail group.
      (while t
	(while (re-search-forward regexp nil t)
	  (cond ((string-equal group "english")
		 (setq en-category
		       (save-excursion
			 (save-match-data
			   (if (re-search-backward "\
<h[0-9]\\(?:[\n\t ]+[^>]+\\)?>[\t\n ]*\\([^&]+\\)[\t\n ]*&#[0-9]+"
						   nil t)
			       (downcase (match-string 1)))))))
		(t
		 (setq hour-min
		       (save-excursion
			 (save-match-data
			   (if (re-search-forward "\
<span[\t\n ]+[^>]+>[\t\n ]*(\\(?:[01]?[0-9]/[0-3]?[0-9][\t\n ]+\\)?
\\([012]?[0-9]:[0-5][0-9]\\))[\t\n ]*</span>"
						  nil t)
			       (match-string 1)))))))
	  (setq month (string-to-number (match-string (nth 5 numbers)))
		year (if (setq num (nth 4 numbers))
			 (string-to-number (match-string num))
		       (cond ((>= (- month cmonth) 2)
			      (1- cyear))
			     ((and (= 1 month) (= 12 cmonth))
			      (1+ cyear))
			     (t
			      cyear)))
		day (string-to-number (match-string (nth 6 numbers)))
		serial (cond (rss-p
			      (format "%d%s.%s"
				      year
				      (match-string (nth 1 numbers))
				      (match-string (nth 2 numbers))))
			     (paper-p
			      (format "%d%02d%02d" year month day))
			     ((and (setq num (nth 1 numbers))
				   (match-beginning num))
			      (format "%d%02d%02d.%s"
				      year month day (match-string num)))
			     (t
			      (shimbun-subst-char-in-string
			       ?/ ?.
			       (downcase (match-string (nth 2 numbers))))))
		extra (or (and (setq num (nth 8 numbers))
			       (match-beginning num)
			       (match-string num))
			  (and (setq num (nth 9 numbers))
			       (match-beginning num)
			       (match-string num)))
		rgroup (mapconcat 'identity
				  (nreverse (save-match-data
					      (split-string group "\\.")))
				  ".")
		id (if (and extra
			    (not (member group '("job.special"))))
		       (concat "<" serial "%" extra "." rgroup "."
			       shimbun-asahi-top-level-domain ">")
		     (concat "<" serial "%" rgroup "."
			     shimbun-asahi-top-level-domain ">")))
	  (unless (and (shimbun-search-id shimbun id)
		       (if backnumbers
			   (throw 'stop nil)
			 ;; Don't stop it since there might be more new
			 ;; articles even if the same links are repeated.
			 t))
	    (push (shimbun-create-header
		   ;; number
		   0
		   ;; subject
		   (cond (rss-p
			  (match-string (nth 3 numbers)))
			 (en-category
			  (concat "[" en-category "] "
				  (match-string (nth 3 numbers))))
			 ((and (setq num (nth 8 numbers))
			       (match-beginning num))
			  (concat "[" (match-string num) "] "
				  (match-string (nth 3 numbers))))
			 ((and (setq num (nth 9 numbers))
			       (match-beginning num))
			  (concat "[" (match-string num) "] "
				  (match-string (nth 3 numbers))))
			 (paper-p
			  (concat jname (format " (%d/%d)" month day)))
			 (t
			  (match-string (nth 3 numbers))))
		   ;; from
		   (if (and rss-p
			    (setq num (nth 10 numbers))
			    (setq num (match-string num)))
		       (save-match-data
			 (shimbun-replace-in-string
			  from "(RSS" (concat "\\&:" num)))
		     from)
		   ;; date
		   (shimbun-make-date-string
		    year month day
		    (cond ((and (setq num (nth 11 numbers))
				(match-beginning num))
			   (concat (match-string num) ":"
				   (match-string (nth 12 numbers))))
			  ((and (setq num (nth 7 numbers))
				(match-beginning num))
			   (match-string num))
			  (paper-p
			   "07:00")
			  (t
			   hour-min)))
		   ;; id
		   id
		   ;; references, chars, lines
		   "" 0 0
		   ;; xref
		   (shimbun-expand-url
		    (match-string (nth 0 numbers))
		    (cond (paper-p
			   (concat shimbun-asahi-url "paper/"))
			  (book-p
			   "http://book.asahi.com/")
			  (t
			   shimbun-asahi-url))))
		  headers)))
	(if (string-equal group "nankyoku.whitemail")
	    (progn
	      (cond ((eq backnumbers 'stop)
		     (throw 'stop nil))
		    ((null backnumbers)
		     (while (re-search-forward "<a[\t\n ]+href=\"\
\\(http://www\\.asahi\\.com/nankyoku/whitemail/\
backnum0[345][01][0-9]\\.html\\)\">"
					       nil t)
		       (unless (member (setq id (match-string 1)) backnumbers)
			 (push id backnumbers)))))
	      (if backnumbers
		  (progn
		    (shimbun-retrieve-url
		     (prog1
			 (car backnumbers)
		       (erase-buffer)
		       (unless (setq backnumbers (cdr backnumbers))
			 (setq backnumbers 'stop)))))
		(throw 'stop nil)))
	  (throw 'stop nil))))
    (append (shimbun-sort-headers headers)
	    (shimbun-asahi-get-headers-for-today group jname from))))

(luna-define-method shimbun-get-headers ((shimbun shimbun-asahi)
					 &optional range)
  (shimbun-asahi-get-headers shimbun))

(defun shimbun-asahi-get-headers-for-today (group jname from)
  "Return a list of the header for today's article.
It works for only the groups `editorial' and `tenjin'."
  (goto-char (point-min))
  (let ((basename (cdr (assoc group '(("editorial" . "editorial")
				      ("tenjin" . "column")))))
	year month day url)
    (when (and basename
	       (re-search-forward
		(concat
		 ;; 1. year
		 "\\(20[0-9][0-9]\\)" "$BG/(B"
		 ;; 2. month
		 "\\([01]?[0-9]\\)" "$B7n(B"
		 ;; 3. day
		 "\\([0-3]?[0-9]\\)" "$BF|(B"
		 "$B!J(B.$BMKF|!KIU(B")
		nil t))
      (setq year (string-to-number (match-string 1))
	    month (string-to-number (match-string 2))
	    day (string-to-number (match-string 3))
	    url (format "paper/%s%d%02d%02d.html" basename year month day))
      (list
       (shimbun-make-header
	;; number
	0
	;; subject
	(shimbun-mime-encode-string (concat jname
					    (format " (%d/%d)" month day)))
	;; from
	from
	;; date
	(shimbun-make-date-string year month day "07:00")
	;; id
	(format "<%d%02d%02d%%%s.%s>"
		year month day group shimbun-asahi-top-level-domain)
	;; references, chars, lines
	"" 0 0
	;; xref
	(shimbun-expand-url url shimbun-asahi-url))))))

(defun shimbun-asahi-prepare-article (shimbun header)
  "Prepare an article.
Extract the article core on some groups or adjust a date header if
there is a correct information available.  For the groups editorial
and tenjin, it tries to fetch the article for that day if it failed."
  (let ((case-fold-search t)
	(group (shimbun-current-group-internal shimbun)))
    (cond
     ((string-match "\\`book\\." group)
      (when (re-search-forward
	     "<p class=\"midasi13\">[^<>]+<br>\\[$BI><T(B\\]\\([^<>]+\\)</p>"
	     nil t)
	(shimbun-header-set-from header (match-string 1))
	(goto-char (point-min)))
      ;; Collect images.
      (let (start end images)
	(while (re-search-forward "<div[\t\n ]+class=\"bokp\">" nil t)
	  (setq start (match-beginning 0))
	  (when (and (search-forward "</div>" nil t)
		     (re-search-forward "\\([\t\n ]*<!--$B9XF~(B-->\\)\\|</div>"
					nil t))
	    (setq images
		  (nconc images
			 (list (buffer-substring start (or (match-beginning 1)
							   (match-end 0))))))
	    (delete-region start (point))))
	(when (and images
		   (progn
		     (goto-char (point-min))
		     (re-search-forward shimbun-asahi-content-start nil t)))
	  (insert "\n")
	  (while images
	    (insert (pop images)
		    (if images
			"<br>\n"
		      "\n"))))))
     ((string-equal group "culture.yurufemi")
      (let (start comics)
	(while (and (search-forward "alt=\"$B%^%s%,(B\"" nil t)
		    (re-search-backward "<table[\t\n ]+" nil t)
		    (progn
		      (setq start (match-beginning 0))
		      (search-forward "</table>" nil t))
		    (push (buffer-substring start (match-end 0)) comics)))
	(erase-buffer)
	(when comics
	  (insert "<!-- Start of Kiji -->\n"
		  (mapconcat 'identity comics "\n")
		  "\n<!-- End of Kiji -->\n"))))
     ((string-equal group "editorial")
      (let ((regexp "\
<h[0-9]\\(?:[\t\n ]+[^>]+\\)?>[\t\n ]*<a[\t\n ]+name=\"syasetu[0-9]+\">")
	    (retry 0)
	    index)
	(while (<= retry 1)
	  (if (re-search-forward regexp nil t)
	      (progn
		(goto-char (match-beginning 0))
		(insert "<!-- Start of Kiji -->")
		(when index
		  (insert "\
\n<p>($B;XDj$5$l$?(B&nbsp;url&nbsp$B$,(B&nbsp$B$^$@(B/$B$9$G$K(B&nbsp$BL5$$$N$G!"(B\
<a href=\"" index "\">$B%H%C%W%Z!<%8(B</a> $B$+$i5-;v$r<hF@$7$^$7$?(B)</p>\n"))
		(search-forward "</a>" nil t)
		(while (re-search-forward regexp nil t))
		(when (re-search-forward "[\n\t ]*</p>" nil t)
		  (insert "\n<!-- End of Kiji -->"))
		(setq retry 255))
	    (erase-buffer)
	    (if (zerop retry)
		(progn
		  (shimbun-retrieve-url (setq index
					      (shimbun-index-url shimbun)))
		  (goto-char (point-min)))
	      (insert "Couldn't retrieve the page.\n")))
	  (setq retry (1+ retry)))))
     ((string-equal group "tenjin")
      (let ((retry 0)
	    index)
	(while (<= retry 1)
	  (if (and (search-forward "$B!ZE7@<?M8l![(B" nil t)
		   (re-search-forward "<SPAN STYLE=[^>]+>[\t\n ]*" nil t))
	      (progn
		(insert "<!-- Start of Kiji -->")
		(when index
		  (insert "\
\n<p>($B;XDj$5$l$?(B&nbsp;url&nbsp$B$,(B&nbsp$B$^$@(B/$B$9$G$K(B&nbsp$BL5$$$N$G!"(B\
<a href=\"" index "\">$B%H%C%W%Z!<%8(B</a> $B$+$i5-;v$r<hF@$7$^$7$?(B)</p>\n"))
		(while (re-search-forward "[\t\n ]*<SPAN STYLE=[^>]+>[\t\n ]*"
					  nil t)
		  (delete-region (match-beginning 0) (match-end 0)))
		(when (re-search-forward "[\t\n ]*</SPAN>" nil t)
		  (goto-char (match-beginning 0))
		  (insert "\n<!-- End of Kiji -->"))
		(setq retry 255))
	    (erase-buffer)
	    (if (zerop retry)
		(progn
		  (shimbun-retrieve-url (setq index
					      (shimbun-index-url shimbun)))
		  (goto-char (point-min)))
	      (insert "Couldn't retrieve the page.\n")))
	  (setq retry (1+ retry)))))
     ((string-equal group "shopping")
      (let ((subgroup (shimbun-header-xref header)))
	(when (string-match "\\([^/]+\\)/[^/]+\\'" subgroup)
	  (setq subgroup (match-string 1 subgroup))
	  (cond ((string-equal subgroup "asapaso")
		 (when (re-search-forward
			"<div[\t\n ]+id=\"photo[0-9]+\">[\t\n ]*"
			nil t)
		   (delete-region (point-min) (point))
		   (insert "<!-- Start of Kiji -->")
		   (when (re-search-forward "\
\\(?:[\t\n ]*<[^>]+>\\)*<div[\t\n ]+class=\"gotobacknumber\">"
					    nil t)
		     (goto-char (match-beginning 0))
		     (insert "<!-- End of Kiji -->"))))
		((string-equal subgroup "interiorlife")
		 (when (re-search-forward
			"<p[\t\n ]+class=\"intro\">[\t\n ]*"
			nil t))
		 (delete-region (point-min) (point))
		 (insert "<!-- Start of Kiji -->")
		 (when (re-search-forward "\
\\(?:[\t\n ]*<[^>]+>\\)*<div[\t\n ]+class=\"gotobacknumber\">"
					  nil t)
		   (goto-char (match-beginning 0))
		   (insert "<!-- End of Kiji -->")))
		((string-equal subgroup "dvd")
		 (let ((regexp (shimbun-content-end shimbun)))
		   (while (re-search-forward regexp nil t)
		     (replace-match "\n")))
		 (goto-char (point-min))
		 (when (re-search-forward "\\(?:\
<!--$BFC=8(B-->\\|<div[\t\n ]+id=kijih>\\|<!--[\t\n ]+Start of Headline[\t\n ]+-->\
\\)[\t\n ]*"
					  nil t)
		   (insert "<!-- Start of Kiji -->")
		   (when (re-search-forward "\
\[\t\n ]*\\(?:<!--/$B:nIJ>R2p$3$3$^$G(B-->\\|<!--/$BFC=8(B-->\\)"
					    nil t)
		     (insert "<!-- End of Kiji -->"))))
		((member subgroup '("hobby" "music"))
		 (let ((regexp (shimbun-content-end shimbun)))
		   (while (re-search-forward regexp nil t)
		     (replace-match "\n")))
		 (goto-char (point-min))
		 (when (re-search-forward "\
\[\t\n ]*\\(?:<!--/$B:nIJ>R2p$3$3$^$G(B-->\\|<!--/$BFC=8(B-->\\)"
					  nil t)
		   (insert "<!-- End of Kiji -->")))))))
     ((string-equal group "shopping.kishi")
      (when (re-search-forward "<div[\t\n ]+id=\"kijih\">[\t\n ]*" nil t)
	(insert "<!-- Start of Kiji -->")))
     ((string-equal group "rss"))
     ((string-equal group "world.china")
      (let (start)
	(when (and (re-search-forward "\
<H2>$BCf9q:G?7%K%e!<%9(B</H2>[\t\n ]*<H1>[^>]+</H1>[\t\n ]*"
				      nil t)
		   (progn
		     (setq start (match-end 0))
		     (re-search-forward "\
<p[^>]*>[\t\n ]*([01][0-9]/[0-3][0-9])[\t\n ]*</p>"
					nil t)))
	  (delete-region (match-end 0) (point-max))
	  (insert "\n<!-- End of Kiji -->")
	  (delete-region (point-min) (goto-char start))
	  (insert "<!-- Start of Kiji -->\n"))))
     (t
      (when (re-search-forward
	     (eval-when-compile
	       (let ((s0 "[\t\n ]*")
		     (s1 "[\t\n ]+"))
		 (concat "<p" s1 "class" s0 "=" s0 "\"day\"" s0 ">" s0
			 ;; 1. year
			 "\\(20[0-9][0-9]\\)$BG/(B"
			 ;; 2. month
			 "\\([01]?[0-9]\\)$B7n(B"
			 ;; 3. day
			 "\\([0-3]?[0-9]\\)$BF|(B"
			 ;; 4. hour
			 "\\([012]?[0-9]\\)$B;~(B"
			 ;; 5. minute
			 "\\([0-5]?[0-9]\\)$BJ,(B"
			 s0 "</p>")))
	     nil t)
	(shimbun-header-set-date
	 header
	 (shimbun-make-date-string
	  (string-to-number (match-string 1))
	  (string-to-number (match-string 2))
	  (string-to-number (match-string 3))
	  (concat (match-string 4) ":" (match-string 5))
	  "+0900"))))))
  (goto-char (point-min)))

(luna-define-method shimbun-make-contents :before ((shimbun shimbun-asahi)
						   header)
  (shimbun-asahi-prepare-article shimbun header))

(provide 'sb-asahi)

;;; sb-asahi.el ends here

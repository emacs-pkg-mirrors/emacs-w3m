;;; w3m-weather.el --- Add-on program to look weather forecast

;; Copyright (C) 2001 TSUCHIYA Masatoshi <tsuchiya@pine.kuee.kyoto-u.ac.jp>

;; Authors: TSUCHIYA Masatoshi <tsuchiya@pine.kuee.kyoto-u.ac.jp>,
;; Keywords: w3m, WWW, hypermedia

;; w3m-weather.el is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of the
;; License, or (at your option) any later version.

;; w3m-weather.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with w3m.el; if not, write to the Free Software Foundation,
;; Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


;;; Commentary:

;; w3m-weather.el is the add-on program of w3m.el to look weather
;; foracast.  For more detail about w3m.el, see:
;;
;;    http://namazu.org/~tsuchiya/emacs-w3m/


;;; How to install:

;; Please put this file to appropriate directory, and if you want
;; byte-compile it.  And add following lisp expressions to your
;; ~/.emacs.
;;
;;     (autoload 'w3m-weather "w3m-weather" "Display weather report." t)


;;; Code:

(require 'w3m)

(defconst w3m-weather-url-alist
  (eval-when-compile
    (let ((format "http://channel.goo.ne.jp/weather/area/%s.html")
	  (alist
	   '(("$BKL3$F;!&=!C+COJ}(B" . "011")
	     ("$BKL3$F;!&LVAvCOJ}(B" . "021")
	     ("$BKL3$F;!&KL8+COJ}(B" . "022")
	     ("$BKL3$F;!&LfJLCOJ}(B" . "023")
	     ("$BKL3$F;!&>e@nCOJ}(B" . "031")
	     ("$BKL3$F;!&N1K(COJ}(B" . "032")
	     ("$BKL3$F;!&6|O)COJ}(B" . "041")
	     ("$BKL3$F;!&:,<<COJ}(B" . "042")
	     ("$BKL3$F;!&==>!COJ}(B" . "043")
	     ("$BKL3$F;!&C@?6COJ}(B" . "051")
	     ("$BKL3$F;!&F|9bCOJ}(B" . "052")
	     ("$BKL3$F;!&@P<mCOJ}(B" . "061")
	     ("$BKL3$F;!&6uCNCOJ}(B" . "062")
	     ("$BKL3$F;!&8e;VCOJ}(B" . "063")
	     ("$BKL3$F;!&EOEgCOJ}(B" . "071")
	     ("$BKL3$F;!&[X;3COJ}(B" . "072")
	     ("$B@D?98)!&DE7ZCOJ}(B" . "081")
	     ("$B@D?98)!&2<KLCOJ}(B" . "082")
	     ("$B@D?98)!&;0H,>eKLCOJ}(B" . "083")
	     ("$B=)ED8)!&1h4_It(B" . "091")
	     ("$B=)ED8)!&FbN&It(B" . "092")
	     ("$B4d<j8)!&FbN&It(B" . "101")
	     ("$B4d<j8)!&1h4_KLIt(B" . "102")
	     ("$B4d<j8)!&1h4_FnIt(B" . "103")
	     ("$B;37A8)!&B<;3COJ}(B" . "111")
	     ("$B;37A8)!&CV;rCOJ}(B" . "112")
	     ("$B;37A8)!&>1FbCOJ}(B" . "113")
	     ("$B;37A8)!&:G>eCOJ}(B" . "114")
	     ("$B5\>k8)!&J?LnIt(B" . "121")
	     ("$B5\>k8)!&;31h$$(B" . "122")
	     ("$BJ!Eg8)!&CfDL$j(B" . "131")
	     ("$BJ!Eg8)!&IMDL$j(B" . "132")
	     ("$BJ!Eg8)!&2qDECOJ}(B" . "133")
	     ("$B?73c8)!&2<1[COJ}(B" . "141")
	     ("$B?73c8)!&Cf1[COJ}(B" . "142")
	     ("$B?73c8)!&>e1[COJ}(B" . "143")
	     ("$B?73c8)!&:4EOEg(B" . "144")
	     ("$BIY;38)!&ElIt(B" . "151")
	     ("$BIY;38)!&@>It(B" . "152")
	     ("$B@P@n8)!&2C2lCOJ}(B" . "161")
	     ("$B@P@n8)!&G=EPCOJ}(B" . "162")
	     ("$BJ!0f8)!&NfKL(B" . "171")
	     ("$BJ!0f8)!&NfFn(B" . "172")
	     ("$BFJLZ8)!&FnIt(B" . "181")
	     ("$BFJLZ8)!&KLIt(B" . "182")
	     ("$B72GO8)!&FnIt(B" . "191")
	     ("$B72GO8)!&KLIt(B" . "192")
	     ("$B:k6L8)!&FnIt(B" . "201")
	     ("$B:k6L8)!&KLIt(B" . "202")
	     ("$B:k6L8)!&CaIcCOJ}(B" . "203")
	     ("$B0q>k8)!&KLIt(B" . "211")
	     ("$B0q>k8)!&FnIt(B" . "212")
	     ("$B@iMU8)!&KL@>It(B" . "221")
	     ("$B@iMU8)!&KLElIt(B" . "222")
	     ("$B@iMU8)!&FnIt(B" . "223")
	     ("$BEl5~ET(B" . "231")
	     ("$BEl5~ET!&0KF&=tEgKLIt(B" . "232")
	     ("$BEl5~ET!&0KF&=tEgFnIt(B" . "233")
	     ("$BEl5~ET!&>.3^86(B" . "234")
	     ("$B?@F`@n8)!&ElIt(B" . "261")
	     ("$B?@F`@n8)!&@>It(B" . "262")
	     ("$BD9Ln8)!&KLIt(B" . "271")
	     ("$BD9Ln8)!&CfIt(B" . "272")
	     ("$BD9Ln8)!&FnIt(B" . "273")
	     ("$B;3M|8)!&Cf@>It(B" . "281")
	     ("$B;3M|8)!&ElItIY;N8^8P(B" . "282")
	     ("$B@E2,8)!&CfIt(B" . "291")
	     ("$B@E2,8)!&@>It(B" . "292")
	     ("$B@E2,8)!&ElIt(B" . "293")
	     ("$B@E2,8)!&0KF&COJ}(B" . "294")
	     ("$B4tIl8)!&H~G;COJ}(B" . "301")
	     ("$B4tIl8)!&HtBMCOJ}(B" . "302")
	     ("$B;0=E8)!&KLCfIt(B" . "311")
	     ("$B;0=E8)!&FnIt(B" . "312")
	     ("$B0&CN8)!&@>It(B" . "321")
	     ("$B0&CN8)!&ElIt(B" . "322")
	     ("$B5~ETI\!&FnIt(B" . "331")
	     ("$B5~ETI\!&KLIt(B" . "332")
	     ("$BJ<8K8)!&FnIt(B" . "341")
	     ("$BJ<8K8)!&KLIt(B" . "342")
	     ("$BF`NI8)!&KLIt(B" . "351")
	     ("$BF`NI8)!&FnIt(B" . "352")
	     ("$B<"2l8)!&FnIt(B" . "361")
	     ("$B<"2l8)!&KLIt(B" . "362")
	     ("$BOB2N;38)!&KLIt(B" . "371")
	     ("$BOB2N;38)!&FnIt(B" . "372")
	     ("$BBg:eI\(B" . "381")
	     ("$BD;<h8)!&ElIt(B" . "391")
	     ("$BD;<h8)!&@>It(B" . "392")
	     ("$BEg:,8)!&ElIt(B" . "401")
	     ("$BEg:,8)!&@>It(B" . "402")
	     ("$BEg:,8)!&1#4t=tEg(B" . "403")
	     ("$B2,;38)!&FnIt(B" . "411")
	     ("$B2,;38)!&KLIt(B" . "412")
	     ("$B9-Eg8)!&FnIt(B" . "421")
	     ("$B9-Eg8)!&KLIt(B" . "422")
	     ("$B;38}8)!&@>It(B" . "431")
	     ("$B;38}8)!&CfIt(B" . "432")
	     ("$B;38}8)!&ElIt(B" . "433")
	     ("$B;38}8)!&KLIt(B" . "434")
	     ("$B9a@n8)(B" . "441")
	     ("$B0&I28)!&CfM=COJ}(B" . "451")
	     ("$B0&I28)!&ElM=COJ}(B" . "452")
	     ("$B0&I28)!&FnM=COJ}(B" . "453")
	     ("$BFAEg8)!&KLIt(B" . "461")
	     ("$BFAEg8)!&FnIt(B" . "462")
	     ("$B9bCN8)!&CfIt(B" . "471")
	     ("$B9bCN8)!&ElIt(B" . "472")
	     ("$B9bCN8)!&@>It(B" . "473")
	     ("$BJ!2,8)!&J!2,COJ}(B" . "481")
	     ("$BJ!2,8)!&KL6e=#COJ}(B" . "482")
	     ("$BJ!2,8)!&C^K-COJ}(B" . "483")
	     ("$BJ!2,8)!&C^8eCOJ}(B" . "484")
	     ("$BBgJ,8)!&CfIt(B" . "491")
	     ("$BBgJ,8)!&KLIt(B" . "492")
	     ("$BBgJ,8)!&@>It(B" . "493")
	     ("$BBgJ,8)!&FnIt(B" . "494")
	     ("$B:42l8)!&FnIt(B" . "501")
	     ("$B:42l8)!&KLIt(B" . "502")
	     ("$B7'K\8)!&7'K\COJ}(B" . "511")
	     ("$B7'K\8)!&0$AICOJ}(B" . "512")
	     ("$B7'K\8)!&E7Ap02KLCOJ}(B" . "513")
	     ("$B7'K\8)!&5eKaCOJ}(B" . "514")
	     ("$B5\:j8)!&FnItJ?Ln(B" . "521")
	     ("$B5\:j8)!&FnIt;31h$$(B" . "522")
	     ("$B5\:j8)!&KLItJ?Ln(B" . "523")
	     ("$B5\:j8)!&KLIt;31h$$(B" . "524")
	     ("$BD9:j8)!&FnIt(B" . "531")
	     ("$BD9:j8)!&KLIt(B" . "532")
	     ("$BD9:j8)!&0m4tBPGOCOJ}(B" . "533")
	     ("$BD9:j8)!&8^EgCOJ}(B" . "534")
	     ("$B</;yEg8)!&;'K`COJ}(B" . "561")
	     ("$B</;yEg8)!&Bg6yCOJ}(B" . "562")
	     ("$B</;yEg8)!&<o;REg(B" . "563")
	     ("$B</;yEg8)!&205WEg(B" . "563")
	     ("$B1bH~=tEg(B" . "564")
	     ("$B2-Fl8)!&CfFnIt(B" . "591")
	     ("$B2-Fl8)!&KLIt(B" . "592")
	     ("$B2-Fl8)!&5WJFEg(B" . "593")
	     ("$B2-Fl8)!&BgElEg(B" . "594")
	     ("$B2-Fl8)!&5\8EEg(B" . "595")
	     ("$B2-Fl8)!&@P3@Eg(B" . "596")
	     ("$B2-Fl8)!&M?Fa9qEg(B" . "597"))))
      (mapcar (lambda (area)
		(cons (car area) (format format (cdr area))))
	      alist)))
  "Associative list of regions and urls.")

(defcustom w3m-weather-default-area
  "$B5~ETI\!&FnIt(B"
  "Default region to check weateher."
  :group 'w3m
  :type (cons 'radio
	      (mapcar (lambda (area) (list 'const (car area)))
		      w3m-weather-url-alist)))

(defcustom w3m-weather-filter-functions
  '(w3m-weather-remove-headers
    w3m-weather-remove-footers
    w3m-weather-remove-weather-images
    w3m-weather-remove-washing-images
    w3m-weather-remove-futon-images
    w3m-weather-remove-week-weather-images
    w3m-weather-insert-title)
  "Filter functions to remove useless tags."
  :group 'w3m
  :type 'hook)

;;; Weather:
;;;###autoload
(defun w3m-weather (area)
  "Display weather report."
  (interactive
   (list (if current-prefix-arg
	     (completing-read "Input area: " w3m-weather-url-alist nil t)
	   w3m-weather-default-area)))
  (w3m (format "about://weather/%s" area)))

;;;###autoload
(defun w3m-about-weather (url &rest args)
  (let (area furl)
    (if (and (string-match "^about://weather/" url)
	     (setq area (substring url (match-end 0))
		   furl (cdr (assoc area w3m-weather-url-alist)))
	     (w3m-retrieve furl))
	(w3m-with-work-buffer
	  (w3m-decode-buffer furl)
	  (run-hook-with-args 'w3m-weather-filter-functions area)
	  "text/html")
      (w3m-message "Unknown URL: %s" url)
      nil)))

(defun w3m-weather-remove-headers (&rest args)
  "Remove header of the weather forecast page."
  (goto-char (point-min))
  (when (search-forward "<!-- area_s_title -->" nil t)
    (delete-region (point-min) (point))
    (when (search-forward "<img src=\"/common/clear.gif\"")
      (let ((start))
	(and (search-backward "<tr>" nil t)
	     (setq start (point))
	     (search-forward "</tr>" nil t)
	     (delete-region start (point)))))))

(defun w3m-weather-remove-footers (&rest args)
  "Remove footer of the weather forecast page."
  (goto-char (point-max))
  (when (search-backward "<!-- /area_7days -->" nil t)
    (delete-region (point) (point-max))
    (forward-line -2)
    (when (looking-at "<div")
      (delete-region (point) (point-max)))))

(defun w3m-weather-remove-weather-images (&rest args)
  "Remove images which stand for weather forecasts."
  (let ((case-fold-search t) start end)
    (goto-char (point-min))
    (and (re-search-forward
	  "\\(<td[^>]*>$BE75$(B</td>\\)[ \t\r\f\n]*<td[^>]*><img src=\"/weather/images/"
	  nil t)
	 (setq start (match-beginning 1)
	       end (match-end 1))
	 (search-forward
	  "<tr bgcolor=\"#FFFFFF\">"
	  (prog2 (forward-line 5) (point) (goto-char (match-end 0)))
	  t)
	 (progn
	   (delete-region end (point))
	   (goto-char start)
	   (when (re-search-forward "\\([ \t\r\f\n]rowspan=\"[0-9]+\"\\)[> \t\r\f\n]" end t)
	     (delete-region (match-beginning 1) (match-end 1)))))))

(defun w3m-weather-remove-washing-images (&rest args)
  "Remove images which stand for washing index."
  (let ((case-fold-search t))
    (goto-char (point-min))
    (while (re-search-forward
	    "<td[^>]*>\\(<img src=\"/weather/images/wash[-0-9]*.gif\"[^>]*><br>\\)"
	    nil t)
      (delete-region (match-beginning 1) (match-end 1)))))

(defun w3m-weather-remove-futon-images (&rest args)
  "Remove images which stand for futon index."
  (let ((case-fold-search t))
    (goto-char (point-min))
    (while (re-search-forward
	    "<td[^>]*>\\(<img src=\"/weather/images/bed[-0-9]*.gif\"[^>]*><br>\\)"
	    nil t)
      (delete-region (match-beginning 1) (match-end 1)))))

(defun w3m-weather-remove-week-weather-images (&rest args)
  "Remove images which stand for the weather forecast for the week."
  (let ((case-fold-search t))
    (goto-char (point-min))
    (while (re-search-forward
	    "<td[^>]*>\\(<img src=\"/weather/images/tk[0-9]*.gif\"[^>]*><br>\\)"
	    nil t)
      (delete-region (match-beginning 1) (match-end 1)))))

(defun w3m-weather-insert-title (area &rest args)
  "Insert title."
  (goto-char (point-min))
  (insert "<head><title>Weather forecast of " area "</title></head><body>")
  (goto-char (point-max))
  (insert "</body>"))


(provide 'w3m-weather)
;;; w3m-weather.el ends here.

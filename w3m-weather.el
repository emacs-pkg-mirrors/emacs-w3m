;;; w3m-weather.el --- Add-on program to look weather forecast

;; Copyright (C) 2001 TSUCHIYA Masatoshi <tsuchiya@namazu.org>

;; Authors: TSUCHIYA Masatoshi <tsuchiya@namazu.org>,
;; Keywords: w3m, WWW, hypermedia

;; This file is a part of emacs-w3m.

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

;; w3m-weather.el is the add-on program of emacs-w3m to look weather
;; foracast.  For more detail about emacs-w3m, see:
;;
;;    http://emacs-w3m.namazu.org/


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
	   '(("$BKL3$F;!&CUFb(B" . "1")
	     ("$BKL3$F;!&LVAv(B" . "2")
	     ("$BKL3$F;!&00@n(B" . "3")
	     ("$BKL3$F;!&6|O)(B" . "4")
	     ("$BKL3$F;!&<<Mv(B" . "5")
	     ("$BKL3$F;!&;%KZ(B" . "6")
	     ("$BKL3$F;!&H!4[(B" . "7")
	     ("$B@D?98)(B" . "8")
	     ("$B=)ED8)(B" . "9")
	     ("$B4d<j8)(B" . "10")
	     ("$B;37A8)(B" . "11")
	     ("$B5\>k8)(B" . "12")
	     ("$BJ!Eg8)(B" . "13")
	     ("$B?73c8)(B" . "14")
	     ("$BIY;38)(B" . "15")
	     ("$B@P@n8)(B" . "16")
	     ("$BJ!0f8)(B" . "17")
	     ("$BFJLZ8)(B" . "18")
	     ("$B72GO8)(B" . "19")
	     ("$B:k6L8)(B" . "20")
	     ("$B0q>k8)(B" . "21")
	     ("$B@iMU8)(B" . "22")
	     ("$BEl5~ET(B" . "23")
	     ("$B?@F`@n8)(B" . "26")
	     ("$BD9Ln8)(B" . "27")
	     ("$B;3M|8)(B" . "28")
	     ("$B@E2,8)(B" . "29")
	     ("$B4tIl8)(B" . "30")
	     ("$B;0=E8)(B" . "31")
	     ("$B0&CN8)(B" . "32")
	     ("$B5~ETI\(B" . "33")
	     ("$BJ<8K8)(B" . "34")
	     ("$BF`NI8)(B" . "35")
	     ("$B<"2l8)(B" . "36")
	     ("$BOB2N;38)(B" . "37")
	     ("$BBg:eI\(B" . "38")
	     ("$BD;<h8)(B" . "39")
	     ("$BEg:,8)(B" . "40")
	     ("$B2,;38)(B" . "41")
	     ("$B9-Eg8)(B" . "42")
	     ("$B;38}8)(B" . "43")
	     ("$B9a@n8)(B" . "44")
	     ("$B0&I28)(B" . "45")
	     ("$BFAEg8)(B" . "46")
	     ("$B9bCN8)(B" . "47")
	     ("$BJ!2,8)(B" . "48")
	     ("$BBgJ,8)(B" . "49")
	     ("$B:42l8)(B" . "50")
	     ("$B7'K\8)(B" . "51")
	     ("$B5\:j8)(B" . "52")
	     ("$BD9:j8)(B" . "53")
	     ("$B</;yEg8)(B" . "56")
	     ("$B2-Fl8)(B" . "59"))))
      (mapcar (lambda (area)
		(cons (car area) (format format (cdr area))))
	      alist)))
  "Associative list of regions and urls.")

(defcustom w3m-weather-default-area
  "$B5~ETI\(B"
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
    (while (re-search-forward
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

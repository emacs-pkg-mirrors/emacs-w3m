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
    (let ((format "http://weather.yahoo.co.jp/weather/jp/%s.html")
	  (alist
	   '(("$BF;KL!&=!C+(B" . "1a/1100")
	     ("$BF;KL!&>e@n(B" . "1a/1200")
	     ("$BF;KL!&N1K((B" . "1a/1300")
	     ("$BF;El!&LVAv(B" . "1c/1710")
	     ("$BF;El!&KL8+(B" . "1c/1720")
	     ("$BF;El!&LfJL(B" . "1c/1730")
	     ("$BF;El!&:,<<(B" . "1c/1800")
	     ("$BF;El!&6|O)(B" . "1c/1900")
	     ("$BF;El!&==>!(B" . "1c/2000")
	     ("$BF;1{!&@P<m(B" . "1b/1400")
	     ("$BF;1{!&6uCN(B" . "1b/1500")
	     ("$BF;1{!&8e;V(B" . "1b/1600")
	     ("$BF;Fn!&I0;3(B" . "1d/2400")
	     ("$BF;Fn!&C@?6(B" . "1d/2100")
	     ("$BF;Fn!&F|9b(B" . "1d/2200")
	     ("$BF;Fn!&EOEg(B" . "1d/2300")
	     ("$B@D?98)!&DE7Z(B" . "2/3110")
	     ("$B@D?98)!&2<KL(B" . "2/3120")
	     ("$B@D?98)!&;0H,>eKL(B" . "2/3130")
	     ("$B4d<j8)!&FbN&It(B" . "3/3310")
	     ("$B4d<j8)!&1h4_KLIt(B" . "3/3320")
	     ("$B4d<j8)!&1h4_FnIt(B" . "3/3330")
	     ("$B=)ED8)!&1h4_It(B" . "5/3210")
	     ("$B=)ED8)!&FbN&It(B" . "5/3220")
	     ("$B5\>k8)!&J?LnIt(B" . "4/3410")
	     ("$B5\>k8)!&;31h$$(B" . "4/3420")
	     ("$B;37A8)!&B<;3(B" . "6/3510")
	     ("$B;37A8)!&CV;r(B" . "6/3520")
	     ("$B;37A8)!&>1Fb(B" . "6/3530")
	     ("$B;37A8)!&:G>e(B" . "6/3540")
	     ("$BJ!Eg8)!&CfDL$j(B" . "7/3610")
	     ("$BJ!Eg8)!&IMDL$j(B" . "7/3620")
	     ("$BJ!Eg8)!&2qDE(B" . "7/3630")
	     ("$B0q>k8)!&KLIt(B" . "8/4010")
	     ("$B0q>k8)!&FnIt(B" . "8/4020")
	     ("$BFJLZ8)!&FnIt(B" . "9/4110")
	     ("$BFJLZ8)!&KLIt(B" . "9/4120")
	     ("$B72GO8)!&FnIt(B" . "10/4210")
	     ("$B72GO8)!&KLIt(B" . "10/4220")
	     ("$B:k6L8)!&FnIt(B" . "11/4310")
	     ("$B:k6L8)!&KLIt(B" . "11/4320")
	     ("$B:k6L8)!&CaIc(B" . "11/4330")
	     ("$B@iMU8)!&KL@>It(B" . "12/4510")
	     ("$B@iMU8)!&KLElIt(B" . "12/4520")
	     ("$B@iMU8)!&FnIt(B" . "12/4530")
	     ("$BEl5~ET!&IcEg(B" . "13/9900")
	     ("$BEl5~ET!&El5~(B" . "13/4400")
	     ("$BEl5~ET!&0KF&=tEgKLIt(B" . "13/0")
	     ("$BEl5~ET!&0KF&=tEgFnIt(B" . "13/100")
	     ("$B?@F`@n8)!&ElIt(B" . "14/4610")
	     ("$B?@F`@n8)!&@>It(B" . "14/4620")
	     ("$B?73c8)!&2<1[(B" . "15/5410")
	     ("$B?73c8)!&Cf1[(B" . "15/5420")
	     ("$B?73c8)!&>e1[(B" . "15/5430")
	     ("$B?73c8)!&:4EO(B" . "15/5440")
	     ("$BIY;38)!&ElIt(B" . "16/5510")
	     ("$BIY;38)!&@>It(B" . "16/5520")
	     ("$B@P@n8)!&2C2l(B" . "17/5610")
	     ("$B@P@n8)!&G=EP(B" . "17/5620")
	     ("$BJ!0f8)!&NfKL(B" . "18/5710")
	     ("$BJ!0f8)!&NfFn(B" . "18/5720")
	     ("$B;3M|8)!&Cf@>It(B" . "19/4910")
	     ("$B;3M|8)!&IY;N8^8P(B" . "19/4920")
	     ("$BD9Ln8)!&KLIt(B" . "20/4810")
	     ("$BD9Ln8)!&CfIt(B" . "20/4820")
	     ("$BD9Ln8)!&FnIt(B" . "20/4830")
	     ("$B4tIl8)!&H~G;(B" . "21/5210")
	     ("$B4tIl8)!&HtBM(B" . "21/5220")
	     ("$B@E2,8)!&CfIt(B" . "22/5010")
	     ("$B@E2,8)!&0KF&(B" . "22/5020")
	     ("$B@E2,8)!&ElIt(B" . "22/5030")
	     ("$B@E2,8)!&@>It(B" . "22/5040")
	     ("$B0&CN8)!&@>It(B" . "23/5110")
	     ("$B0&CN8)!&ElIt(B" . "23/5120")
	     ("$B;0=E8)!&KLCfIt(B" . "24/5310")
	     ("$B;0=E8)!&FnIt(B" . "24/5320")
	     ("$B<"2l8)!&FnIt(B" . "25/6010")
	     ("$B<"2l8)!&KLIt(B" . "25/6020")
	     ("$B5~ETI\!&KLIt(B" . "26/400")
	     ("$B5~ETI\!&FnIt(B" . "26/6100")
	     ("$BBg:eI\(B" . "27/6200")
	     ("$BJ<8K8)!&KLIt(B" . "28/500")
	     ("$BJ<8K8)!&FnIt(B" . "28/6300")
	     ("$BF`NI8)!&KLIt(B" . "29/6410")
	     ("$BF`NI8)!&FnIt(B" . "29/6420")
	     ("$BOB2N;38)!&KLIt(B" . "30/6510")
	     ("$BOB2N;38)!&FnIt(B" . "30/6520")
	     ("$BD;<h8)!&ElIt(B" . "31/6910")
	     ("$BD;<h8)!&@>It(B" . "31/6920")
	     ("$BEg:,8)!&1#4t(B" . "32/600")
	     ("$BEg:,8)!&ElIt(B" . "32/6810")
	     ("$BEg:,8)!&@>It(B" . "32/6820")
	     ("$B2,;38)!&FnIt(B" . "33/6610")
	     ("$B2,;38)!&KLIt(B" . "33/6620")
	     ("$B9-Eg8)!&FnIt(B" . "34/6710")
	     ("$B9-Eg8)!&KLIt(B" . "34/6720")
	     ("$B;38}8)!&@>It(B" . "35/8110")
	     ("$B;38}8)!&CfIt(B" . "35/8120")
	     ("$B;38}8)!&KLIt(B" . "35/8140")
	     ("$B;38}8)!&ElIt(B" . "35/8130")
	     ("$BFAEg8)!&KLIt(B" . "36/7110")
	     ("$BFAEg8)!&FnIt(B" . "36/7120")
	     ("$B9a@n8)(B" . "37/7200")
	     ("$B0&I28)!&ElM=(B" . "38/7320")
	     ("$B0&I28)!&FnM=(B" . "38/7330")
	     ("$B0&I28)!&CfM=(B" . "38/7310")
	     ("$B9bCN8)!&CfIt(B" . "39/7410")
	     ("$B9bCN8)!&ElIt(B" . "39/7420")
	     ("$B9bCN8)!&@>It(B" . "39/7430")
	     ("$BJ!2,8)!&J!2,(B" . "40/8210")
	     ("$BJ!2,8)!&KL6e=#(B" . "40/8220")
	     ("$BJ!2,8)!&C^K-(B" . "40/8230")
	     ("$BJ!2,8)!&C^8e(B" . "40/8240")
	     ("$B:42l8)!&FnIt(B" . "41/8510")
	     ("$B:42l8)!&KLIt(B" . "41/8520")
	     ("$BD9:j8)!&0m4tBPGO(B" . "42/700")
	     ("$BD9:j8)!&8^Eg(B" . "42/800")
	     ("$BD9:j8)!&FnIt(B" . "42/8410")
	     ("$BD9:j8)!&KLIt(B" . "42/8420")
	     ("$B7'K\8)!&7'K\(B" . "43/8610")
	     ("$B7'K\8)!&0$AI(B" . "43/8620")
	     ("$B7'K\8)!&E7Ap02KL(B" . "43/8630")
	     ("$B7'K\8)!&5eKa(B" . "43/8640")
	     ("$BBgJ,8)!&CfIt(B" . "44/8310")
	     ("$BBgJ,8)!&KLIt(B" . "44/8320")
	     ("$BBgJ,8)!&@>It(B" . "44/8330")
	     ("$BBgJ,8)!&FnIt(B" . "44/8340")
	     ("$B5\:j8)!&FnItJ?LnIt(B" . "45/8710")
	     ("$B5\:j8)!&KLItJ?LnIt(B"$B!&(B.$B!&!&(B"45/8720")
	     ("$B5\:j8)!&FnIt;31h$$(B" . "45/8730")
	     ("$B5\:j8)!&KLIt;31h$$(B" . "45/8740")
	     ("$B</;yEg8)!&;'K`(B" . "46/8810")
	     ("$B</;yEg8)!&Bg6y(B" . "46/8820")
	     ("$B</;yEg8)!&<o;REg!&205WEg(B" . "46/900")
	     ("$B</;yEg8)!&1bH~(B" . "46/1000")
	     ("$B2-Fl8)!&K\EgCfFnIt(B" . "47/9110")
	     ("$B2-Fl8)!&K\EgKLIt(B" . "47/9120")
	     ("$B2-Fl8)!&5WJFEg(B" . "47/9130")
	     ("$B2-Fl8)!&BgElEg(B" . "47/9200")
	     ("$B2-Fl8)!&5\8EEg(B" . "47/9300")
	     ("$B2-Fl8)!&@P3@Eg(B" . "47/9400")
	     ("$B2-Fl8)!&M?Fa9qEg(B" . "47/9500"))))
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
(defun w3m-about-weather (url no-decode no-cache &rest args)
  (let (area furl)
    (if (and (string-match "^about://weather/" url)
	     (setq area (substring url (match-end 0))
		   furl (cdr (assoc area w3m-weather-url-alist)))
	     (w3m-retrieve furl nil no-cache))
	(w3m-with-work-buffer
	  (w3m-decode-buffer furl)
	  (run-hook-with-args 'w3m-weather-filter-functions area furl)
	  "text/html")
      (w3m-message "Unknown URL: %s" url)
      nil)))

(defun w3m-weather-remove-headers (&rest args)
  "Remove header of the weather forecast page."
  (goto-char (point-min))
  (when (search-forward "\
<TABLE border=\"0\" CELLSPACING=\"1\" CELLPADDING=\"0\" width=\"100%\">
<tr><td>

<table border=\"0\" CELLSPACING=\"0\" CELLPADDING=\"0\" width=\"100%\">
<tr><td bgcolor=\"#dcdcdc\"><b>$B:#F|!&L@F|$NE75$(B</b></td>" nil t)
    (delete-region (point-min) (match-beginning 0))))

(defun w3m-weather-remove-footers (&rest args)
  "Remove footer of the weather forecast page."
  (goto-char (point-max))
  (when (search-backward "\
<table border=0 cellpadding=2 cellspacing=5 width=\"100%\">
<tr bgcolor=\"#dcdcdc\">
<td colspan=3><b>$B%l%8%c!<E75$(B</b></td></tr>" nil t)
    (delete-region (point) (point-max))))

(defun w3m-weather-insert-title (area url &rest args)
  "Insert title."
  (goto-char (point-min))
  (insert "<head><title>Weather forecast of "
	  area
	  "</title></head>\n"
	  "<body><p align=left><a href=\""
	  url
	  "\">[Yahoo!]</a></p>\n")
  (goto-char (point-max))
  (insert "</body>"))


(provide 'w3m-weather)
;;; w3m-weather.el ends here.

;;; -*- mode: Emacs-Lisp; coding: euc-japan -*-

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

;; w3m-weather.el is the add-on program to look weather foracast of
;; w3m.el.  For more detail about w3m.el, see:
;;
;;    http://namazu.org/~tsuchiya/emacs-w3m/


;;; How to install:

;; Please put this file to appropriate directory, and if you want
;; byte-compile it.  And add following lisp expressions to your
;; ~/.emacs.
;;
;;     (autoload 'w3m-weather "w3m-weather" "*Display weather report." t)


;;; Code:

(require 'w3m)

(defconst w3m-weather-url-alist
  (eval-when-compile
    (let ((format "http://channel.goo.ne.jp/weather/area/%s.html")
	  (alist
	   '(("�̳�ƻ����ë����" . "011")
	     ("�̳�ƻ����������" . "021")
	     ("�̳�ƻ���̸�����" . "022")
	     ("�̳�ƻ����������" . "023")
	     ("�̳�ƻ����������" . "031")
	     ("�̳�ƻ��α˨����" . "032")
	     ("�̳�ƻ����ϩ����" . "041")
	     ("�̳�ƻ����������" . "042")
	     ("�̳�ƻ����������" . "043")
	     ("�̳�ƻ����������" . "051")
	     ("�̳�ƻ����������" . "052")
	     ("�̳�ƻ���м�����" . "061")
	     ("�̳�ƻ����������" . "062")
	     ("�̳�ƻ���������" . "063")
	     ("�̳�ƻ����������" . "071")
	     ("�̳�ƻ���ػ�����" . "072")
	     ("�Ŀ������ŷ�����" . "081")
	     ("�Ŀ�������������" . "082")
	     ("�Ŀ�������Ȭ��������" . "083")
	     ("���ĸ��������" . "091")
	     ("���ĸ�����Φ��" . "092")
	     ("��긩����Φ��" . "101")
	     ("��긩���������" . "102")
	     ("��긩���������" . "103")
	     ("��������¼������" . "111")
	     ("���������ֻ�����" . "112")
	     ("����������������" . "113")
	     ("���������Ǿ�����" . "114")
	     ("�ܾ븩��ʿ����" . "121")
	     ("�ܾ븩�����褤" . "122")
	     ("ʡ�縩�����̤�" . "131")
	     ("ʡ�縩�����̤�" . "132")
	     ("ʡ�縩����������" . "133")
	     ("���㸩����������" . "141")
	     ("���㸩���������" . "142")
	     ("���㸩���������" . "143")
	     ("���㸩��������" . "144")
	     ("�ٻ���������" . "151")
	     ("�ٻ���������" . "152")
	     ("������ò�����" . "161")
	     ("�����ǽ������" . "162")
	     ("ʡ�温������" . "171")
	     ("ʡ�温������" . "172")
	     ("���ڸ�������" . "181")
	     ("���ڸ�������" . "182")
	     ("���ϸ�������" . "191")
	     ("���ϸ�������" . "192")
	     ("��̸�������" . "201")
	     ("��̸�������" . "202")
	     ("��̸�����������" . "203")
	     ("��븩������" . "211")
	     ("��븩������" . "212")
	     ("���ո���������" . "221")
	     ("���ո���������" . "222")
	     ("���ո�������" . "223")
	     ("�����" . "231")
	     ("����ԡ���Ʀ��������" . "232")
	     ("����ԡ���Ʀ��������" . "233")
	     ("����ԡ����޸�" . "234")
	     ("�����������" . "261")
	     ("�����������" . "262")
	     ("Ĺ�������" . "271")
	     ("Ĺ�������" . "272")
	     ("Ĺ�������" . "273")
	     ("��������������" . "281")
	     ("�������������ٻθ޸�" . "282")
	     ("�Ų���������" . "291")
	     ("�Ų���������" . "292")
	     ("�Ų���������" . "293")
	     ("�Ų�������Ʀ����" . "294")
	     ("���츩����ǻ����" . "301")
	     ("���츩����������" . "302")
	     ("���Ÿ���������" . "311")
	     ("���Ÿ�������" . "312")
	     ("���θ�������" . "321")
	     ("���θ�������" . "322")
	     ("�����ܡ�����" . "331")
	     ("�����ܡ�����" . "332")
	     ("ʼ�˸�������" . "341")
	     ("ʼ�˸�������" . "342")
	     ("���ɸ�������" . "351")
	     ("���ɸ�������" . "352")
	     ("���츩������" . "361")
	     ("���츩������" . "362")
	     ("�²λ���������" . "371")
	     ("�²λ���������" . "372")
	     ("�����" . "381")
	     ("Ļ�踩������" . "391")
	     ("Ļ�踩������" . "392")
	     ("�纬��������" . "401")
	     ("�纬��������" . "402")
	     ("�纬������������" . "403")
	     ("������������" . "411")
	     ("������������" . "412")
	     ("���縩������" . "421")
	     ("���縩������" . "422")
	     ("������������" . "431")
	     ("������������" . "432")
	     ("������������" . "433")
	     ("������������" . "434")
	     ("���" . "441")
	     ("��ɲ������ͽ����" . "451")
	     ("��ɲ������ͽ����" . "452")
	     ("��ɲ������ͽ����" . "453")
	     ("���縩������" . "461")
	     ("���縩������" . "462")
	     ("���θ�������" . "471")
	     ("���θ�������" . "472")
	     ("���θ�������" . "473")
	     ("ʡ������ʡ������" . "481")
	     ("ʡ�������̶彣����" . "482")
	     ("ʡ��������˭����" . "483")
	     ("ʡ�������޸�����" . "484")
	     ("��ʬ��������" . "491")
	     ("��ʬ��������" . "492")
	     ("��ʬ��������" . "493")
	     ("��ʬ��������" . "494")
	     ("���츩������" . "501")
	     ("���츩������" . "502")
	     ("���ܸ�����������" . "511")
	     ("���ܸ�����������" . "512")
	     ("���ܸ���ŷ��������" . "513")
	     ("���ܸ�����������" . "514")
	     ("�ܺ긩������ʿ��" . "521")
	     ("�ܺ긩���������褤" . "522")
	     ("�ܺ긩������ʿ��" . "523")
	     ("�ܺ긩���������褤" . "524")
	     ("Ĺ�긩������" . "531")
	     ("Ĺ�긩������" . "532")
	     ("Ĺ�긩�������������" . "533")
	     ("Ĺ�긩����������" . "534")
	     ("�����縩����������" . "561")
	     ("�����縩���������" . "562")
	     ("�����縩�������" . "563")
	     ("�����縩��������" . "563")
	     ("��������" . "564")
	     ("���츩��������" . "591")
	     ("���츩������" . "592")
	     ("���츩��������" . "593")
	     ("���츩��������" . "594")
	     ("���츩���ܸ���" . "595")
	     ("���츩���г���" . "596")
	     ("���츩��Ϳ�����" . "597"))))
      (mapcar (lambda (area)
		(cons (car area) (format format (cdr area))))
	      alist)))
  "Associative list of regions and urls.")

(defcustom w3m-weather-default-area
  "�����ܡ�����"
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
(defun w3m-weather (area)
  "*Display weather report."
  (interactive
   (list (if current-prefix-arg
	     (completing-read "Input area: " w3m-weather-url-alist nil t)
	   w3m-weather-default-area)))
  (w3m (format "about://weather/%s" area)))

(defun w3m-about-weather (url &rest args)
  (let (area furl)
    (if (and (string-match "^about://weather/" url)
	     (setq area (substring url (match-end 0))
		   furl (cdr (assoc area w3m-weather-url-alist)))
	     (w3m-retrieve furl))
	(w3m-with-work-buffer
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
	  "\\(<td[^>]*>ŷ��</td>\\)[ \t\r\f\n]*<td[^>]*><img src=\"/weather/images/"
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

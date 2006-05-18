;;; w3m-tabmenu.el --- Functions for TAB menu browsing

;; Copyright (C) 2001, 2002, 2003, 2004, 2005
;; TSUCHIYA Masatoshi <tsuchiya@namazu.org>

;; Authors: Hideyuki SHIRAI    <shirai@meadowy.org>,
;;          TSUCHIYA Masatoshi <tsuchiya@namazu.org>
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
;; Inc.; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;; This file contains the functions for TAB browsing.  For more detail
;; about emacs-w3m, see:
;;
;;    http://emacs-w3m.namazu.org/

;;; Code:

(eval-when-compile
  (require 'cl))

(require 'w3m-util)
(require 'w3m)
(require 'easymenu)

(defun w3m-setup-tab-menu ()
  "Setup w3m tab menubar."
  (when w3m-use-tab-menubar
    (w3m-static-if (featurep 'xemacs)
	(unless (car (find-menu-item current-menubar '("Tab")))
	  (easy-menu-define w3m-tab-menu w3m-mode-map
	    "" '("Tab" ["dummy" w3m-switch-buffer t]))
	  (easy-menu-add w3m-tab-menu)
	  (setq current-menubar
		(cons w3m-tab-menu
		      (delq (assoc "Tab" current-menubar) current-menubar)))
	  (add-hook 'activate-menubar-hook 'w3m-tab-menubar-update))
      (unless (lookup-key w3m-mode-map [menu-bar Tab])
	(easy-menu-define w3m-tab-menu w3m-mode-map "" '("Tab"))
	(easy-menu-add w3m-tab-menu)
	(add-hook 'menu-bar-update-hook 'w3m-tab-menubar-update)))))

(defun w3m-switch-buffer ()
  "Switch `w3m-mode' buffer in the current window."
  (interactive)
  (let ((items (w3m-tab-menubar-make-items 'nomenu))
	(minibuffer-setup-hook
	 (append minibuffer-setup-hook '(beginning-of-line)))
	(count 1)
	(form "%s [%s]")
	(completion-ignore-case t)
	comp hist histlen default buf)
    (dolist (item items)
      (when (nth 2 item)	;; current-buffer
	(setq default count))
      (setq comp (cons
		  (cons
		   (format form (nth 1 item) (nth 0 item)) (nth 0 item))
		  comp))
      (setq hist (cons (format form (nth 1 item) (nth 0 item)) hist))
      (setq count (1+ count)))
    (setq comp (nreverse comp))
    (setq histlen (length hist))
    (setq hist (append hist hist hist hist hist)) ;; STARTPOS at 3rd hist
    (setq buf
	  (completing-read
	   "Switch to w3m buffer: "
	   comp nil t (car (nth (1- default) comp))
	   (cons 'hist (+ (* 3 histlen) (- histlen default -1)))
	   (car (nth (1- default) comp))))
    (setq buf (cdr (assoc buf comp)))
    (when (get-buffer buf)
      (switch-to-buffer buf))))

(defun w3m-tab-menubar-open-item (buf)
  "Open w3m buffer from tab menubar."
  (interactive)
  (when (get-buffer buf)
    (switch-to-buffer buf)))

(defun w3m-tab-menubar-update ()
  "Update w3m tab menubar."
  (when (and (eq major-mode 'w3m-mode)
	     (w3m-static-if (featurep 'xemacs)
		 (frame-property (selected-frame) 'menubar-visible-p)
	       menu-bar-mode))
    (easy-menu-define w3m-tab-menu w3m-mode-map
      "The menu kepmap for the emacs-w3m tab."
      (cons "Tab" (w3m-tab-menubar-make-items)))
    (w3m-static-when (featurep 'xemacs)
      (let ((items (car (find-menu-item current-menubar '("Tab")))))
	(when items
	  (setcdr items (cdr w3m-tab-menu))
	  (set-buffer-menubar current-menubar))))))

(defun w3m-tab-menubar-make-items (&optional nomenu)
  "Create w3m tab menu items."
  (let* ((i 0) (current (current-buffer))
	 (menu (mapcar
		(lambda (buffer)
		  (if nomenu
		      (list (buffer-name buffer)
			    (w3m-buffer-title buffer)
			    (eq buffer current))
		    (vector (format "%d: %s%s"
				    (incf i)
				    (if (eq buffer current) "* " "  ")
				    (w3m-buffer-title buffer))
			    `(w3m-tab-menubar-open-item ,(buffer-name buffer))
			    buffer)))
		(w3m-list-buffers))))
    (if nomenu
	menu
      (setq w3m-tab-button-menu-current-buffer (current-buffer))
      (append menu
	      '("-")
	      '("-")
	      (w3m-make-menu-commands w3m-tab-button-menu-commands)))))

(provide 'w3m-tabmenu)

;;; w3m-tabmenu.el ends here

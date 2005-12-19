;;; w3m-fb.el --- frame-local buffers support for Emacs-w3m

;;; Copyright (C) 2005 Matthew P. Hodges

;; Author: Matthew P. Hodges <MPHodges@member.fsf.org>
;; Version: $Id: w3m-fb.el,v 1.1 2005-12-19 04:28:27 yamaoka Exp $

;; w3m-fb.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 2, or (at your
;; option) any later version.

;; w3m-fb.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;;; Commentary:
;; 
;; With this mode switched on, W3M buffers are associated with the
;; frame on which they were created.  Only tabs for the current
;; frame's W3M buffers are shown (with non-nil w3m-use-tab); other
;; affected commands are w3m-next-buffer w3m-previous-buffer,
;; w3m-select-buffer and w3m-quit.
;;
;; Switch the mode on programmatically with:
;;
;;     (w3m-fb-mode 1)
;;
;; or toggle interactively with M-x w3m-fb-mode RET.

;;; Code:

(require 'w3m)

(defconst w3m-fb-version "1.0.0"
  "Version number of this package.")

(eval-when-compile
  (defalias 'w3m-fb-frame-parameter
    (cond
     ((fboundp 'frame-parameter)
      'frame-parameter)
     ((fboundp 'frame-property)
      'frame-property)
     (t
      (error "No frame parameter/property function"))))

  (defvar w3m-fb-delete-frame-functions
    (cond
     ((boundp 'delete-frame-functions)
      'delete-frame-functions)
     ((boundp 'delete-frame-hook)
      'delete-frame-hook)
     (t
      (error "No delete-frame hook/functions variable found")))
    "Symbol associated with `delete-frame' hooks."))

(defvar w3m-fb-list-buffers-frame nil
  "Frame to list buffers for in `w3m-list-buffers'.
Bind this if the buffers associated with a frame other than the
selected frame are required.")

;; Customizable variables

(defgroup w3m-fb nil
  "Frame local buffers for Emacs-w3m."
  :group 'w3m)

(defcustom w3m-fb-delete-frame-kill-buffers t
  "If non-nil, kill W3M buffers after deleting frames."
  :group 'w3m-fb
  :type 'boolean
  :set (lambda (sym val)
         (set sym val)
         (when (boundp 'w3m-fb-mode)
           (if w3m-fb-mode
               (add-hook w3m-fb-delete-frame-functions 'w3m-fb-delete-frame-buffers)
             (remove-hook w3m-fb-delete-frame-functions 'w3m-fb-delete-frame-buffers)))))

;; Internal variables

(defvar w3m-fb-buffer-list nil
  "List of w3m buffers associated with the selected frame.")

(defvar w3m-fb-inhibit-buffer-selection nil
  "Non-nil to inhibit selecting a suitable w3m buffer.")

;; Internal functions

(defun w3m-fb-delete-frame-buffers (&optional frame)
  "Delete W3M buffers associated with frame FRAME."
  (let* ((w3m-fb-list-buffers-frame frame)
         (buffers (w3m-list-buffers))
         ;; Now bind w3m-fb-mode to nil so that w3m-delete-buffer
         ;; doesn't call w3m-quit when there are w3m buffers belonging
         ;; to other frames.
         (w3m-fb-mode nil)
         (w3m-fb-inhibit-buffer-selection t))
    (save-window-excursion
      (dolist (b buffers)
	(with-current-buffer b
	  (w3m-delete-buffer))))))

;; Could use set-frame-parameter here, but it isn't portable
(defun w3m-fb-set-frame-parameter (frame parameter value)
  "Set for frame FRAME parameter PARAMETER to VALUE."
  (modify-frame-parameters frame (list (cons parameter value))))

(defun w3m-fb-add ()
  "Add current buffer to `w3m-fb-buffer-list'."
  (let ((val (w3m-fb-frame-parameter nil 'w3m-fb-buffer-list)))
    (w3m-fb-set-frame-parameter
     nil 'w3m-fb-buffer-list (nconc val (list (current-buffer))))))

(defun w3m-fb-remove ()
  "Remove current buffer from `w3m-fb-buffer-list'.
Applies to all frames."
  (when (eq major-mode 'w3m-mode)
    (let (val)
      (dolist (f (frame-list))
        (setq val (w3m-fb-frame-parameter f 'w3m-fb-buffer-list))
        (w3m-fb-set-frame-parameter
         f 'w3m-fb-buffer-list (delq (current-buffer) val))))))

(defun w3m-fb-associate ()
  "Associate all `w3m-mode' buffers with a frame."
  (let (buffers done rest)
    ;; Buffers displayed in windows
    (dolist (f (frame-list))
      (setq buffers nil)
      (dolist (w (window-list f nil (frame-selected-window f)))
        (when (with-current-buffer (window-buffer w)
                (eq major-mode 'w3m-mode))
          (setq buffers (nconc buffers (list (window-buffer w))))
          (setq done (nconc done (list (window-buffer w))))))
      (w3m-fb-set-frame-parameter
       f 'w3m-fb-buffer-list buffers))
    ;; Buffers not displayed in windows; add to selected frame
    (let ((w3m-fb-mode nil))
      (setq rest (w3m-list-buffers)))
    (dolist (b done)
      (setq rest (delq b rest)))
    (when rest
      (w3m-fb-set-frame-parameter
       nil 'w3m-fb-buffer-list
       (nconc (w3m-fb-frame-parameter nil 'w3m-fb-buffer-list) rest)))))

(defun w3m-fb-dissociate ()
  "Disassociate `w3m-mode' buffers from frames."
  (dolist (f (frame-list))
    (w3m-fb-set-frame-parameter f 'w3m-fb-buffer-list nil)))

(defun w3m-fb-select-buffer ()
  "Select an appropriate W3M buffer to display."
  ;; If there are w3m buffers belonging to this frame, ensure one is
  ;; selected; if not make sure that we're not displaying a w3m
  ;; buffer
  (cond
   ;; Select w3m buffer belonging to frame, if one is available
   ((w3m-list-buffers)
    (unless (memq (current-buffer) (w3m-list-buffers))
      (w3m-next-buffer -1)))
   ;; If no w3m buffers belong to frame, don't display any w3m buffer
   ((while (eq major-mode 'w3m-mode)
;;       (assert (eq (current-buffer)
;;                   (window-buffer (selected-window))))
      (bury-buffer)))))

;; Advised functions

(defvar w3m-fb-advised-functions nil
  "List of functions advised by W3M Frame Buffer Mode.")

(defadvice w3m-list-buffers (after w3m-fb)
  "Return only w3m buffers associated with the selected frame."
  (when w3m-fb-mode
    ;; Don't just return w3m-fb-buffer-list for the selected frame
    ;; because w3m-list-buffers may have sorted the list
    (dolist (b ad-return-value)
      (unless (memq b (w3m-fb-frame-parameter w3m-fb-list-buffers-frame
                                              'w3m-fb-buffer-list))
        (setq ad-return-value (delq b ad-return-value))))))

(add-to-list 'w3m-fb-advised-functions '(w3m-list-buffers after))

(defadvice w3m-close-window (after w3m-fb)
  "Safely close window on selected frame."
  ;; The current-buffer and displayed buffer are not necessarily the
  ;; same at this point; if they aren't bury-buffer will be a nop, and
  ;; we will infloop
  (set-buffer (window-buffer (selected-window)))
  (while (eq major-mode 'w3m-mode)
    (bury-buffer)))

(add-to-list 'w3m-fb-advised-functions '(w3m-close-window after))

(defadvice w3m-delete-buffer (around w3m-fb)
  "Safely delete buffer on selected frame."
  ;; Bind w3m-fb-mode to nil so that w3m-delete-buffer
  ;; doesn't call w3m-quit when there is only one buffer belonging to
  ;; the selected frame, but there are w3m buffers in other frames
  (let ((w3m-fb-mode nil))
    ad-do-it)
  (unless w3m-fb-inhibit-buffer-selection
    (w3m-fb-select-buffer)))

(add-to-list 'w3m-fb-advised-functions '(w3m-delete-buffer around))

(defadvice w3m-quit (around w3m-fb)
  "Optionally quit W3M buffers on other frames."
  (let ((buffers (w3m-list-buffers))
        (all-buffers
         (let ((w3m-fb-mode nil))
           (w3m-list-buffers))))
    (cond
     ((or (= (length buffers) (length all-buffers))
          (y-or-n-p "Kill W3M buffers on other frames? "))
      (let ((w3m-fb-mode nil))
        ad-do-it))
     (t
      (w3m-fb-delete-frame-buffers)
      (w3m-fb-select-buffer)))))

(add-to-list 'w3m-fb-advised-functions '(w3m-quit around))

;; Minor mode setup

;;;###autoload
(define-minor-mode w3m-fb-mode
  "Toggle W3M Frame Buffer mode.
This allows frame-local lists of buffers (tabs)."
  :init-value nil
  :group 'w3m-fb
  :global t
  (if w3m-fb-mode
      (if w3m-pop-up-frames
          (progn
            (message "W3M Frame Buffer mode not activated (non-nil w3m-pop-up-frames)")
            (sit-for 2))
        (add-hook 'w3m-mode-hook 'w3m-fb-add)
        (add-hook 'kill-buffer-hook 'w3m-fb-remove)
        (when w3m-fb-delete-frame-kill-buffers
          (add-hook w3m-fb-delete-frame-functions 'w3m-fb-delete-frame-buffers))
        (w3m-fb-associate)
        (dolist (f w3m-fb-advised-functions)
          (ad-enable-advice (car f) (cadr f) 'w3m-fb)
          (ad-activate (car f))))
    (remove-hook 'w3m-mode-hook 'w3m-fb-add)
    (remove-hook 'kill-buffer-hook 'w3m-fb-remove)
    (remove-hook w3m-fb-delete-frame-functions 'w3m-fb-delete-frame-buffers)
    (w3m-fb-dissociate)
    (dolist (f w3m-fb-advised-functions)
      (ad-disable-advice (car f) (cadr f) 'w3m-fb)
      (ad-activate (car f)))))

(provide 'w3m-fb)

;;; w3m-fb.el ends here

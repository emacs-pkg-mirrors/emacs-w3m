;;; w3m-e21.el --- The stuffs to use emacs-w3m on Emacs-21

;; Copyright (C) 2001, 2002, 2003 TSUCHIYA Masatoshi <tsuchiya@namazu.org>

;; Authors: Yuuichi Teranishi  <teranisi@gohome.org>,
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
;; Inc.; 59 Temple Place, Suite 330; Boston, MA 02111-1307, USA.


;;; Commentary:

;; This file contains the stuffs to use emacs-w3m on Emacs-21.  For
;; more detail about emacs-w3m, see:
;;
;;    http://emacs-w3m.namazu.org/


;;; Code:

(eval-when-compile
  (require 'cl))

(require 'w3m-util)
(require 'w3m-proc)
(require 'w3m-image)
(require 'w3m-favicon)
(require 'w3m-fsf)
(require 'w3m-ccl)
(require 'wid-edit)

;; Functions and variables which should be defined in the other module
;; at run-time.
(eval-when-compile
  (defvar w3m-current-url)
  (defvar w3m-current-title)
  (defvar w3m-current-process)
  (defvar w3m-current-buffer)
  (defvar w3m-display-inline-images)
  (defvar w3m-icon-directory)
  (defvar w3m-mode-map)
  (defvar w3m-profile-directory)
  (defvar w3m-toolbar)
  (defvar w3m-toolbar-buttons)
  (defvar w3m-use-tab)
  (defvar w3m-use-header-line)
  (defvar w3m-work-buffer-name)
  (defvar w3m-history)
  (defvar w3m-history-flat)
  (defvar w3m-form-use-fancy-faces)
  (defvar w3m-async-exec)
  (defvar w3m-use-favicon)
  (autoload 'w3m-expand-url "w3m")
  (autoload 'w3m-retrieve "w3m")
  (autoload 'w3m-image-type "w3m")
  (autoload 'w3m-load-list "w3m")
  (autoload 'w3m-save-list "w3m"))

;;; Coding system.

(defun w3m-make-ccl-coding-system
  (coding-system mnemonic docstring decoder encoder)
  "Define a new CODING-SYSTEM by CCL programs DECODER and ENCODER.
CODING-SYSTEM, DECODER and ENCODER must be symbol."
  (make-coding-system coding-system 4 mnemonic docstring
		      (cons decoder encoder)))

(eval-and-compile
  (defconst w3m-ccl-get-ucs-codepoint-with-emacs-unicode
    `((if (r1 == ,(charset-id 'latin-iso8859-1))
	  ((r1 = (r0 + 128)))
	(if (r1 == ,(charset-id 'mule-unicode-0100-24ff))
	    ((r1 = ((((r0 & #x3f80) >> 7) - 32) * 96))
	     (r0 &= #x7f)
	     (r1 += (r0 + 224)))	; 224 == -32 + #x0100
	  (if (r1 == ,(charset-id 'mule-unicode-2500-33ff))
	      ((r1 = ((((r0 & #x3f80) >> 7) - 32) * 96))
	       (r0 &= #x7f)
	       (r1 += (r0 + 9440)))	; 9440 == -32 + #x2500
	    (if (r1 == ,(charset-id 'mule-unicode-e000-ffff))
		((r1 = ((((r0 & #x3f80) >> 7) - 32) * 96))
		 (r0 &= #x7f)
		 (r1 += (r0 + 57312)))	; 57312 == -32 + #xe000
	      ,(if (fboundp 'ccl-compile-lookup-character)
		   '((lookup-character utf-subst-table-for-encode r1 r0)
		     (if (r7 == 0)	; lookup failed
			 (r1 = #xfffd)))
		 '((r1 = #xfffd)))))))
      (if (r1 == #xfffd)
	  (write-repeat ?~)		; unknown character.
	(r0 = r1)))
    "CCL program to convert multibyte char to ucs with emacs-unicode."))

(if (get 'utf-translation-table-for-encode 'translation-table-id)
    ;; For Emacs 21.3 and later.
    (define-ccl-program w3m-euc-japan-encoder
      `(4
	(loop
	 ,@w3m-ccl-write-euc-japan-character
	 (translate-character utf-translation-table-for-encode r1 r0)
	 ,@w3m-ccl-get-ucs-codepoint-with-emacs-unicode
	 ,@w3m-ccl-generate-ncr)))
  ;; For Emacs 21.[12] that does not have `utf-translation-table-for-encode'.
  (define-ccl-program w3m-euc-japan-encoder
    `(4
      (loop
       ,@w3m-ccl-write-euc-japan-character
       ,@w3m-ccl-get-ucs-codepoint-with-emacs-unicode
       ,@w3m-ccl-generate-ncr))))

(if (get 'utf-translation-table-for-encode 'translation-table-id)
    ;; For Emacs 21.3 and later.
    (define-ccl-program w3m-iso-latin-1-encoder
      `(4
	(loop
	 ,@w3m-ccl-write-iso-latin-1-character
	 (translate-character utf-translation-table-for-encode r1 r0)
	 ,@w3m-ccl-get-ucs-codepoint-with-emacs-unicode
	 ,@w3m-ccl-generate-ncr)))
  ;; For Emacs 21.[12] that does not have `utf-translation-table-for-encode'.
  (define-ccl-program w3m-iso-latin-1-encoder
    `(4
      (loop
       ,@w3m-ccl-write-iso-latin-1-character
       ,@w3m-ccl-get-ucs-codepoint-with-emacs-unicode
       ,@w3m-ccl-generate-ncr))))

(unless (fboundp 'w3m-ucs-to-char)
  (defun w3m-ucs-to-char (codepoint)
    (or (decode-char 'ucs codepoint) ?~)))

(defun w3m-add-local-hook (hook function &optional append)
  "Add to the buffer-local value of HOOK the function FUNCTION."
  (add-hook hook function append t))

;; `display-images-p' has not been available prior to Emacs 21.0.105.
(unless (fboundp 'display-images-p)
  (defalias 'display-images-p 'display-graphic-p))

;; Function which returns non-nil when the current display device can
;; show images inline.
(defalias 'w3m-display-graphic-p 'display-images-p)

(defun w3m-display-inline-images-p ()
  "Returns non-nil when images can be displayed under the present
circumstances."
  (and w3m-display-inline-images (display-images-p)))

(defun w3m-create-image (url &optional no-cache referer size handler)
  "Retrieve data from URL and create an image object.
If optional argument NO-CACHE is non-nil, cache is not used.
If second optional argument REFERER is non-nil, it is used as Referer: field.
If third optional argument SIZE is non-nil, its car element is used as width
and its cdr element is used as height."
  (if (not handler)
      (w3m-process-with-wait-handler
	(w3m-create-image url no-cache referer size handler))
    (lexical-let ((set-size size)
		  (url url)
		  image size)
      (w3m-process-do-with-temp-buffer
	  (type (progn
		  (set-buffer-multibyte nil)
		  (w3m-retrieve url 'raw no-cache nil referer handler)))
	(when (w3m-image-type-available-p (setq type (w3m-image-type type)))
	  (setq image (create-image (buffer-string) type t :ascent 'center))
	  (if (and w3m-resize-images set-size)
	      (progn
		(set-buffer-multibyte t)
		(setq size (image-size image 'pixels))
		(if (and (null (car set-size)) (cdr set-size))
		    (setcar set-size
			    (/ (* (car size) (cdr set-size)) (cdr size))))
		(if (and (null (cdr set-size)) (car set-size))
		    (setcdr set-size
			    (/ (* (cdr size) (car set-size)) (car size))))
		(if (or (not (eq (car size)
				 (car set-size)))  ; width is different
			(not (eq (cdr size)
				 (cdr set-size)))) ; height is different
		    (lexical-let ((image image))
		      (w3m-process-do
			  (resized (w3m-resize-image
				    (plist-get (cdr image) :data)
				    (car set-size)(cdr set-size)
				    handler))
			(if resized (plist-put (cdr image) :data resized))
			image))
		  image))
	    image))))))

(defun w3m-create-resized-image (url rate &optional referer size handler)
  "Resize an cached image object.
URL is the image file's url.
RATE is resize percentage.
If REFERER is non-nil, it is used as Referer: field.
If SIZE is non-nil, its car element is used as width
and its cdr element is used as height."
  (if (not handler)
      (w3m-process-with-wait-handler
	(w3m-create-image url nil referer size handler))
    (lexical-let ((url url)
		  (rate rate)
		  image)
      (w3m-process-do-with-temp-buffer
	  (type (progn
		  (set-buffer-multibyte nil)
		  (w3m-retrieve url 'raw nil nil referer handler)))
	(when (w3m-image-type-available-p (setq type (w3m-image-type type)))
	  (setq image (create-image (buffer-string) type t :ascent 'center))
	  (progn
	    (set-buffer-multibyte t)
	    (w3m-process-do
		(resized (w3m-resize-image-by-rate
			  (plist-get (cdr image) :data)
			  rate
			  handler))
	      (if resized (plist-put (cdr image) :data resized))
	      image)))))))

(defun w3m-insert-image (beg end image &rest args)
  "Display image on the current buffer.
Buffer string between BEG and END are replaced with IMAGE."
  (let ((face (get-text-property beg 'face)))
    (add-text-properties beg end (list 'display image
				       'intangible image
				       'invisible nil))
    ;; Hide underlines behind inline images.
    ;; Gerd Moellmann <gerd@gnu.org>, the maintainer of Emacs 21, wrote in
    ;; the article <86heyi7vks.fsf@gerd.segv.de> in the list emacs-pretest-
    ;; bug@gnu.org on 18 May 2001 that to show an underline of a text even
    ;; if it has an image as a text property is the feature of Emacs 21.
    ;; However, that behavior is not welcome to the w3m buffers, so we do
    ;; to fix it with the following stuffs.
    (when (and face
	       (face-underline-p face))
      (put-text-property beg end 'face nil)
      (put-text-property beg end 'w3m-underline-face face))))

(defun w3m-remove-image (beg end)
  "Remove an image which is inserted between BEG and END."
  (remove-text-properties beg end '(display nil intangible nil))
  (let ((underline (get-text-property beg 'w3m-underline-face)))
    (when underline
      (put-text-property beg end 'face underline))))

(defun w3m-image-type-available-p (image-type)
  "Return non-nil if an image with IMAGE-TYPE can be displayed inline."
  (and (display-images-p)
       (image-type-available-p image-type)))

;;; Form buttons
(defface w3m-form-button-face
  '((((type x w32 mac) (class color))
     :background "lightgrey" :foreground "black"
     :box (:line-width 2 :style released-button))
    (((class color) (background light)) (:foreground "cyan" :underline t))
    (((class color) (background dark)) (:foreground "red" :underline t))
    (t (:underline t)))
  "*Face to fontify buttons in forms."
  :group 'w3m-face)

(defface w3m-form-button-mouse-face
  '((((type x w32 mac) (class color))
     :background "DarkSeaGreen1" :foreground "black"
     :box (:line-width 2 :style released-button))
    (((class color) (background light)) (:foreground "cyan" :underline t))
    (((class color) (background dark)) (:foreground "red" :underline t))
    (t (:underline t)))
  "*Face to fontify focused buttons in forms."
  :group 'w3m-face)

(defface w3m-form-button-pressed-face
  '((((type x w32 mac) (class color))
     :background "lightgrey" :foreground "black"
     :box (:line-width 2 :style pressed-button))
    (((class color) (background light)) (:foreground "cyan" :underline t))
    (((class color) (background dark)) (:foreground "red" :underline t))
    (t (:underline t)))
  "*Face to fontify pressed buttons in forms."
  :group 'w3m-face)

(defvar w3m-form-button-keymap
  (let ((map (copy-keymap widget-keymap)))
    (substitute-key-definition 'widget-forward nil map)
    (substitute-key-definition 'widget-backward nil map)
    map))

(define-widget 'w3m-form-button 'push-button
  "Widget for w3m form button."
  :keymap w3m-form-button-keymap
  :action (function (lambda (widget &optional e)
		      (eval (widget-get widget :w3m-form-action)))))

(defun w3m-form-make-button (start end properties)
  "Make button on the region from START to END."
  (if w3m-form-use-fancy-faces
      (progn
	(unless (memq (face-attribute 'w3m-form-button-face :box)
		      '(nil unspecified))
	  (and (eq ?\[ (char-after start))
	       (eq ?\] (char-before end))
	       (save-excursion
		 (goto-char start)
		 (delete-char 1)
		 (insert " ")
		 (goto-char end)
		 (delete-char -1)
		 (insert " ")
		 (setq start (1+ start)
		       end (1- end)))))
	(widget-convert-button
	 'w3m-form-button start end
	 :w3m-form-action (plist-get properties 'w3m-action))
	(add-text-properties start end properties))
    (add-text-properties start end (append '(face w3m-form-face)
					   properties))))

(defun w3m-setup-widget-faces ()
  (make-local-variable 'widget-button-face)
  (make-local-variable 'widget-mouse-face)
  (make-local-variable 'widget-button-pressed-face)
  (setq widget-button-face 'w3m-form-button-face)
  (setq widget-mouse-face 'w3m-form-button-mouse-face)
  (setq widget-button-pressed-face 'w3m-form-button-pressed-face))

;;; Toolbar
(defcustom w3m-use-toolbar (w3m-image-type-available-p 'xpm)
  "Non-nil activates toolbar of w3m."
  :group 'w3m
  :type 'boolean)

(defvar w3m-e21-toolbar-configurations
  '((auto-resize-tool-bars       . t)
    (auto-raise-tool-bar-buttons . t)
    ;;(tool-bar-button-margin      . 0)
    ;;(tool-bar-button-relief      . 2)
    ))

(defun w3m-e21-setup-toolbar (keymap defs)
  (let ((configs w3m-e21-toolbar-configurations)
	config)
    (while (setq config (pop configs))
      (set (make-local-variable (car config)) (cdr config))))
  ;; Invalidate the default bindings.
  (let ((keys (cdr (key-binding [tool-bar] t)))
	item)
    (while (setq item (pop keys))
      (when (setq item (car-safe item))
	(define-key keymap (vector 'tool-bar item) 'undefined))))
  (let ((n (length defs))
	def)
    (while (>= n 0)
      (setq n (1- n)
	    def (nth n defs))
      (define-key keymap (vector 'tool-bar (aref def 1))
	(list 'menu-item (aref def 3) (aref def 1)
	      :enable (aref def 2)
	      :image (symbol-value (aref def 0)))))))

(defun w3m-e21-make-toolbar-buttons (buttons)
  (dolist (button buttons)
    (let ((up (expand-file-name (concat button "-up.xpm")
				w3m-icon-directory))
	  (down (expand-file-name (concat button "-down.xpm")
				  w3m-icon-directory))
	  (disabled (expand-file-name (concat button "-disabled.xpm")
				      w3m-icon-directory))
	  (icon (intern (concat "w3m-toolbar-" button "-icon")))
	  (props '(:ascent
		   center
		   :color-symbols (("backgroundToolBarColor" . "None")))))
      (unless (boundp icon)
	(if (file-exists-p up)
	    (progn
	      (setq up (apply 'create-image up 'xpm nil props))
	      (if (file-exists-p down)
		  (setq down (apply 'create-image down 'xpm nil props))
		(setq down nil))
	      (if (file-exists-p disabled)
		  (setq disabled (apply 'create-image disabled 'xpm nil props))
		(setq disabled nil))
	      (set icon (vector down up disabled disabled)))
	  (error "Icon file %s not found" up))))))

(defun w3m-setup-toolbar ()
  (when w3m-use-toolbar
    (w3m-e21-make-toolbar-buttons w3m-toolbar-buttons)
    (w3m-e21-setup-toolbar w3m-mode-map w3m-toolbar)))

(defalias 'w3m-update-toolbar 'ignore)

;;; Header line & Tabs
(defcustom w3m-tab-width 16
  "w3m tab width."
  :group 'w3m
  :type '(integer :size 0))

(defface w3m-tab-unselected-face
  '((((type x w32 mac) (class color))
     :background "Gray50" :foreground "Gray20"
     :underline "Gray85" :box (:line-width -1 :style released-button))
    (((class color))
     (:background "cyan" :foreground "black" :underline "blue")))
  "*Face to fontify unselected tabs."
  :group 'w3m-face)

(defface w3m-tab-unselected-retrieving-face
  '((((type x w32 mac) (class color))
     :background "Gray50" :foreground "OrangeRed"
     :underline "Gray85" :box (:line-width -1 :style released-button))
    (((class color))
     (:background "cyan" :foreground "OrangeRed" :underline "blue")))
  "*Face to fontify unselected tabs which are retrieving their pages."
  :group 'w3m-face)

(defface w3m-tab-selected-face
  '((((type x w32 mac) (class color))
     :background "Gray85" :foreground "black"
     :underline "Gray85" :box (:line-width -1 :style released-button))
    (((class color))
     (:background "blue" :foreground "black" :underline "blue"))
    (t (:underline t)))
  "*Face to fontify selected tab."
  :group 'w3m-face)

(defface w3m-tab-selected-retrieving-face
  '((((type x w32 mac) (class color))
     :background "Gray85" :foreground "red"
     :underline "Gray85" :box (:line-width -1 :style released-button))
    (((class color))
     (:background "blue" :foreground "red" :underline "blue"))
    (t (:underline t)))
  "*Face to fontify selected tab which is retrieving its page."
  :group 'w3m-face)

(defface w3m-tab-background-face
  '((((type x w32 mac) (class color))
     :background "LightSteelBlue" :foreground "black"
     :underline "Gray85")
    (((class color))
     (:background "white" :foreground "black" :underline "blue")))
  "*Face to fontify background of tab line."
  :group 'w3m-face)

(defun w3m-setup-header-line ()
  (setq header-line-format
	(cond
	 (w3m-use-tab
	  (list '(:eval (w3m-tab-line))))
	 (w3m-use-header-line
	  (list
	   (propertize
	    "Location: "
	    'face 'w3m-header-line-location-title-face)
	   '(:eval
	     (propertize
	      (if (stringp w3m-current-url)
		  (replace-regexp-in-string "%" "%%" w3m-current-url)
		"")
	      'face 'w3m-header-line-location-content-face
	      'local-map (let ((map (make-sparse-keymap)))
			   (define-key map [header-line mouse-2]
			     'w3m-goto-url)
			   map)
	      'help-echo "mouse-2 prompts to input URL")))))))

(defun w3m-tab-drag-mouse-function (event buffer)
  (let ((window (posn-window (event-end event)))
	mpos)
    (when (framep window) ; dropped at outside of the frame.
      (setq window nil
	    mpos (mouse-position))
      (and (framep (car mpos))
	   (car (cdr mpos))
	   (cdr (cdr mpos))
	   (setq window (window-at (car (cdr mpos))
				   (cdr (cdr mpos))
				   (car mpos)))))
    (when window
      (unless (string= (buffer-name (window-buffer window))
		       buffer)
	(select-window window)
	(switch-to-buffer buffer)))))

(defun w3m-tab-make-keymap (buffer)
  (let ((map (make-sparse-keymap))
	(drag-action `(lambda (e) (interactive "e")
			(w3m-tab-drag-mouse-function
			 e ,(buffer-name buffer))))
	(up-action `(lambda (e) (interactive "e")
		      (switch-to-buffer ,(buffer-name buffer)))))
    (define-key map [header-line down-mouse-1] 'ignore)
    (define-key map [header-line down-mouse-2] 'ignore)
    (define-key map [header-line drag-mouse-1] drag-action)
    (define-key map [header-line drag-mouse-2] drag-action)
    (define-key map [header-line mouse-1] up-action)
    (define-key map [header-line mouse-2] up-action)
    map))

(defvar w3m-tab-line-format nil
  "Internal variable used to keep contents to be shown in the header-line
while the external w3m process is running.  It is also used to control
the `w3m-tab-line' function running too frequently, set by the function
itself and cleared by a timer.")

(defun w3m-tab-line ()
  (or
   (when w3m-current-process
     (or w3m-tab-line-format
	 (progn
	   (run-at-time 0.1 nil (lambda nil (setq w3m-tab-line-format nil)))
	   nil)))
   (let* ((current (current-buffer))
	  (buffers (w3m-list-buffers))
	  (width (if (> (* (length buffers) (+ 5 w3m-tab-width))
			(window-width))
		     (max (- (/ (window-width) (length buffers)) 5) 1)
		   w3m-tab-width))
	  value)
     (setq
      value
      (concat
       (save-current-buffer
	 (mapconcat
	  (lambda (buffer)
	    (let ((title (w3m-buffer-title buffer))
		  (favicon (if w3m-use-favicon
			       (w3m-favicon-image-of buffer))))
	      (propertize
	       (concat (if favicon
			   (propertize "  " 'display favicon)
			 "  ")
		       (if (and (> width 0)
				(> (string-width title) width))
			   (if (> width 6)
			       (concat
				(truncate-string-to-width
				 title
				 (max 0 (- width 3)))
				"...")
			     (truncate-string-to-width title width))
			 (concat title
				 (make-string (max 0
						   (-
						    width
						    (string-width title)))
					      ?\ )))
		       "  ")
	       'mouse-face 'highlight
	       'face (if (progn (set-buffer buffer) w3m-current-process)
			 (if (eq buffer current)
			     'w3m-tab-selected-retrieving-face
			   'w3m-tab-unselected-retrieving-face)
		       (if (eq buffer current)
			   'w3m-tab-selected-face
			 'w3m-tab-unselected-face))
	       'local-map (w3m-tab-make-keymap buffer)
	       'help-echo title)))
	  buffers
	  (propertize " " 'face 'w3m-tab-background-face)))
       (propertize (make-string (window-width) ?\ )
		   'face 'w3m-tab-background-face)))
     (setq w3m-tab-line-format (when w3m-current-process value))
     value)))

(defun w3m-update-tab-line ()
  "Update tab line."
  (when w3m-use-tab
    (set-cursor-color (frame-parameter (selected-frame) 'cursor-color))))

(add-hook 'w3m-mode-setup-functions 'w3m-setup-header-line)
(add-hook 'w3m-mode-setup-functions 'w3m-setup-widget-faces)

(provide 'w3m-e21)

;;; w3m-e21.el ends here

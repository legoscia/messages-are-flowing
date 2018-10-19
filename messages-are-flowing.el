;;; messages-are-flowing.el --- visible indication when composing "flowed" emails  -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Magnus Henoch

;; Author: Magnus Henoch <magnus.henoch@gmail.com>
;; Keywords: mail
;; Version: 0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; If you're writing emails to people who might not view them on a
;; display with the same width as yours, you probably want to send the
;; messages as "flowed" (as per RFC 2646) in order to let the
;; recipient's device disregard the line breaks in your message and
;; rewrap the text for readability.  In `message-mode', you can do
;; that by turning on the `use-hard-newlines' minor mode.
;;
;; However, you probably want some of your newlines to stay put, for
;; paragraph breaks, and for content where you really do want to break
;; the lines yourself.  You can do that with `use-hard-newlines', but
;; it doesn't show you where it's going to put "hard" newlines and
;; where it's going to put "soft" ones.
;;
;; That's where `messages-are-flowing' comes in.  It marks all "hard"
;; newlines with a `⏎' symbol, so that you can have an idea about what
;; parts of your message might be reflowed when the recipient reads it.
;;
;; To activate `messages-are-flowing', add the following to your .emacs:
;;
;; (with-eval-after-load "message"
;;   (add-hook 'message-mode-hook 'messages-are-flowing-use-and-mark-hard-newlines))
;;
;; If your mail program does not encode the flowed format, the following
;; can be used to convert soft newlines to spaces:
;;
;; (add-hook 'message-mode-hook 'messages-are-flowing-enhance-fill-newline)
;;
;; Also note that messages-are-flowing-enhance-fill-newline-modes will need to
;; be set with the modes the enhanced fill-newline should be used in

;;; Code:

;;;###autoload
(defun messages-are-flowing-use-and-mark-hard-newlines ()
  "Turn on `use-hard-newlines', and make hard newlines visible.
The main use of this is to send \"flowed\" email messages, where
line breaks within paragraphs are adjusted by the recipient's
device, such that messages remain readable on narrow displays."
  (interactive)
  (use-hard-newlines)
  (add-hook 'after-change-functions 'messages-are-flowing--mark-hard-newlines nil t))

;;;###autoload
(defun messages-are-flowing-enhance-fill-newline ()
  "Function to enhance fill-newline, only for certain modes"
	(advice-add 'fill-newline :around #'messages-are-flowing--fill-newline-wrapper)
	(turn-off-auto-fill)
  )

(defgroup messages-are-flowing nil
  "Utilities for working with format=flowed messages"
  )

(defcustom messages-are-flowing-enhance-fill-newline-modes '()
  "Modes to apply to when messages-are-flowing-enhance-fille-newline is in use"
  :type '(repeat function)
  :group 'messages-are-flowing)


(defun messages-are-flowing--mark-hard-newlines (beg end &rest _ignore)
  "Visibly mark hard newlines between BEG and END.
For each hard newline, add a display property that makes it visible.
For each soft newline, remove any display property."
  ;; Uncomment for debugging:
  ;;(interactive (list (point-min) (point-max)))
  (save-excursion
    (goto-char beg)
    (while (search-forward "\n" end t)
      (let ((pos (1- (point))))
        (if (get-text-property pos 'hard)
            ;; Use `copy-sequence', because display property values must not be `eq'!
            (add-text-properties pos (1+ pos) (list 'display (copy-sequence "⏎\n")))
          (remove-text-properties pos (1+ pos) '(display nil)))))))


;; fill-newline that puts a space for soft newlines
;; Based on https://emacs.stackexchange.com/questions/19296/retooling-fill-paragraph-to-append-trailing-spaces
(defun messages-are-flowing--fill-newline ()
  "Custom version of fill-newline to behave 3676ishly"

  ;; Replace whitespace here with one newline, then
  ;; indent to left margin.
  (skip-chars-backward " \t")
  (insert ?\s)
  (insert ?\n)
  ;; Give newline the properties of the space(s) it replaces
  (set-text-properties (1- (point)) (point)
					   (fill-text-properties-at (point)))
  (and (looking-at "\\( [ \t]*\\)\\(\\c|\\)?")
	   (or (aref (char-category-set (or (char-before (1- (point))) ?\000)) ?|)
		   (match-end 2))
	   ;; When refilling later on, this newline would normally not be replaced
	   ;; by a space, so we need to mark it specially to re-install the space
	   ;; when we unfill.
	   (put-text-property (1- (point)) (point) 'fill-space (match-string 1)))
  ;; If we don't want breaks in invisible text, don't insert
  ;; an invisible newline.
  (if fill-nobreak-invisible
	  (remove-text-properties (1- (point)) (point)
							  '(invisible t)))
  (if (or fill-prefix
		  (not fill-indent-according-to-mode))
	  (fill-indent-to-left-margin)
	(indent-according-to-mode))
  ;; Insert the fill prefix after indentation.
  (and fill-prefix (not (equal fill-prefix ""))
	   ;; Markers that were after the whitespace are now at point: insert
	   ;; before them so they don't get stuck before the prefix.
	   (insert-before-markers-and-inherit fill-prefix)))

(defun messages-are-flowing--fill-newline-wrapper (orig-fun &rest args)
  "Call [messages-are-flowing--]fill-newline depending on mode"

  ;; NOTE: this is done so that it doesn't affect other modes
  (if (member major-mode messages-are-flowing-enhance-fill-newline-modes)
	  (progn ;; allow multiple statements
		 ;; Alter fill-newline
		 (messages-are-flowing--fill-newline)
		)
	(apply orig-fun args)
	)
  )

(provide 'messages-are-flowing)
;;; messages-are-flowing.el ends here

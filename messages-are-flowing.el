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
;; When pasting text, you get hardened newlines between paragraphs. To
;; also make sure newlines for pasted code and poetry is hardened, use
;; `harden-region' on such text.

;;; Code:

(defcustom messages-are-flowing-newline-marker "⏎"
  "String used to visualise hard newlines."
  :type 'string
  :group 'message-interface)

;;;###autoload
(defun messages-are-flowing-use-and-mark-hard-newlines ()
  "Turn on `use-hard-newlines', and make hard newlines visible.
The main use of this is to send \"flowed\" email messages, where
line breaks within paragraphs are adjusted by the recipient's
device, such that messages remain readable on narrow displays."
  (interactive)
  (use-hard-newlines 3 t)
  (add-hook 'after-change-functions 'messages-are-flowing--mark-hard-newlines nil t)
  (add-hook 'after-change-functions 'messages-are-flowing--harden-between-paras nil t))

;;;###autoload
(defun harden-region (start end)
  "Call this interactively on regions like code and poetry to make
every newline hard in that region."
  (interactive "r")
  (when use-hard-newlines
    (save-excursion
      (goto-char start)
      (while (< (point) (min (point-max) end))
	(end-of-line)
	(forward-char)
	(set-hard-newline-properties
	 (- (point) 1) (point))))))

;;;###autoload
(defun soften-region (start end)
  "Call this interactively on a region to make all newlines soft in
that region."
  (interactive "r")
  (remove-text-properties start end '(hard nil)))

(defun messages-are-flowing--harden-between-paras  (beg end &rest _ignore)
  "Ensure that paragraphs separated by blank lines are hard.

Otherwise that wouldn't be the case for e.g. pasted text."
  (save-excursion
    (goto-char beg)
    (while (search-forward "\n\n" end t)
      (set-hard-newline-properties
       (- (point) 2) (point)))))

(defun messages-are-flowing--mark-hard-newlines (beg end &rest _ignore)
  "Visibly mark hard newlines in paragraphs between BEG and END.
For each hard newline inside a paragraph, add a display property
that makes it visible. For each soft newline, or for hard
newlines between paragraphs, remove any display property."
  ;; Uncomment for debugging:
  ;;(interactive (list (point-min) (point-max)))
  (save-excursion
    (goto-char (max (point-min) (- beg 2)))
    (while (search-forward "\n" (min (+ end 2) (point-max)) t)
      (let ((pos (1- (point))))
        (if (and (get-text-property pos 'hard)
		 (not (or (eq 10 (char-after (1+ pos)))
			  (eq 10 (char-after (1- pos))))))
            ;; Use `copy-sequence', because display property values must not be `eq'!
            (add-text-properties
	     pos (1+ pos)
	     (list 'display (copy-sequence
			     (concat messages-are-flowing-newline-marker "\n"))))
          (remove-text-properties pos (1+ pos) '(display nil)))))))

(provide 'messages-are-flowing)
;;; messages-are-flowing.el ends here

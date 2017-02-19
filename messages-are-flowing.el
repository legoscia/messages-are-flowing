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

(provide 'messages-are-flowing)
;;; messages-are-flowing.el ends here

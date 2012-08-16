;;; ruby-mode-expansions.el --- ruby-specific expansions for expand-region

;; Copyright (C) 2011 Magnar Sveen

;; Author: Matt Briggs
;; Based on js-mode-expansions by: Magnar Sveen <magnars@gmail.com>
;; Keywords: marking region

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


;; Idiomatic ruby has a lot of nested blocks, and its function marking seems a bit buggy.
;;
;; Expansions:
;;
;;
;;  er/mark-ruby-block
;;  er/mark-ruby-function

;;; Code:

(require 'expand-region-core)

(defun er/mark-ruby-block ()
  (interactive)
  (forward-line 1)
  (beginning-of-line)
  (ruby-beginning-of-block)
  (set-mark (point))
  (ruby-end-of-block)
  (end-of-line)
  (exchange-point-and-mark))

(defun er/mark-ruby-symbol ()
  "Mark the entire symbol around or in front of point."
  (interactive)
  (let ((symbol-regexp ":\\|\\s_\\|\\sw"))
    (when (or (looking-at symbol-regexp)
              (looking-back symbol-regexp))
      (while (looking-at symbol-regexp)
        (forward-char))
      (set-mark (point))
      (while (looking-back symbol-regexp)
        (backward-char)))))

(defun er/search-forward-for-closed-nesting (open close)
  "A helper function for matching nested constructs."
  (while (and (not (looking-at (regexp-quote close)))
              (< (point) (point-max)))
    (cond ((looking-at (regexp-quote open))
           (forward-char)
           (er/search-forward-for-closed-nesting open close))
          (t (forward-char))))
  (if (looking-at (regexp-quote close)) (forward-char)))

(defun er/mark-ruby-choose-your-own-quotes ()
  "Mark choose-your-own-quotes style string, arrays, regexen, etc."
  (interactive)
  (let ((quote_start)
        (quote_end))
    (save-excursion
      (while (and (not (looking-back "%[qQwWr]{"))
                  (> (point) (point-min)))
        (backward-char))
      (when (looking-back "%[qQwWr]{")
        (setq quote_start (- (point) 3))
        (er/search-forward-for-closed-nesting "{" "}")
        (when (looking-back "}")
          (setq quote_end (point)))))
    (when (and quote_start
               quote_end
               (<= quote_start (point))
               (>= quote_end   (point)))
      (set-mark  quote_end)
      (goto-char quote_start))))

(defun er/mark-ruby-function ()
  "Mark the current Ruby function."
  (interactive)
  (condition-case nil
      (forward-char 3)
    (error nil))
  (let ((ruby-method-regex "^[\t ]*def\\_>"))
    (word-search-backward ruby-method-regex)
    (while (syntax-ppss-context (syntax-ppss))
      (word-search-backward ruby-method-regex)))
  (set-mark (point))
  (ruby-end-of-block)
  (end-of-line)
  (exchange-point-and-mark))

(defun er/add-ruby-mode-expansions ()
  "Adds Ruby-specific expansions for buffers in ruby-mode"
  (set (make-local-variable 'er/try-expand-list)
       (append er/try-expand-list
               '(er/mark-ruby-symbol
                 er/mark-ruby-choose-your-own-quotes
                 er/mark-ruby-block
                 er/mark-ruby-function))))

(add-hook 'ruby-mode-hook 'er/add-ruby-mode-expansions)

(provide 'ruby-mode-expansions)

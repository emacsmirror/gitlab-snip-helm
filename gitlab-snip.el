;;; gitlab-snip.el --- Gitlab snippets api conexion                  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Fermin Munoz

;; Author: Fermin MF <fmfs@posteo.net>
;; Created: 8 Abril 2020
;; Version: 0.0.1
;; Keywords: languages, basic

;; URL: https://gitlab.com/sasanidas/gitlab-snip
;; Package-Requires: ((emacs "25") (dash "2.17.0") (helm "1.5.9"))
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Small function that send the selected text to gitlab, and creates an snippet.

;;; Code:

(require 'dash)
(require 'helm)

(defvar gitlab-snip-user-token ""
  "This is the required token for using the api: https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html.")

(defvar gitlab-snip-visibility "public"
  "Snippets default visibility.")

(defvar gitlab-snip-server "https://gitlab.com"
  "Gitlab server to save the snippets.")


(defun gitlab-snip-send ()
  "Create an snippet with the selected area."
  (interactive)
  (let* ((snippet--name (read-from-minibuffer "Insert snippet name: "))
	 (snippet--description (read-from-minibuffer "Insert the snippet description: "))
	 (snippet--text
	  (json-encode (let* ((pos1 (region-beginning)) (pos2 (region-end)))(filter-buffer-substring pos1 pos2)))))
    (let
	((url-request-method "POST")
	 (url-request-extra-headers
	  (list (cons "Content-Type"  "application/json")
		(cons "Private-Token"  gitlab-snip-user-token)))
	 (url-request-data (concat
			    "{\"title\": \"" snippet--name " \",
                         \"content\": "snippet--text",
                         \"description\": \"" snippet--description"\",
                         \"file_name\": \"" (buffer-name) "\",
                         \"visibility\": \""gitlab-snip-visibility"\" }")))
      (url-retrieve-synchronously (concat gitlab-snip-server "/api/v4/snippets")))))


(defun gitlab--snippet-actions ( action &optional  snippet-id)
"Function for gitlab-snip-helm actions SNIPPET-ID ACTION."
  (cond ((string-equal action "Insert")
	 (with-current-buffer (let
				  ((url-request-extra-headers
				    (list (cons "Private-Token" gitlab-snip-user-token))))
				(url-retrieve-synchronously (concat "https://gitlab.com/api/v4/snippets/" snippet-id "/raw")))
	   (goto-char (point-min))
	   (re-search-forward "^$")
	   (delete-region (point) (point-min))
	   (buffer-string)))
	((string-equal action "All-snippets")
	 (with-current-buffer
				   (let
				       ((url-request-extra-headers
					 (list (cons "Private-Token" gitlab-snip-user-token))))
				     (url-retrieve-synchronously "https://gitlab.com/api/v4/snippets"))
				 (json-read)))))

;; TODO The lexical scope is not working
(defun gitlab-snip-helm-snippets ()
   "Insert selected snippet in the current mark."
   (interactive)
   (let* () (setq gitlab--request-result (gitlab--snippet-actions "All-snippets"))
     
     (setq helm-source-user-snippets
	   (helm-build-sync-source "gitlab-snip"
	     :candidates (-map (lambda (x)
				 (cdr (nth 1 x)))
			       gitlab--request-result)
	     :action '(("Insert" . (lambda (selected) (insert
						       (let* ((snippet--id (car (-non-nil (-map (lambda (x)
										 (if (string-equal selected (cdr (nth 1 x)) )
										     (number-to-string (cdr (nth 0 x)))))
									       gitlab--request-result)))  ))
							 (gitlab--snippet-actions "Insert" snippet--id ))))))))
     (helm :sources '(helm-source-user-snippets)
	   :buffer "*helm gitlab-snip*")))



(provide 'gitlab-snip)
;;; gitlab-snip.el ends here

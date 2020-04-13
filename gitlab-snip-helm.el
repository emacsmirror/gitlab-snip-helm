;;; gitlab-snip-helm.el --- Gitlab snippets api helm package                  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Fermin Munoz

;; Author: Fermin MF <fmfs@posteo.net>
;; Created: 13 Abril 2020
;; Version: 0.0.2
;; Keywords: tools,files,convenience

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

;; This package manage gitlab snippets with the help of helm framework.

;;; Code:

(require 'dash)
(require 'helm)
(require 'json)

(defvar gitlab-snip-helm-user-token ""
  "This is the required token for using the api: https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html.")

(defvar gitlab-snip-helm-visibility "public"
  "Snippets default visibility.")

(defvar gitlab-snip-helm-server "https://gitlab.com"
  "Gitlab server to save the snippets.")


(defun gitlab-snip-helm-send ()
  "Create an snippet with the selected area and send it to the gitlab selected server."
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


(defun gitlab-snip-helm--actions ( action &optional  snippet-id)
  "Helped function to define the diferent snippets acctions, it requires the action defined string ACTION and an optional SNIPPET-ID."
  (cond ((string-equal action "Insert")
	 (with-current-buffer (let
				  ((url-request-extra-headers
				    (list (cons "Private-Token" gitlab-snip-user-token))))
				(url-retrieve-synchronously (concat "https://gitlab.com/api/v4/snippets/" snippet-id "/raw")))
	   (goto-char (point-min))
	   (re-search-forward "^$")
	   (delete-region (point) (point-min))
	   (buffer-string)))

	((string-equal action "Get-snippets")
	 (with-current-buffer
	     (let
		 ((url-request-extra-headers
		   (list (cons "Private-Token" gitlab-snip-user-token))))
	       (url-retrieve-synchronously "https://gitlab.com/api/v4/snippets"))
	   (json-read)))))

(defun gitlab-snip-helm-snippets ()
  "Helm extension that insert the selected snippet in the current buffer mark."
  (interactive)
  (let* ((helm-source-user-snippets
	  (helm-build-sync-source "gitlab-snip"
	    :candidates (-map (lambda (x)
				(cdr (nth 1 x)))
			      (gitlab-snip-helm--actions "Get-snippets"))
	    :action '(("Insert" . (lambda (selected) (insert (let*
								 ((snippet--id (car
										(-non-nil (-map (lambda (x)
												  (if (string-equal selected (cdr (nth 1 x)) )
												      (number-to-string (cdr (nth 0 x)))))
												(gitlab-snip-helm--actions "Get-snippets"))))))
							       (gitlab--snippet--actions "Insert" snippet--id )))))))))
    (helm :sources (list  helm-source-user-snippets)
	  :buffer "*helm gitlab-snip*")))

(provide 'gitlab-snip-helm)
;;; gitlab-snip-helm.el ends here

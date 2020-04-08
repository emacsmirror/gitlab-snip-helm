;;; gitlab-snip.el --- Gitlab snippets api conexion                  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Fermin Munoz

;; Author: Fermin MF <fmfs@posteo.net>
;; Created: 8 Abril 2020
;; Version: 0.0.1
;; Keywords: languages, basic

;; URL: https://gitlab.com/sasanidas/emacs-c64-basic-ide
;; Package-Requires: ((emacs "25"))
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
(require 'json)

(defvar gitlab-snip-user-token ""
  "This is the required token for using the api: https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html.")

(defvar gitlab-snip-visibility "public"
  "Snippets default visibility.")


(defun gitlab-snip-send ()
  "Create an snippet with the selected area."
  (interactive)
  (let* ((snippet--name (read-from-minibuffer "Inserta el nombre del snippet: "))
	 (snippet--description (read-from-minibuffer "Inserta la descripcion: "))
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
    (url-retrieve-synchronously "https://gitlab.com/api/v4/snippets"))))

;;; gitlab-snip.el ends here

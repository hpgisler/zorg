;;; zorg.el --- Zettelkasten navigation for org files, structured as Folgezettels -*- lexical-binding: t -*-

;; Copyright (C) 2024 Hanspeter Gisler

;; Author: Hanspeter Gisler <info1@gisler.pro>
;; Maintainer: Hanspeter Gisler <info1@gisler.pro>
;; Created: 2024
;; Version: 1.0
;; Package-Requires: ((emacs "27.1") (org "9.6.15") (evil "1.15.0"))
;; Homepage: https://github.com/hpgisler/zorg
;; Keywords: Zettelkasten, org

;;; Commentary:

;; Zorg aims to provide simple navigational functions for org files
;; which are structured as a Zettelkasten, in which each heading
;; represents a Zettel.  The Zettels (headings) relative location
;; is significant and thus forms Folgezettel relationships.
;; (implicit linking)

;;; Code:

(require 'org)
(require 'evil)

(defvar zorg-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Keymap for 'zorg-mode'.
It probably makes sense to define some keybindings.

In standard Emacs keybindings, you probably may do something as follows:

      (define-key zorg-mode-map (kbd \"C-}\") #'zorg-forward-heading)
      (define-key zorg-mode-map (kbd \"C-{\") #'zorg-backward-heading)
      (define-key zorg-mode-map (kbd \"C->\") #'zorg-inner-or-forward-heading)
      (define-key zorg-mode-map (kbd \"C-<\") #'zorg-outer-or-backward-heading)
      (define-key zorg-mode-map (kbd \"C-)\") #'org-fold-show-entry)
      (define-key zorg-mode-map (kbd \"C-(\") #'org-fold-hide-entry)

If you use 'evil' you may do the binding as indicated in the following example:

    (evil-define-minor-mode-key '(motion normal) 'zorg-mode
      \"}\" 'zorg-forward-heading
      \"{\" 'zorg-backward-heading
      \">\" 'zorg-inner-or-forward-heading
      \"<\" 'zorg-outer-or-backward-heading
      \")\" 'org-fold-show-entry  ; this is not actually a zorg function
      \"(\" 'org-fold-hide-entry) ; this is not actually a zorg function")


;;;###autoload
(defun zorg-toggle-fold-state ()
  "Toggle fold state of headings."
  (interactive)
  (put 'zorg-toggle-fold-state 'fold-state-p (not (get 'zorg-toggle-fold-state 'fold-state-p)))
  (zorg--update-fold))



;;;###autoload
(define-minor-mode zorg-mode
  "Buffer-local minor mode for navigating 'org-mode' formatted Zettelkasten.
It is assumed, that the Zettelkasten is:

- fully contained in one org file

- the org files headings structure directly correspond to Luhmann's Folgezettel
  structure, i.e. its headings are arranged as Luhmann's Zettels -
  but without explizit id number annotation (e.g. 2a5b) i.e.

- headings on the same indentation level (*..)
  correspond to e.g. to ..2a, ..2b etc.

- sub-headings correspond to e.g. ..2a1, 2a2, etc

- when linking to a zettel is required,
  org's normal linking mechanism to headings is employed

Furthermore it is assumed that Zettels - i.e. individual atomic notes -
are quite short.  Adhering to the style of Luhmann's note taking practice,
each note fit on an A6 sized paper Zettel.  This brevity of a Zettel actually
is not a technical requirement, but it ensures the following:

- Quick grasp of a Zettel's content when skimming through the Zettelkasten;
  the readers concentration span should suffice when scanning such a Zettel

- Thus the file size of the entire Zettelkasten should remain small enough
  for fast processing by Emacs.  E.g. 10'000 Zettels,
  each not larger than 1 k Byte, leads to a Zettelkasten sized 10 M Bytes.

Zorg-mode provides commands and a keymap 'zorg-mode-map',
aiming for easy navigation within an 'org-mode' formatted file,
structured as a Zettelkasten.

Visibility of a Zettel's neighbours is thus provided
in the style of Luhmannn's Zettelkasten: Org headings following each other
on the same level or as direct sub-headings form such relationships; such
relationships might be interpreted as Folgezettels.  Zettels relative location
thus form implicit links in-between them.  It is assumed that this kind of
visibility of neighbouring Zettels is relevant for surfacing unexpected
connections in-between ideas contained in them: Namely during sorting-in
new Zettels as well as during browsing through the Zettelkasten.

To not obfuscate such relationships in-between Zettels, well-arranged Zettel
presentation during Zettel browsing seems key.  (The aim of this package.)
Of course other mechanisms for Zettel discoverability must be employed es well -
apart from the implicit relationships formed by Folgezettels such as:

- Direct linking between Zettels, via 'org-mode's' provided mechanisms.
- Creation of Zettels acting as topic hubs, linking to related Zettels
- etc."
  :lighter " Zorg"
  :keymap zorg-mode-map
  :version "1.0")

;;;###autoload
(defun zorg-forward-heading ()
  "Move forward 1 heading at the same level.
If there are no more headings at the same level, attempt to move to
the next higher heading.
The final heading moved to will be the last top level heading."
  (interactive)
  (if (and (org-evil-motion--last-heading-same-level-p) (org-evil-motion--heading-has-parent-p) (zorg--next-headline-exists-p))
      (progn
        (org-evil-motion-up-heading)
        (zorg-forward-heading))
    (if (not (org-evil-motion--last-heading-same-level-p))
        (progn
          (if (not (org-before-first-heading-p))
              (org-fold-hide-subtree))
          (org-forward-heading-same-level 1)
          (org-fold-show-children))
      (error "Already at the last heading")))
  (zorg--update-fold))

;;;###autoload
(defun zorg-backward-heading ()
  "Move backward 1 heading at the same level.
If there are no more headings at the same level, attempt to move to
the next higher heading.
The final heading moved to will be the first top level heading."
  (interactive)
  (if (org-evil-motion--first-heading-same-level-p)
      (if (org-evil-motion--heading-has-parent-p)
          (progn
            (if (not (org-at-heading-p))
                (org-evil-motion-up-heading))
            (org-fold-hide-entry) ;
            (org-fold-hide-subtree)
            (org-evil-motion-up-heading))
        (if (org-at-heading-p)
            (error "Already at first top level heading")
          (org-evil-motion-up-heading)))
    (progn
      (org-fold-hide-subtree)
      (org-backward-heading-same-level 1)
      (org-fold-show-children)))
  (zorg--update-fold))

;;;###autoload
(defun zorg-inner-or-forward-heading ()
  "Move to sub heading if it exists or forward 1 heading at the same level.
If there are no more headings at the sub- or same level, attempt to move to
the next higher heading.
Finally, this command will cycle through all the sub headings
of the last top level heading."
  (interactive)
  (if (org-before-first-heading-p)
      (zorg-forward-heading)
    (progn
      (org-fold-hide-entry)
      (org-fold-show-children)
      (if (outline-has-subheading-p)
          (progn 
            (org-next-visible-heading 1)
            (org-fold-show-children))
        (zorg-forward-heading))))
  (zorg--update-fold))

;;;###autoload
(defun zorg-outer-or-backward-heading ()
  "Move to super heading if it exists or backward 1 heading at the same level.
The final heading moved to will be the first top level heading."
  (interactive)
  (if (org-evil-motion--heading-has-parent-p)
      (progn
        (if (not (org-at-heading-p))
            (org-evil-motion-up-heading))
        (org-fold-hide-subtree)
        (org-evil-motion-up-heading))
    (zorg-backward-heading))
  (zorg--update-fold))


(defun zorg--next-headline-exists-p ()
  "Check whether there exists a next headline after point."
  (save-excursion
    (outline-next-heading)
    (not (eobp))))


(defun zorg--update-fold ()
  "Based on `zorg-toggle-fold-state' show or hide current heading."
  (funcall (if (get 'zorg-toggle-fold-state 'fold-state-p) #'org-fold-show-entry #'org-fold-hide-entry)))


(provide 'zorg)

;;; zorg.el ends here

;;; zorg.el --- Zettelkasten navigation for org files, structured as Folgezettels -*- lexical-binding: t -*-

;;; Commentary:

;; Zorg aims to provide simple navigational functions for org files
;; which are structured as a Zettelkasten, in which each heading
;; represents a Zettel.  The Zettels (headings) relative location
;; is significant and thus forms Folgezettel relationships.
;; (implicit linking)

;;; Code:

(require 'org)
(require 'evil)

:(defvar zorg-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd ")") #'zorg-forward-heading) 
    (define-key map (kbd "]") #'zorg-backward-heading) 
    (define-key map (kbd "|") #'zorg-inner-or-forward-heading) 
    (define-key map (kbd ">") #'zorg-outer-or-backward-heading) 
    map)
  "Keymap for `zorg-mode'.")

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

- Thus the file size of the entire Zettelkasten should remains small enough
  for fast processing by Emacs.  E.g. 10'000 Zettels,
  each not larger than 1 kByte, leads to a Zettelkasten sized 10 MBytes.

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
presentation during their browsing seems key.  Of course other mechanisms for
Zettel discoverability must be employed es well - apart from the implicit
relationships formed by Folgezettels such as:

- Direct linking between Zettels
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
  (if (and (org-evil-motion--last-heading-same-level-p) (org-evil-motion--heading-has-parent-p))
      (progn
        (org-evil-motion-up-heading)
        (zorg-forward-heading))
    (if (not (org-evil-motion--last-heading-same-level-p))
        (progn
          (if (not (org-before-first-heading-p))
              (org-fold-hide-subtree))
          (org-forward-heading-same-level 1)
          (org-fold-show-children))
      (error "Already at the last top level heading"))))

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
      (org-fold-show-children))))

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
        (zorg-forward-heading)))))

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
    (zorg-backward-heading)))

(provide 'zorg)

;;; zorg.el ends here

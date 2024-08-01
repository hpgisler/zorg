;;; zorg.el --- Simple notes with an efficient file-naming scheme -*- lexical-binding: t -*-

;;; Commentary:

;; Zorg aims to provide simple browsing movement functions for org files,
;; structured as a zettelkasten.

;;; Code:


:(defvar zorg-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd ")") #'zorg-forward-heading) 
    (define-key map (kbd "]") #'zorg-backward-heading) 
    (define-key map (kbd "|") #'zorg-forward-inner-heading) 
    (define-key map (kbd ">") #'zorg-backward-inner-heading) 
    map)
  "Keymap for `zorg-mode'.")


;;;###autoload
(define-minor-mode zorg-mode
  "Buffer-local minor mode for sensible navigation of an org-mode formatted zetterkasten.

It is assumed, that the zettelkasten is:
- fully condained in one org file
- the org files headingss structture directry correspond to Luhmann's folgezettel structure, i.e.
  its headings are arranged as Luhmann's zettels - but without explizit id annodation, i.e.
  - headings on the same indentation level (*..) correspond to e.g. to ..2a, ..2b etc.
  - sub-headings correspond to e.g. ..2a1, 2a2, etc
  - when linking to a zettel is required, org's normal linking mechanism to headings is employed

Further, it is assumed that zettels - i.e. individual atomic notes - are quite short.
Adhering to the style of Luhmann's note taking practice,
each note fit an a A6 sized zettel.
This brevity of an zettel is actually not a technical requirement, but it ensures:
- quick grasp of a zettels content when skimming through the zettelkasten;
  the readers concentration span should suffice  when scanning such a zettel
- the file size of the entire zettelkasten remains small enough to be processed fast by emacs
  e.g. 10'000 zettels, each with a maximum size of 1 kByte of text,
  leads to a zettelkasten size of 10 MBytes.

Zorg-mode provides commands and key-bindings for easy interaction with (navigation of)
the zettels in the zettelkasten - in a similar way as probaly was the case for Luhmann
with his physical zettelkasten (slip-box).
The basic idea being that - to a certain degree - zettel discoverability results
from the zettles arrangement as folgezettels thus allowing discoverability
when browsing the zettelkasten. that  - very much so as if the 
easily navigate the zettelka sten's zettels (headings).
Of course other mechanisms for zettel discoverability should be employed es well,
such as, direct linking between zettels, topic zettel hubs, linking to related zettels, etc."

  :lighter " Zorg"
  :keymap zorg-mode-map
  :version "1.0")


;;;###autoload
(defun zorg-forward-heading ()
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
      (error "No more forward headings"))))
    

;;;###autoload
(defun zorg-backward-heading ()
  (interactive)
  (if (org-evil-motion--first-heading-same-level-p)
      (if (org-evil-motion--heading-has-parent-p)
          (progn
            (org-fold-hide-subtree)
            (org-evil-motion-up-heading))
        (if (org-at-heading-p)
            (error "Already at first heading")
          (org-evil-motion-up-heading)))
    (if (not (org-evil-motion--first-heading-same-level-p))
        (if (org-at-heading-p)
            (progn
              (org-fold-hide-subtree)
              (org-backward-heading-same-level 1)
              (org-fold-show-children))
          (org-evil-motion-up-heading))
      (error "No more previous headings"))))


;;;###autoload
(defun zorg-forward-inner-heading ()
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
(defun zorg-backward-inner-heading ()
  (interactive)
  (if (org-evil-motion--heading-has-parent-p)
      (progn
        (org-fold-hide-subtree)
        (org-evil-motion-up-heading))
    (zorg-backward-heading)))


(provide 'zorg)

;;; zorg.el ends here

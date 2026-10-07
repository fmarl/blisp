;; guix shell -m manifest.scm

(specifications->manifest
  (list "nasm" "make" "qemu"))

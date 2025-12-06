;; Copyright (C) 2025 Florian Marrero Liestmann
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;; Author: Florian Marrero Liestmann <f.m.liestmann@fx-ttr.de>
;; File: print.asm
;;
;; Routines to output strings to TTY
;;
;; How to use:
;;
;; mov si, MSG
;; call printer
;;
[BITS 16]
	
printer:
	push bx

	mov ah, 0x0E 		; BIOS Printing Mode
	mov bx, 0x00

.loop:
	lodsb			; For reference see https://www.i8086.de/asm/8086-88-asm-lodsb.html
	cmp al, 0		; If the null terminator is reached, we're finished.
	je .end

	call _print_char
	jmp .loop
	
.end:
	pop bx
	ret

_print_char:
	mov ah, 0x0E
	int 0x10
	ret

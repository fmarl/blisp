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
;; File: kern.asm
;;
;; Memory map (segment 0):
;;   0x0000  nil: car and cdr, zeroed at boot
;;   0x0004  __env and __la, zeroed at boot
;;   0x7C00  stack top, grows down
;;   0x7C00  this sector, the symbol table grows past its end
;;   0x8000  cons cells, bump allocated up to 0xFFFF
;;
;; A value is a word: 0 is nil, bit 15 clear is the address of a
;; symbol's name, bit 15 set the address of a cell (car +0, cdr +2).

[BITS 16]
[ORG 0x7C00]

HEAP	equ 0x8000
__env	equ 4			; list of (symbol . value)
__la	equ 6			; lookahead character

boot_init:
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00
	cld
	mov di, ax
	stosw			; nil's car
	stosw			; nil's cdr
	stosw			; __env
	stosw			; __la
	;; falls through into start_interp

%include "interp.asm"
%include "read.asm"
%include "print.asm"

__prompt:	db 0x0D, "> ", 0
__dot:		db " . ", 0
__heap_ptr:	dw HEAP
__names_ptr:	dw __names_end

__names:			; symbol table, nul terminated names
__quote_sym:	db "quote", 0
__if_sym:	db "if", 0
__lambda_sym:	db "lambda", 0
__car_sym:	db "car", 0
__cdr_sym:	db "cdr", 0
__cons_sym:	db "cons", 0
__atom_sym:	db "atom", 0
__eq_sym:	db "eq", 0
__t_sym:	db "t", 0
__names_end:

times 510 - ($-$$) db 0
dw 0xAA55

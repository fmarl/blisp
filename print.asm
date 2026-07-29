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

[BITS 16]

printer:
	lodsb			; For reference see https://www.i8086.de/asm/8086-88-asm-lodsb.html
	or al, al		; If the null terminator is reached, we're finished.
	jz .end
	call _print_char
	jmp printer
.end:
	ret

_print_char:			; AL is preserved by the BIOS, BX is clobbered
	mov ah, 0x0E		; BIOS teletype output, page 0
	xor bx, bx
	int 0x10
	ret

print_val:
	cmp ax, HEAP
	jae .list
	or ax, ax
	jnz .sym
	mov ax, __nil_sym
.sym:
	xchg ax, si		; a symbol is its name
	jmp printer
.list:
	xchg ax, di
	mov al, '('
	call _print_char
.elem:
	push di
	mov ax, [di]
	call print_val
	pop di
	mov di, [di+2]
	cmp di, HEAP		; any atom cdr ends the list
	jb .close
	mov al, ' '
	call _print_char
	jmp .elem
.close:
	mov al, ')'
	jmp _print_char

__nil_sym:	db "()", 0x00

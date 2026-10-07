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

printer:			; SI = nul terminated string
	lodsb
	or al, al
	jz _print_char.ret
	call _print_char
	jmp printer

_print_char:			; AL = character, CR also prints LF; clobbers AH, BX
	mov ah, 0x0E
	xor bx, bx
	cmp al, 0x0D
	int 0x10		; the flags survive the interrupt
	jne .ret
	mov al, 0x0A
	jmp _print_char
.ret:
	ret

print_val:			; AX = value
	or ax, ax
	js .list
	jz .list		; nil prints as ()
	xchg ax, si
	jmp printer
.list:
	xchg ax, di
	mov al, '('
.elem:				; AL = separator, DI = cell or nil
	call _print_char
	or di, di
	jz .close
	push di
	mov ax, [di]
	call print_val
	pop di
	mov di, [di+2]
	mov al, ' '
	or di, di
	js .elem
	jz .close
	mov si, __dot		; an atom as cdr
	call printer
	xchg ax, di
	call print_val
.close:
	mov al, ')'
	jmp _print_char

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
;; File: read.asm

[BITS 16]

_advance:			; __la <- next key, echoed; CR also echoes LF
	mov ah, 0x00
	int 0x16         	; wait for key -> AL
	call _print_char
	cmp al, 0x0D
	jne .store
	mov al, 0x0A
	call _print_char
.store:
	mov [__la], al
	ret

_skip_ws:			; -> AL = first lookahead above ' '
	mov al, [__la]
	cmp al, ' '
	ja .ret
	call _advance
	jmp _skip_ws
.ret:
	ret

parse_expr:
	call _skip_ws
	cmp al, '('
	je .list

.atom:
	mov di, [__names_ptr]
.copy:
	stosb
	call _advance
	mov al, [__la]
	cmp al, ')'
	ja .copy
	xor al, al
	stosb
	mov bx, __names
.scan:
	mov si, bx
	mov di, [__names_ptr]
.cmp:
	lodsb
	scasb
	jne .next
	or al, al
	jnz .cmp
	mov ax, bx		; match; commit if it is the new copy
	cmp bx, [__names_ptr]
	jne .ret
	mov [__names_ptr], di
.ret:
	ret
.next:
	lodsb			; skip SI to the start of the next name
	or al, al
	jnz .next
	mov bx, si
	jmp .scan

.list:
	call _advance		; consume the (
.tail:
	call _skip_ws
	cmp al, ')'
	jne .item
	call _advance		; consume the )
	xor ax, ax
	ret
.item:
	call parse_expr
	push ax
	call .tail		; parse the rest of the list
	mov dx, ax
	pop ax
	jmp cons

__la:	db ' '

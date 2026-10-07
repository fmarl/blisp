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

parse_expr:			; -> AX = expression
	call _skip_ws
	je .tail		; a stray ) reads as nil
	cmp al, '('
	je .list
	mov di, [__names_ptr]	; copy the name behind the table
.copy:
	stosb
	or di, di
	js _overflow
	call _advance
	mov al, [__la]
	cmp al, ')'
	ja .copy
	cmp al, '('
	jae .end
	cmp al, ' '
	ja .copy
.end:
	xor al, al
	stosb
	mov bx, __names		; the symbol is the first copy of the name
.scan:
	mov si, bx
	mov di, [__names_ptr]
.cmp:
	lodsb
	scasb
	jne .next
	or al, al
	jnz .cmp
	mov ax, bx
	cmp si, di		; only the new copy ends where the new copy ends
	jne .ret
	mov [__names_ptr], di	; keep it
.ret:
	ret
.next:
	dec si			; the mismatch may have been the terminator
.skip:
	lodsb
	or al, al
	jnz .skip
	mov bx, si
	jmp .scan

.list:
	call _advance
.tail:
	call _skip_ws
	jne .item
	call _advance		; the key after the ) is consumed as well
	xor ax, ax
	ret
.item:
	call parse_expr
	push ax
	call .tail
	pop dx
	xchg ax, dx
	jmp cons

_advance:			; next key -> __la, echoed
	mov ah, 0
	int 0x16
	mov [__la], al
	jmp _print_char

_skip_ws:			; -> AL = first lookahead above ' ', ZF = it is a )
	mov al, [__la]
	cmp al, ' '
	ja .ret
	call _advance
	jmp _skip_ws
.ret:
	cmp al, ')'
	ret

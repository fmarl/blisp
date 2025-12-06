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
;;
;; Routines to output strings to TTY
;;
;; How to use:
;;
;; call scanner
;; result will be in di
;;
[BITS 16]

scanner:
	mov di, __linebuf	; We will read 32 byte
	xor cx, cx
.read_char:
	mov ah, 0x00
	int 0x16         	; wait for key -> AL
	
	cmp al, 0x0D     	; CR?
	je .end_line
	
	cmp al, 0x08		; backspace handling
	je .do_backspace
				
	mov ah, 0x0E		; echo
	int 0x10
	
	stosb
	inc cx
	cmp cx, 31
	jl .read_char
	jmp .end_line
	
.do_backspace:
	cmp cx, 0
	je .read_char
	dec di
	dec cx
			
	mov al, 8		; erase echo: backspace, space, backspace
	mov ah, 0x0E
	int 0x10
	
	mov al, ' '
	int 0x10
	
	mov al, 8
	int 0x10
	
	jmp .read_char

.end_line:
	mov byte [di], 0	; zero terminate
	mov di, __linebuf 	; copy result to di
	ret

__linebuf:	times 32 db 0

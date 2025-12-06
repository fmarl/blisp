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
;; File: interp.asm
[BITS 16]

start_interp:
	call _set_prompt
	call _read
	jmp $
	
_set_prompt:
	mov si, __prompt_sym 	; Setup our prompt
	call printer
	ret
	
_read:
	call scanner
	mov si, di
	call printer
	ret
.eval:
.print:
	
%include "print.asm"
%include "read.asm"	
__prompt_sym: 	db "expr> ", 0x00
__if_sym: 	db "if", 0x00
__quote_sym:	db "quote", 0x00
__lambda_sym:	db "lambda", 0x00
__begin_sym:	db "begin", 0x00
__define_sym:	db "define", 0x00
__let_sym:	db "let", 0x00
__set_sym:	db "set!", 0x00

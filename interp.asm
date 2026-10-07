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

start_interp:
	mov si, __prompt
	call printer
	call parse_expr
	call eval
	call print_val
	jmp start_interp

eval:				; AX = expression -> AX = value
	or ax, ax
	jz .ret
	js .combo
	mov bx, [__env]		; symbol: unbound ones evaluate to themselves
.look:
	or bx, bx
	jz .ret
	mov di, [bx]
	mov bx, [bx+2]
	cmp ax, [di]
	jne .look
	mov ax, [di+2]
.ret:
	ret

.combo:
	xchg ax, si
	cmp word [si], __lambda_sym
	jne .form
	xchg ax, si		; a lambda evaluates to itself
	ret
.form:
	lodsw			; AX = operator, SI = address of the cdr
	cmp ax, __quote_sym
	je .quote
	cmp ax, __if_sym
	jne .app
	mov si, [si]		; (test then [else])
	lodsw
	push si
	call eval
	pop si
	mov si, [si]		; (then [else])
	or ax, ax
	jnz .sel
	mov si, [si+2]		; ([else])
.sel:
	lodsw
	jmp eval
.quote:
	mov si, [si]
	lodsw
	ret
.app:
	push si
	call eval
	pop si
	push ax
	mov si, [si]
	call _evlis
	xchg ax, si
	pop ax
	;; falls through into apply

apply:				; AX = function, SI = argument list -> AX = value
	or ax, ax
	js .closure
	cmp ax, __car_sym
	je .car
	cmp ax, __cdr_sym
	je .cdr
	cmp ax, __cons_sym
	je .cons
	cmp ax, __atom_sym
	je .atom
	cmp ax, __eq_sym
	jne .nil		; not a function
	lodsw
	mov si, [si]
	cmp ax, [si]
	je .t
.nil:
	xor ax, ax
.ret:
	ret
.atom:
	lodsw
	or ax, ax
	js .nil
.t:
	mov ax, __t_sym
	ret
.cdr:
	mov bx, 2
	db 0xA9			; test ax, imm16: swallows the xor below
.car:
	xor bx, bx
	mov si, [si]
	or si, si
	jns .nil		; car and cdr of an atom are nil
	mov ax, [bx+si]
	ret
.cons:
	lodsw
	mov si, [si]
	mov dx, [si]
	jmp cons
.closure:			; AX = (lambda param body)
	mov dx, [si]		; the first argument
	xchg ax, si
	mov si, [si+2]
	lodsw			; AX = param, SI = address of (body)
	call cons
	mov dx, [__env]
	call cons
	mov [__env], ax		; the binding stays: dynamic scope
	mov si, [si]
	lodsw
	jmp eval

_evlis:				; SI = list -> AX = list of the values
	or si, si
	jz apply.nil
	lodsw
	push word [si]
	call eval
	pop si
	push ax
	call _evlis
	pop dx
	xchg ax, dx
	;; falls through into cons

cons:				; AX = car, DX = cdr -> AX = cell; clobbers DX, DI
	mov di, [__heap_ptr]
	or di, di		; wrapped past 0xFFFF
	jz _overflow
	stosw
	xchg ax, dx
	stosw
	xchg di, [__heap_ptr]
	xchg ax, di
	ret

_overflow:			; out of memory: reboot
	mov al, '!'
	call _print_char
	int 0x19

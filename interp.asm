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

HEAP	equ 0x8400		; first cons cell; names must stay below

start_interp:
	mov si, __prompt_sym
	call printer
	call parse_expr
	call eval
	call print_val
	jmp start_interp

cons:
	push di
	mov di, [__heap_ptr]
	push di
	stosw
	xchg ax, dx
	stosw
	mov [__heap_ptr], di
	pop ax
	pop di
	ret

eval:
	or ax, ax
	jz .ret			; nil
	cmp ax, HEAP
	jae .combo
	mov bx, [__env]		; symbol: unbound evaluates to itself
.look:
	or bx, bx
	jz .ret
	mov di, [bx]		; binding (symbol . value)
	cmp ax, [di]
	je .hit
	mov bx, [bx+2]
	jmp .look
.hit:
	mov ax, [di+2]
.ret:
	ret

.combo:
	xchg ax, di		; DI = the cell
	mov ax, [di]
	cmp ax, __quote_sym
	je .quote
	cmp ax, __if_sym
	je .if
	cmp ax, __lambda_sym
	jne .app
	xchg ax, di		; a lambda evaluates to itself
	ret

.quote:
	mov di, [di+2]
	mov ax, [di]
	ret

.if:
	mov di, [di+2]		; (cond then [else])
	push di
	mov ax, [di]
	call eval
	pop di
	mov di, [di+2]		; (then [else])
	or ax, ax
	jnz .sel
	mov di, [di+2]		; ([else])
.sel:
	or di, di		; missing branch: nil (AX is 0 here)
	jz .ret
	mov ax, [di]
	jmp eval		; tail position

.app:				; (fn arg...)
	push di
	call eval		; AX still holds the operator expression
	pop di
	push ax
	mov di, [di+2]
	call _evlis
	xchg ax, di		; DI = argument list
	pop ax			; AX = function

apply:
	cmp ax, HEAP
	jae .closure
	cmp ax, __car_sym
	je .car
	cmp ax, __cdr_sym
	je .cdr
	cmp ax, __cons_sym
	je .cons
	cmp ax, __eq_sym
	jne .nil		; not applicable -> ()
	mov ax, [di]		; eq
	mov di, [di+2]
	cmp ax, [di]
	mov ax, __t_sym
	je .ret
.nil:
	xor ax, ax
.ret:
	ret
.car:
	mov bx, [di]
	mov ax, [bx]
	ret
.cdr:
	mov bx, [di]
	mov ax, [bx+2]
	ret
.cons:
	mov ax, [di]
	mov di, [di+2]
	mov dx, [di]
	jmp cons

.closure:			; AX = (lambda param body), DI = args
	xchg ax, di		; DI = lambda, AX = args
	mov si, [di+2]		; (param body)
	push si
	xchg ax, bx		; BX = args
	mov ax, [si]		; the parameter symbol
	mov dx, [bx]		; the first argument
	call _bind
	pop di
	mov di, [di+2]		; (body)
	mov ax, [di]
	jmp eval		; bindings stay: dynamic scope, no cleanup

_evlis:
	or di, di
	jnz .go
	xor ax, ax
	ret
.go:
	push word [di+2]
	mov ax, [di]
	call eval
	pop di
	push ax
	call _evlis
	mov dx, ax
	pop ax
	jmp cons

_bind:
	call cons		; (symbol . value)
	mov dx, [__env]
	call cons
	mov [__env], ax
	ret

%include "print.asm"
%include "read.asm"

__prompt_sym:	db 0x0D, 0x0A, "> ", 0x00
__env:		dw 0x00
__heap_ptr:	dw HEAP
__names_ptr:	dw __names_end

__names:
__quote_sym:	db "quote", 0x00
__if_sym:	db "if", 0x00
__lambda_sym:	db "lambda", 0x00
__car_sym:	db "car", 0x00
__cdr_sym:	db "cdr", 0x00
__cons_sym:	db "cons", 0x00
__eq_sym:	db "eq", 0x00
__t_sym:	db "t", 0x00
__names_end:

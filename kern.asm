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

[BITS 16]
[ORG 0x7C00]

jmp short start

start:
	jmp 0:boot_init

boot_init: 
	cli			; Disable interrupts
	mov ax, 0x00
	mov ds, ax		; Set data segment
	mov es, ax		; Set extra segment
	mov ss, ax		; Set stack segment
	mov sp, 0x7C00		; Set stack pointer
	sti			; Enable interrupts
	cld

	call start_interp
	
.error:
	jmp $

%include "interp.asm"

times 510 - ($-$$) db 0x00	; Fill remaining memory
dw 0xAA55			; Magicnumber which marks this as bootable for BIOS

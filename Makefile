NASM ?= nasm
QEMU ?= qemu-system-i386
PYTHON ?= python3

all: kern.bin

kern.bin: kern.asm interp.asm read.asm print.asm
	$(NASM) -f bin -l kern.lst -o $@ $<

start: kern.bin
	$(QEMU) -drive format=raw,file=$<

clean:
	rm -f kern.bin kern.lst

.PHONY: all start clean

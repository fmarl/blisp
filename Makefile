BINDIR = @bindir@
KERN_SRC=kern.asm
KERN_OBJ=kern.bin
OUTPUTS=${KERN_OBJ}

all: compile-kernel
	@echo "[1] Done."

start: compile-kernel
	qemu-system-i386 -drive format=raw,file=${KERN_OBJ}

compile-kernel: ${KERN_OBJ}
	@echo "[0] Compiling $<"

${KERN_OBJ}: ${KERN_SRC}
	@nasm -f bin $< -o $@

.PHONY: clean

clean:
	@echo "Cleaning"
	@rm -rf ${OUTPUTS}

# blisp

blisp is a lisp interpreter as a bootsector OS. The whole
interpreter lives in the 510 bytes of the boot sector.

## Build & run

    make
    make start

## The language

Symbols and lists, no numbers. Expressions are typed at the prompt
and may span lines; the result prints after the expression is
complete and one more key (usually the final enter) is pressed.
Memory is bump-allocated, there is no GC so reboot to reset.

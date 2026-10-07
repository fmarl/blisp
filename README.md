# blisp

blisp is a lisp interpreter as a bootsector OS. The whole
interpreter lives in the 510 bytes of the boot sector.

## Build & run

    make          # kern.bin, needs nasm
    make start    # boots it in qemu
    make test     # needs python3 and `pip install unicorn`

## The language

Symbols and lists, no numbers, no strings, no `'`. `()` is nil and
false, everything else is true.

An expression is read once the key after it has been typed, usually
enter. Whitespace and parentheses end a symbol. A stray `)` reads
as `()`.

- `()` evaluates to itself.
- A symbol evaluates to its binding, or to itself if unbound.
- `(quote x)` is `x`.
- `(if test then else)`, `else` is optional and defaults to `()`.
- `(lambda param body)` evaluates to itself. One parameter, a symbol.
- `(f arg ...)` evaluates `f` and the arguments and applies them.
  Applying a non-function gives `()`.

Functions: `car`, `cdr`, `cons`, `atom`, `eq`. `car` and `cdr` of an
atom are `()`. `(cons (quote a) (quote b))` prints as `(a . b)`.
Missing arguments are `()`, extra ones are ignored.

A lambda call pushes its binding onto a global environment and nothing
pops it. Scope is dynamic and bindings outlive the call, which is how
things get defined:

    > ((lambda twice (twice (quote x))) (lambda y (cons y y)))
    (x . x)
    > (twice (quote z))
    (z . z)

Memory is bump allocated and never freed. Cells live in 32 KB, symbol
names in about 500 bytes. When either runs out blisp prints `!` and
reboots.

## Example: Fibonacci

Numbers are lists of `i`. Addition appends them:

    > ((lambda add (quote ok))
       (lambda p (lambda q (if p (cons (quote i) ((add (cdr p)) q)) q))))
    ok

`fib(n-1) + fib(n-2)` does not work: the first call rebinds `n`, the
second one sees the wrong value. So iterate on a triple `(n a b)`:

    > ((lambda iter (quote ok))
       (lambda s (if (car s)
                     (iter (cons (cdr (car s))
                           (cons (car (cdr (cdr s)))
                           (cons ((add (car (cdr s))) (car (cdr (cdr s)))) ()))))
                     (car (cdr s)))))
    ok
    > ((lambda fib (quote ok))
       (lambda n (iter (cons n (cons () (cons (quote (i)) ()))))))
    ok
    > (fib (quote (i i i i i)))
    (i i i i i)
    > (fib (quote (i i i i i i i i i i)))
    (i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i i)

The tail call keeps the stack flat, the heap runs out after fib of 14.
Parameter names must differ between functions.

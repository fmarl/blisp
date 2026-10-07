import sys
from pathlib import Path

from unicorn import UC_ARCH_X86, UC_HOOK_INTR, UC_MODE_16, Uc
from unicorn.x86_const import UC_X86_REG_AH, UC_X86_REG_AL, UC_X86_REG_AX, UC_X86_REG_IP

LOAD = 0x7C00
PROMPT = "\r\n> "

CASES = [
    ("true", "true"),
    ("(car (quote (a b)))", "a"),
    ("(cdr (quote (a b)))", "(b)"),
    ("(cons (quote a) (quote (b)))", "(a b)"),
    ("(cons (quote a) (quote b))", "(a . b)"),
    ("(cons () ())", "(())"),
    ("(eq (quote a) (quote a))", "t"),
    ("(eq (quote a) (quote b))", "()"),
    ("(eq () ())", "t"),
    ("(atom (quote a))", "t"),
    ("(atom ())", "t"),
    ("(atom (quote (a)))", "()"),
    ("(atom)", "t"),
    ("(if (quote x) (quote yes) (quote no))", "yes"),
    ("(if () (quote yes) (quote no))", "no"),
    ("(if () (quote yes))", "()"),
    ("((lambda x (cons x x)) (quote q))", "(q . q)"),
    ("x", "q"),
    ("(lambda y y)", "(lambda y y)"),
    ("((lambda twice (twice (quote x))) (lambda y (cons y y)))", "(x . x)"),
    ("(twice (quote z))", "(z . z)"),
    ("(car (quote a))", "()"),
    ("(cdr ())", "()"),
    ("(quote)", "()"),
    ("(if)", "()"),
    ("((lambda x x))", "()"),
    ("(foo bar)", "()"),
    ("ab", "ab"),
    ("abc", "abc"),
    ("((lambda abc (quote bound)) (quote v))", "bound"),
    ("abc", "v"),
    ("(quote (a(b) c))", "(a (b) c)"),
    ("(quote a&b)", "a&b"),
    ("(quote quotes)", "quotes"),
]

OVERFLOWS = [
    ("((lambda f (f f)) (lambda f (f f)))", "heap"),
    ("n" * 600, "symbol table"),
]


def boot(image: bytes, keys: bytes, limit: int = 50_000_000) -> tuple[str, bool]:
    uc = Uc(UC_ARCH_X86, UC_MODE_16)
    uc.mem_map(0, 0x10000)
    uc.mem_write(LOAD, image)
    out = bytearray()
    pending = iter(keys)
    rebooted = False

    def interrupt(uc: Uc, number: int, _data: object) -> None:
        nonlocal rebooted
        ip = uc.reg_read(UC_X86_REG_IP)
        
        if number == 0x10 and uc.reg_read(UC_X86_REG_AH) == 0x0E:
            out.append(uc.reg_read(UC_X86_REG_AL))
        elif number == 0x16:
            key = next(pending, None)
            if key is None:
                uc.emu_stop()
                return
            uc.reg_write(UC_X86_REG_AX, key)
        elif number == 0x19:
            rebooted = True
            uc.emu_stop()
            return
        else:
            raise RuntimeError(f"unexpected int {number:#x}")
        
        uc.reg_write(UC_X86_REG_IP, ip)

    uc.hook_add(UC_HOOK_INTR, interrupt)
    uc.emu_start(LOAD, LOAD + len(image), count=limit)
    
    return out.decode("latin-1"), rebooted


def main(path: str) -> int:
    image = Path(path).read_bytes()
    failed = 0

    keys = "".join(expr + "\r" for expr, _ in CASES).encode()
    out, rebooted = boot(image, keys)
    answers = out.split(PROMPT)[1 : len(CASES) + 1]
    
    for (expr, want), answer in zip(CASES, answers, strict=True):
        got = answer.removeprefix(expr + "\r\n")
        if got != want or rebooted:
            failed += 1
            print(f"FAIL {expr!r}: want {want!r}, got {got!r}")

    for expr, what in OVERFLOWS:
        out, rebooted = boot(image, (expr + "\r").encode())
        if not (rebooted and out.endswith("!")):
            failed += 1
            print(f"FAIL {what} overflow: no reboot, output ends {out[-40:]!r}")

    total = len(CASES) + len(OVERFLOWS)
    print(f"{total - failed}/{total} passed")
    
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))

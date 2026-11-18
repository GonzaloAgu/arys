#!/usr/bin/env python3
"""Genera o valida una secuencia balanceada de respuestas correctas (A-D).

Uso:
    python mc_answer_sequence.py 10
    python mc_answer_sequence.py check C A D B A C B D A C
"""

from __future__ import annotations

import random
import sys
from collections import Counter

LETTERS = list("ABCD")
rng = random.SystemRandom()


def generate(n: int) -> list[str]:
    if n <= 0:
        raise ValueError("n debe ser mayor que cero")
    sequence = LETTERS * (n // 4) + rng.sample(LETTERS, n % 4)
    while True:
        rng.shuffle(sequence)
        if not any(
            sequence[i] == sequence[i + 1] == sequence[i + 2]
            for i in range(n - 2)
        ):
            return sequence


def validate(sequence: list[str]) -> int:
    counts = Counter(sequence)
    valid_letters = bool(sequence) and set(sequence) <= set(LETTERS)
    balanced = valid_letters and (max(counts.values()) - min(counts.values()) <= 1)
    no_triples = not any(
        sequence[i] == sequence[i + 1] == sequence[i + 2]
        for i in range(len(sequence) - 2)
    )

    print("Secuencia:", " ".join(sequence))
    print("Conteo:", " ".join(f"{letter}={counts[letter]}" for letter in LETTERS if counts[letter]))
    if valid_letters:
        print("Diferencia max-min:", max(counts.values()) - min(counts.values()))
    else:
        print("Diferencia max-min: n/a (hay letras fuera de A-D)")
    print("Tres iguales seguidas:", "SÍ" if not no_triples else "NO")

    ok = valid_letters and balanced and no_triples
    print("VÁLIDA" if ok else "INVÁLIDA")
    return 0 if ok else 1


def main(argv: list[str]) -> int:
    if len(argv) >= 2 and argv[1].lower() == "check":
        sequence = [part.strip().upper() for part in argv[2:] if part.strip()]
        if not sequence:
            print("Uso: mc_answer_sequence.py check C A D B ...", file=sys.stderr)
            return 2
        return validate(sequence)

    if len(argv) < 2:
        print("Uso: mc_answer_sequence.py N | mc_answer_sequence.py check C A D B ...", file=sys.stderr)
        return 2

    try:
        n = int(argv[1])
    except ValueError:
        print("N debe ser un entero.", file=sys.stderr)
        return 2

    print(" ".join(generate(n)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

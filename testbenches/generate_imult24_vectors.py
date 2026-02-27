#!/usr/bin/env python3
"""Generate 24-bit integer multiplication vectors.

Each line contains three hex numbers (a, b, product) separated by spaces,
matching the format of testbenches/vectors.txt used by the existing add32_tb.
The products are 48-bit values so they are printed with up to 12 hex digits.

Usage:
    python generate_imult24_vectors.py [count]

If no count is provided, 100000 vector pairs are generated.
"""

import random
import sys


def main():
    outname = "testbenches/imult24_vectors.txt"
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 100000
    random.seed(0)

    with open(outname, "w") as f:
        for _ in range(count):
            a = random.getrandbits(24)
            b = random.getrandbits(24)
            prod = a * b
            # format: 6 hex digits for 24‑bit operands, 12 for 48‑bit product
            f.write(f"{a:06x} {b:06x} {prod:012x}\n")

    print(f"Wrote {count} vectors to {outname}")


if __name__ == "__main__":
    main()

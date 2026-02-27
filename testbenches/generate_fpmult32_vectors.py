#!/usr/bin/env python3
"""Generate 32‑bit floating point multiplication vectors.

Each line contains three hex numbers (a, b, product) separated by spaces,
matching the format used by `fpadd32_vectors.txt`.

Usage:
    python generate_fpmult32_vectors.py [count]

If no count is provided, 100000 vector pairs are generated.
"""

import random
import sys

try:
    import numpy as np
except ImportError:
    sys.stderr.write("error: numpy is required for this script\n")
    sys.exit(1)


def main():
    outname = "testbenches/fpmult32_vectors.txt"
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 100000
    random.seed(0)

    with open(outname, "w") as f:
        for _ in range(count):
            a = np.uint32(random.getrandbits(32))
            b = np.uint32(random.getrandbits(32))
            fa = a.view(np.float32)
            fb = b.view(np.float32)
            prod = np.float32(fa * fb)
            res = prod.view(np.uint32)
            f.write(f"{a:08x} {b:08x} {res:08x}\n")

    print(f"Wrote {count} vectors to {outname}")


if __name__ == "__main__":
    main()

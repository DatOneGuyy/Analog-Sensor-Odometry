import struct
import random

def u32_to_fields(u):
    sign = (u >> 31) & 1
    exp = (u >> 23) & 0xFF
    frac = u & 0x7FFFFF
    return sign, exp, frac


def fields_to_u32(sign, exp, frac):
    return (sign << 31) | ((exp & 0xFF) << 23) | (frac & 0x7FFFFF)


def add_fp32_bits(a_bits, b_bits):
    # mirrors the SystemVerilog add32 implementation (no special-case handling)
    sa, ea, fa = u32_to_fields(a_bits)
    sb, eb, fb = u32_to_fields(b_bits)

    # implicit leading 1
    ma = (1 << 23) | fa
    mb = (1 << 23) | fb

    # extend to signed integers
    # represent with extra headroom (28 bits)
    if sa:
        ma_ext = -ma
    else:
        ma_ext = ma
    if sb:
        mb_ext = -mb
    else:
        mb_ext = mb

    # pick max exponent
    if ea >= eb:
        exp_max = ea
        exp_min = eb
        mant_max = ma_ext
        mant_min = mb_ext
    else:
        exp_max = eb
        exp_min = ea
        mant_max = mb_ext
        mant_min = ma_ext

    diff = exp_max - exp_min
    if diff >= 25:
        mant_min_shifted = 0
    else:
        # arithmetic shift for signed
        mant_min_shifted = mant_min >> diff

    sum_signed = mant_max + mant_min_shifted

    if sum_signed < 0:
        sign_sum = 1
        mag = -sum_signed
    else:
        sign_sum = 0
        mag = sum_signed

    # normalization
    carry_out = (mag >= (1 << 24))
    if carry_out:
        mag = mag >> 1

    # count leading zeros in bits [23:0]
    leading_zeros = 0
    for i in range(23, -1, -1):
        if (mag >> i) & 1 == 0:
            leading_zeros += 1
        else:
            break

    if mag != 0:
        mag = (mag << leading_zeros) & ((1 << 24) - 1)  # keep lower 24 bits after shift

    exp_final = int(exp_max + (1 if carry_out else 0) - leading_zeros) & 0xFF

    frac_out = mag & ((1 << 23) - 1)
    return fields_to_u32(sign_sum, exp_final, frac_out)


def u32_to_float(u):
    return struct.unpack('!f', struct.pack('!I', u))[0]


def float_to_u32(f):
    return struct.unpack('!I', struct.pack('!f', f))[0]


if __name__ == '__main__':
    # quick random test comparing to rounded float32 addition
    rng = random.Random(123)
    mismatches = 0
    for _ in range(2000):
        # generate random normal-ish floats by random exponents and fractions
        a_bits = rng.getrandbits(32)
        b_bits = rng.getrandbits(32)
        # skip NaN/Inf/subnormal by ensuring exp not all 0 or all 1
        def sanitize(x):
            s, e, f = u32_to_fields(x)
            if e == 0 or e == 0xFF:
                e = rng.randint(1, 0xFE)
            return fields_to_u32(s, e, f)
        a_bits = sanitize(a_bits)
        b_bits = sanitize(b_bits)

        ref_bits = add_fp32_bits(a_bits, b_bits)

        # compute float32-add via Python float pack->unpack (round to float32)
        fa = u32_to_float(a_bits)
        fb = u32_to_float(b_bits)
        real_sum = struct.unpack('!I', struct.pack('!f', fa + fb))[0]

        if ref_bits != real_sum:
            mismatches += 1

    print(f"Checked 2000 random cases; mismatches vs float32 add: {mismatches}")
    print("Note: implementation uses truncation-like normalization, no IEEE rounding rules.")


def generate_vectors(filename='vectors.txt', count=1000, seed=12345):
    rng = random.Random(seed)
    with open(filename, 'w') as f:
        for _ in range(count):
            a = rng.getrandbits(32)
            b = rng.getrandbits(32)
            # sanitize exponents to avoid subnormals/inf/nan
            def s(x):
                sgn, e, fr = u32_to_fields(x)
                if e == 0 or e == 0xFF:
                    e = rng.randint(1, 0xFE)
                return fields_to_u32(sgn, e, fr)
            a = s(a)
            b = s(b)
            r = add_fp32_bits(a, b)
            f.write(f"%08x %08x %08x\n" % (a, b, r))



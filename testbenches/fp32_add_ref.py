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


def generate_vectors(filename='testbenches/fpadd32_vectors.txt', count=5000, seed=12345):
    rng = random.Random(seed)
    with open(filename, 'w') as f:
        generated = 0
        while generated < count:
            a_bits = rng.getrandbits(32)
            b_bits = rng.getrandbits(32)
            
            # sanitize exponents to avoid subnormals/inf/nan
            def sanitize(x):
                sgn, e, fr = u32_to_fields(x)
                if e == 0 or e == 0xFF:
                    e = rng.randint(1, 0xFE)
                return fields_to_u32(sgn, e, fr)
                
            a_bits = sanitize(a_bits)
            b_bits = sanitize(b_bits)
            
            fa = u32_to_float(a_bits)
            fb = u32_to_float(b_bits)
            
            real_sum_float = fa + fb
            
            try:
                # Attempt to pack back into 32-bit float
                r_bits = float_to_u32(real_sum_float)
            except OverflowError:
                # The sum exceeded FP32 limits. 
                # Skip this pair and try again.
                continue
                
            f.write(f"%08x %08x %08x\n" % (a_bits, b_bits, r_bits))
            generated += 1 # Only increment on success


if __name__ == '__main__':
    rng = random.Random(123)
    print("generating vectors\n")

    generate_vectors()
#include <stdio.h>
#include <math.h>
#include <stdint.h>

void print_float_binary(float f) {
    union {
        float val_f;
        uint32_t val_u;
    } data;

    data.val_f = f;

    for (int i = sizeof(float) * 8 - 1; i >= 0; i--) {
        uint32_t mask = (uint32_t)1 << i;
        if (data.val_u & mask) {
            printf("1");
        } else {
            printf("0");
        }
        
        if (i == 31 || i == 23) {
            //printf(" ");
        }
    }
}

int main() {
    const int count = 16;
    float angles[count];

    for (int i = 0; i < count; ++i) {
        print_float_binary(atan(1.0 / pow(2, i)));
        printf(", ");
    }

    return 0;
}
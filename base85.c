/*
 * base85 - Base85 encoding/decoding utility
 * Copyright (C) 2026 thaolt@songphi.com
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "base85.h"
#include <string.h>
 #include <ctype.h>

static char default_charset[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+-;<=>?@^_`{|}~";

size_t base85_encode_block(const unsigned char* input, size_t input_len, char* output) {
    unsigned long num = 0;
    
    // Convert up to 4 bytes to a 32-bit number (big-endian)
    for (size_t i = 0; i < input_len; i++) {
        num = (num << 8) | input[i];
    }

    // Python base64.b85encode pads the final, partial block with zero bytes
    // (i.e. treat missing bytes as trailing '\x00').
    if (input_len < 4) {
        num <<= (unsigned long)((4 - input_len) * 8);
    }
    
    // Convert to 5 Base85 digits
    char result[5];
    for (int i = 4; i >= 0; i--) {
        result[i] = default_charset[num % 85];
        num /= 85;
    }
    
    // For partial blocks, only output the needed characters
    size_t output_len = (input_len * 5 + 3) / 4;
    // Python emits the first (input_len + 1) characters of the 5-char chunk.
    memcpy(output, result, output_len);
    
    return output_len;
}

size_t base85_encode(const unsigned char* input, size_t input_len, char* output) {
    size_t output_pos = 0;
    
    // Process full 4-byte blocks
    while (input_len >= 4) {
        output_pos += base85_encode_block(input, 4, output + output_pos);
        input += 4;
        input_len -= 4;
    }
    
    // Process remaining partial block
    if (input_len > 0) {
        output_pos += base85_encode_block(input, input_len, output + output_pos);
    }
    
    output[output_pos] = '\0';
    return output_pos;
}

size_t base85_decode_block(const char* input, size_t input_len, unsigned char* output) {
    // Python's base64.b85decode behavior:
    // - Input is padded with '~' to a multiple of 5 characters
    // - Each 5-char chunk decodes to 4 bytes
    // - Then the final output is truncated by the number of padding chars
    if (input_len == 0) return 0;
    if (input_len == 1) return 0;

    size_t padding = 0;
    if (input_len < 5) {
        padding = 5 - input_len;
    }

    unsigned long num = 0;
    for (size_t i = 0; i < input_len; i++) {
        const char* p = strchr(default_charset, input[i]);
        if (!p) return 0; // Invalid character
        num = num * 85 + (unsigned long)(p - default_charset);
    }

    // Pad with '~' (the last digit, value 84)
    for (size_t i = 0; i < padding; i++) {
        num = num * 85 + 84;
    }

    output[0] = (num >> 24) & 0xFF;
    output[1] = (num >> 16) & 0xFF;
    output[2] = (num >> 8) & 0xFF;
    output[3] = num & 0xFF;

    return 4 - padding;
}

size_t base85_decode(const char* input, size_t input_len, unsigned char* output) {
    size_t output_pos = 0;

    char carry[5];
    size_t carry_len = 0;

    for (size_t i = 0; i < input_len; i++) {
        unsigned char c = (unsigned char)input[i];
        if (isspace(c)) continue;

        carry[carry_len++] = (char)c;
        if (carry_len == 5) {
            output_pos += base85_decode_block(carry, 5, output + output_pos);
            carry_len = 0;
        }
    }

    if (carry_len > 0) {
        output_pos += base85_decode_block(carry, carry_len, output + output_pos);
    }

    return output_pos;
}
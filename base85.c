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

static char default_charset[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+-;<=>?@^_`{|}~";

size_t base85_encode_block(const unsigned char* input, size_t input_len, char* output) {
    unsigned long num = 0;
    
    // Convert up to 4 bytes to a 32-bit number (big-endian)
    for (size_t i = 0; i < input_len; i++) {
        num = (num << 8) | input[i];
    }
    
    // Convert to 5 Base85 digits
    char result[5];
    for (int i = 4; i >= 0; i--) {
        result[i] = default_charset[num % 85];
        num /= 85;
    }
    
    // For partial blocks, only output the needed characters
    size_t output_len = (input_len * 5 + 3) / 4;
    memcpy(output, result + 5 - output_len, output_len);
    
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
    // Convert Base85 characters back to numbers
    unsigned long num = 0;
    for (size_t i = 0; i < input_len; i++) {
        const char* p = strchr(default_charset, input[i]);
        if (!p) return 0; // Invalid character
        num = num * 85 + (p - default_charset);
    }
    
    // Don't pad for partial blocks - just work with what we have
    
    // Convert back to bytes (big-endian)
    size_t output_len;
    if (input_len == 5) {
        output_len = 4;
    } else {
        output_len = (input_len - 1) * 4 / 5 + 1;
    }
    
    // For partial blocks, we need to position the number correctly
    if (input_len < 5) {
        // Calculate how many bytes we're missing
        int missing_bytes = 4 - output_len;
        // Shift left by the missing bytes
        num <<= (missing_bytes * 8);
    }
    
    for (size_t i = 0; i < output_len; i++) {
        output[i] = (num >> (24 - i * 8)) & 0xFF;
    }
    
    return output_len;
}

size_t base85_decode(const char* input, size_t input_len, unsigned char* output) {
    size_t output_pos = 0;
    
    // Process full 5-character blocks
    while (input_len >= 5) {
        output_pos += base85_decode_block(input, 5, output + output_pos);
        input += 5;
        input_len -= 5;
    }
    
    // Process remaining partial block
    if (input_len > 0) {
        output_pos += base85_decode_block(input, input_len, output + output_pos);
    }
    
    return output_pos;
}
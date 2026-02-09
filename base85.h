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

#ifndef BASE85_H
#define BASE85_H

#include <stddef.h>

// Encode binary data to Base85
// Returns number of characters written to output (excluding null terminator)
// output must have enough space (input_len * 5 / 4 + 5)
size_t base85_encode(const unsigned char* input, size_t input_len, char* output);

size_t base85_encode_block(const unsigned char* input, size_t input_len, char* output);

// Decode Base85 text to binary data
// Returns number of bytes written to output
// output must have enough space (input_len * 4 / 5 + 4)
size_t base85_decode(const char* input, size_t input_len, unsigned char* output);

size_t base85_decode_block(const char* input, size_t input_len, unsigned char* output);

#endif
#ifndef BASE85_H
#define BASE85_H

#include <stddef.h>
#include <stdio.h>

// Encode binary data to Base85
// Returns number of characters written to output (excluding null terminator)
// output must have enough space (input_len * 5 / 4 + 5)
size_t base85_encode(const unsigned char* input, size_t input_len, char* output);

// Decode Base85 text to binary data
// Returns number of bytes written to output
// output must have enough space (input_len * 4 / 5 + 4)
size_t base85_decode(const char* input, size_t input_len, unsigned char* output);

// Stream-based encode function
void base85_encode_stream(FILE* input, FILE* output);

// Stream-based decode function  
void base85_decode_stream(FILE* input, FILE* output);

#endif
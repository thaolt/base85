#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <getopt.h>
#include "base85.h"

const char* program_name = "base85";
const char* version_string = "1.0.0";

static void print_usage(FILE* stream, int exit_code) {
    fprintf(stream, "Usage: %s [OPTION]... [FILE]\n", program_name);
    fprintf(stream, "%s encode or decode FILE, or standard input, to standard output.\n\n", program_name);
    fprintf(stream, "With no FILE, or when FILE is -, read standard input.\n\n");
    fprintf(stream, "Mandatory arguments to long options are mandatory for short options too.\n");
    fprintf(stream, "  -d, --decode          decode data\n");
    fprintf(stream, "  --help        display this help and exit\n");
    fprintf(stream, "  --version     output version information and exit\n");
    exit(exit_code);
}

static void print_version(void) {
    printf("%s %s\n", program_name, version_string);
    exit(0);
}

int main(int argc, char* argv[]) {
    bool decode_mode = false;
    const char* input_file = NULL;
    
    static struct option long_options[] = {
        {"decode", no_argument, 0, 'd'},
        {"help", no_argument, 0, 'h'},
        {"version", no_argument, 0, 'v'},
        {0, 0, 0, 0}
    };
    
    int c;
    while ((c = getopt_long(argc, argv, "dhv", long_options, NULL)) != -1) {
        switch (c) {
            case 'd':
                decode_mode = true;
                break;
            case 'h':
                print_usage(stdout, 0);
                break;
            case 'v':
                print_version();
                break;
            case '?':
                print_usage(stderr, 1);
                break;
            default:
                abort();
        }
    }
    
    if (optind < argc) {
        input_file = argv[optind];
    }
    
    FILE* input = stdin;
    if (input_file && strcmp(input_file, "-") != 0) {
        input = fopen(input_file, "r");
        if (!input) {
            perror("Error opening input file");
            return 1;
        }
    }
    
    if (decode_mode) {
        base85_decode_stream(input, stdout);
    } else {
        base85_encode_stream(input, stdout);
    }
    
    if (input != stdin) {
        fclose(input);
    }
    
    return 0;
}

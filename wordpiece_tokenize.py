#!/usr/bin/env python3

"""Tokenize text in a word-piece style."""


import argparse
import multiprocessing
import sys
import unicodedata


SPACE = "▁"


ALNUM_CHARSET = set(
    chr(i) for i in range(sys.maxunicode)
    if (unicodedata.category(chr(i)).startswith("L")
        or unicodedata.category(chr(i)).startswith("N")))


def tokenize(string):
    space_separated = string.strip().split(" ")
    tokens = []

    for space_sep_tok in space_separated:
        if all(c in ALNUM_CHARSET for c in space_sep_tok):
            tokens.append(SPACE + space_sep_tok)
            continue

        in_alph = space_sep_tok[0] in ALNUM_CHARSET
        cur_token = [SPACE]
        for char in space_sep_tok:
            if in_alph == (char in ALNUM_CHARSET):
                cur_token.append(char)
            else:
                tokens.append("".join(cur_token))
                in_alph = char in ALNUM_CHARSET
                cur_token = [char]

        if cur_token:
            tokens.append("".join(cur_token))

    return tokens


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument(
        "input", nargs="?", default=sys.stdin, type=argparse.FileType('r'))
    parser.add_argument("--num-threads", type=int, default=8)
    parser.add_argument("--buffer-size", type=int, default=100000)
    args = parser.parse_args()

    pool = multiprocessing.Pool(args.num_threads)

    line_buffer = []

    def process_buffer():
        tokenized = pool.map(tokenize, line_buffer)
        for tok in tokenized:
            print(" ".join(tok))

    for line in args.input:
        line_buffer.append(line)

        if len(line_buffer) >= args.buffer_size:
            process_buffer()
            line_buffer = []

    process_buffer()


if __name__ == "__main__":
    main()

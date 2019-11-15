#!/usr/bin/env python3

"""Sample natrual noise into tokenized text ."""

import argparse
import random
import sys


SPACE = "▁"


def load_table(table_file):
    error_table = {}
    for line in table_file:
        words = line.strip().split()
        error_table[words[0]] = words[1:]
    table_file.close()

    return error_table


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument(
        "dictionary", type=argparse.FileType('r'),
        help="File from 'charNMT-noise' tabulating the frequent typos.")
    parser.add_argument(
        "probability", type=float, help="Sampling probability")
    parser.add_argument(
        "input", nargs="?", default=sys.stdin, type=argparse.FileType('r'))
    args = parser.parse_args()

    if args.probability < 0 or args.probability > 1:
        raise ValueError("Probability must be between 0 and 1.")

    error_table = load_table(args.dictionary)

    total_tokens = 0
    replacements = 0

    for line in args.input:
        new_tokens = []
        for token in line.strip().split():
            total_tokens += 1
            if token[1:] in error_table and random.random() < args.probability:
                new_tokens.append(
                        SPACE + random.choice(error_table[token[1:]]))
                replacements += 1
            else:
                new_tokens.append(token)
        print(" ".join(new_tokens))

    print(f"Total tokens: {total_tokens}, replaced: {replacements}",
          file=sys.stderr)
    print(f"Replacement rate: {replacements / total_tokens:.2f}",
          file=sys.stderr)


if __name__ == "__main__":
    main()
